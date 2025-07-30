load("@aspect_bazel_lib//lib:copy_file.bzl", "copy_file_action")
load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@bazel_skylib//lib:paths.bzl", "paths")
load(":helm_chart_providers.bzl", "ChartInfo")
load("@aspect_bazel_lib//lib:stamping.bzl", "STAMP_ATTRS", "maybe_stamp")
load("@aspect_bazel_lib//lib:copy_file.bzl", "COPY_FILE_TOOLCHAINS")

DEFAULT_HELM_API_VERSION = "v2"
DEFAULT_HELM_CHART_VERSION = "1.0.0"
DEFAULT_VALUES_REPO_YAML = ".image.repository"


_DOC = """Customize helm chart values and configuration.

This rule should not be used directly, users should use `helm_chart` macro instead. See [helm_chart](#helm_chart).
Despite, if you want to see the configuration arguments you can use to package a helm chart using `helm_chart` rule, check the arguments doc below for `chart_srcs` rule,
as `helm_chart` is just a wrapper around `chart_srcs` rule and all the arguments are propagated to `chart_srcs` rule.

This rule takes chart src files and write them to bazel output dir applying some modifications.
The rule is designed to be used with a packager to produce an archived file (`pkg_tar` is used).

```starlark
chart_srcs(
    name = "basic_chart",
    chart_name = "example",
    srcs = glob(["**"]),
)
```

You can customize the values of the chart overriding them via `values` rule attribute:

```starlark
chart_srcs(
    name = "basic_chart",
    chart_name = "example",
    srcs = glob(["**"]),
    values = {
        "override.value": "valueoverrided",
    }
)
```

Chart src files are not mandatory, you can specify all the chart configuration via rule attributes.
In this case the rule will take care of generating the chart files for you (Chart.yaml, values.yaml, template files, chart deps...).

```starlark
chart_srcs(
    name = "chart",
    chart_name = "example",
    version = "v1.0.0",
    app_version = "v2.3.4",
    api_version = "v2",
    description = "Helm chart description placed inside Chart.yaml",
    image = ":oci_image",
    values = {
        "yaml.path.to.value": "value",
    },
)
```

Stamp variables are supported in values attribute. To enable the use of stamp variables enable them via stamp attribute and --stamp flag in bazel.
You can customize stamped variables using bazel workspace status. See [the Bazel workspace status docs](https://docs.bazel.build/versions/master/user-manual.html#workspace_status)

All values with ${} format will be replaced by stamped variables (both volatile and stable are supported).

```starlark
chart_srcs(
    name = "chart",
    chart_name = "example",
    srcs = glob(["**"]),
    stamp = -1,
    values = {
        "stamped.value": "${STAMPED_VARIABLE}",
    },
)
```

For compatibility reasons, some attributes are still supported but marked as deprecated. Its use is discouraged.
"""

_DEPRECATED_ATTRS = {
    "values_repo_yaml_path": attr.string(mandatory = False, doc="[Deprecated] Yaml path used to set the repo config provided by `image_repository` attribute (deprecated). %s" % DEFAULT_VALUES_REPO_YAML),
    "chart_deps": attr.label_list(allow_files = True, mandatory = False, providers = [ChartInfo], doc="[Deprecated] Chart dependencies. Use deps attribute instead."),
    "helm_chart_version": attr.string(mandatory = False, doc="[Deprecated] Helm chart version. Use version instead."),
    "package_name": attr.string(mandatory = False, doc="[Deprecated] Helm chart name. Use chart_name instead."),
    "additional_templates": attr.label_list(allow_files = True, mandatory = False, doc="[Deprecated] Use templates instead."),
    "image_tag": attr.string(mandatory = False, doc="[Deprecated] Use image attribute instead."),
    "image_repository": attr.string(doc="[Deprecated] You can use values attr dict to modify repository values."),
}

_DEPRECATED_ATTRS_MSG = {
    "values_repo_yaml_path": "You can use values attr dict to modify repository values.",
    "chart_deps": "Use deps attribute instead.",
    "helm_chart_version": "Use version attribute instead.",
    "package_name": "Use chart_name instead.",
    "additional_templates": "Use templates attribute instead.",
    "image_tag": "Use image attribute instead.",
    "image_repository": "You can use values attr dict to modify repository values.",
}

_ATTRS = dicts.add({
        "chart_name": attr.string(mandatory = True, doc="Name of the chart. It will be modified in the name field of the Chart.yaml"),
        "srcs": attr.label_list(allow_files = True, default = [], doc="A list of helm chart source files."),
        "image": attr.label(allow_single_file = True, mandatory = False, doc="""
            Reference to image rule use to interpolate the image sha256 in the chart values.yaml.
            If provided, the sha256 of the image will be placed in the output values.yaml of the chart in the yaml path provided by `values_tag_yaml_path` attribute.
            Only oci_image rules are supported."""
        ),
        "image_digest": attr.label(allow_single_file = True, mandatory = False, doc="Reference to oci_image digest file. Used internally by the macro (do not use it)."),
        "values_tag_yaml_path": attr.string(default = ".image.tag", doc="Yaml path used to set the image sha256 inside the chart values.yaml."),
        "version": attr.string(mandatory = False, doc="Helm chart version to be placed in Chart.yaml manifest"),
        "version_manifest": attr.label(mandatory = False, allow_single_file = True, doc="Helm chart version file to be used to set the chart version in Chart.yaml manifest. The file can be a yaml file or a josn file containing a single key named version."),
        "app_version": attr.string(doc="Helm chart appVersion. The value is replaced in the output Chart.yaml manifest in the appVersion key."),
        "app_version_manifest": attr.label(mandatory = False, allow_single_file = True, doc="Helm chart appVersion file. The value is replaced in the output Chart.yaml manifest in the appVersion key. The file can be a yaml file or a json file containing a single key named version."),
        "api_version": attr.string(doc="Helm chart manifest apiVersion. The value is replaced in the output Chart.yaml manifest."),
        "description": attr.string(doc="Helm chart manifest description. The value is replaced in the output Chart.yaml manifest."),
        "deps": attr.label_list(allow_files = True, mandatory = False, providers = [ChartInfo], doc="""
            A list of helm chart that this helm chart depends on. They will be placed inside the `charts` directory.
            The dependencies will be traced inside the Chart.yaml manifest as well.
        """),
        "deps_conditions": attr.string_dict(doc="""
            A dictionary containing the conditions that the dependencies of the chart should met to be rendered by helm.
            The key has to be the name of the dependency chart. The value will be the condition that the values of the chart should have.
            Check helm doc for more info https://helm.sh/docs/topics/charts/#the-chartyaml-file
        """),
        "templates": attr.label_list(allow_files = True, mandatory = False, doc="""
            A list of files that will be added to the chart. They will be added as addition to the chart templates refernced in the `srcs` attribute.
        """),
        "values": attr.string_dict(doc="""
            A dictionary of key values to be written in to the chart values.
            keys: `yaml.path` or `.yaml.path`
            values:  the value to be replaced inside the Chart values.yaml.
            This attr supports use of stamped values. To provide a stamped value you have to use ${STAMP_VARIABLE_NAME} as value of the dict with
            your stamped variable key. Make sure to enable stamping in your rule with the attribute `stamp`.
        """),
        "force_repository_append": attr.bool(default = True, doc="""
            A flag to specify if @ should be appended to the repository value in the chart values.yaml (in case `image` rule attribute is specified).
            The rules will look for the specified repository value inside the values.yaml.
            This is intended to meet image url with digest format: `gcr.io/container@sha256:a12e258c58ab92be22e403d08c8ef7eefd6119235eddca01309fe6b21101e100`.
            If you have this already covered in your deployment templates, set this attr to false.
            If the flag is set to true, the image rule attr is provided and no `values_repo_yaml_path` is set, the rule will look for the default path of the
            repository value. %s
        """ % DEFAULT_VALUES_REPO_YAML),
        "path_to_chart": attr.string(doc="Attribute to specify the path to the root of the chart. This attribute is mandatory if neither Chart.yaml nor values.yaml are provided, and the chart srcs attr is not empty to determinate where in the path of the source files is located the root of the helm chart."),
        "_subst_template": attr.label(allow_single_file = True, default = ":substitute.sh.tpl"),
}, _DEPRECATED_ATTRS, STAMP_ATTRS)



def _find_outer_file(files):
    file = None if len(files) == 0 else files[0]

    for f in files:
        if len(f.path) < len(file.path):
            file = f

    return file

# filter out from chart src files Chart.yaml manifest and values.yaml files
def _filter_manifest_and_values_from_files(files):
    return [f for f in files if not f.path.endswith("Chart.yaml") and not f.path.endswith("values.yaml")]

# locate where the helm chart root is placed
def _locate_chart_roots(srcs, path_to_chart="", name=""):
    chart_manifests = []
    values = []
    requirements = []

    for src in srcs:
        if src.basename == "Chart.yaml":
            chart_manifests += [src]

        if src.basename == "values.yaml":
            values += [src]

        if src.basename == "requirements.yaml":
            requirements += [src]

    if len(srcs) > 0 and len(chart_manifests) == 0 and len(values) == 0 and not path_to_chart:
        fail("If you provide some chart source files, you have to provide either a Chart.yaml manifest either a values.yaml file or use the explicit attr 'path_to_chart'. Otherwise the root path of the chart %s cannot be located" % name)

    manifest = _find_outer_file(chart_manifests or [])
    value_file = _find_outer_file(values or [])
    requirements_file = _find_outer_file(requirements or [])

    root_path = manifest.dirname if manifest else value_file.dirname if value_file else path_to_chart

    return struct(
        manifest=manifest,
        values=value_file,
        requirements = requirements_file,
        root=root_path,
    )

# Returns a yq expression to extract a value from a JSON or YAML file.
def _yq_expression_value_from_file(file, key):
    return "(load(\"{}\") | .{} | ... style=\"\")".format(file.path, key)

# get a dict with the content to populate a Chart.yaml manifest with data fom the helm chart
def _get_manifest_subst_args(ctx, chart_deps, no_prev_manifest):
    subst_args = {}

    chart_name = ctx.attr.chart_name or ctx.attr.package_name

    version = ctx.attr.version or ctx.attr.helm_chart_version
    app_version = ctx.attr.app_version

    if ctx.file.version_manifest:
        version = _yq_expression_value_from_file(ctx.file.version_manifest, "version")

    if ctx.file.app_version_manifest:
        app_version = _yq_expression_value_from_file(ctx.file.app_version_manifest, "version")

    if ctx.attr.api_version or no_prev_manifest:
        subst_args["apiVersion"] = ctx.attr.api_version or DEFAULT_HELM_API_VERSION

    subst_args["name"] = chart_name

    if ctx.attr.description:
        subst_args["description"] = ctx.attr.description

    if version or no_prev_manifest:
        subst_args["version"] = version or DEFAULT_HELM_CHART_VERSION

    if app_version:
        subst_args["appVersion"] = app_version

    deps_conditions = ctx.attr.deps_conditions or {}

    for i, dep in enumerate(chart_deps):
        subst_args[".dependencies[%s].name" % i] = dep.name

        if dep.version:
            subst_args[".dependencies[%s].version" % i] = dep.version

        condition = deps_conditions.get(dep.name)

        if condition:
            subst_args[".dependencies[%s].condition" % i] = condition

    return subst_args


# generate a file with a yq write expression
def _create_yq_substitution_file(ctx, output_name, substitutions):
    out_file = ctx.actions.declare_file(output_name)

    subst_values = ""

    for yaml_path, value in substitutions.items():
        if len(subst_values) > 0:
            subst_values += " |\n"

        yaml_path = _normalize_yaml_path(yaml_path)

        if value.startswith("strenv(") or value.startswith("(load("):
            subst_values += "{yaml} = {value}".format(yaml=yaml_path, value=value)
        else:
            subst_values += "{yaml} = \"{value}\"".format(yaml=yaml_path, value=value)

    ctx.actions.write(
        output = out_file,
        content = subst_values
    )

    return out_file

# utility function to normalize yaml paths for yq tool
def _normalize_yaml_path(yaml_path):
    if not yaml_path or yaml_path.startswith("."):
        return yaml_path

    if yaml_path and not yaml_path.startswith("."):
        return "." + yaml_path

# function to parse stamp values variables format (${}) to envvariables read from yq (env())
def _replace_stamp_values(values):
    values_to_replace = {}

    for key, value in values.items():
        if value.startswith("${") and value.endswith("}"):
            values_to_replace[key] = value.replace("${", "strenv(").replace("}", ")")

    result_dict = dicts.add({}, values, values_to_replace)

    return result_dict


def _image_digest_processor(ctx):
    if not ctx.attr.image:
        return None

    sha_file = ctx.file.image_digest

    sha_shell_extr_expr = "$(cat {sha_file})".format(
        sha_file=sha_file.path
    )

    return struct(
        sha_file=sha_file,
        sha_expr=sha_shell_extr_expr,
    )

# print a warning message for every deprecated attribute provided to the rule
def _warn_deprecated_attr(ctx):
    for name, _ in _DEPRECATED_ATTRS.items():
        if getattr(ctx.attr, name):
            additional_msg = _DEPRECATED_ATTRS_MSG.get(name, "")
            print("WARNING: %s is marked as deprecated and should not be used. It could be removed soon - %s" % (name, additional_msg))


def _chart_srcs_impl(ctx):
    _warn_deprecated_attr(ctx)

    digest_path = ""
    image_tag = ""

    chart_yaml = None
    yq_bin = ctx.toolchains["@aspect_bazel_lib//lib:yq_toolchain_type"].yqinfo.bin
    copy_to_directory_bin = ctx.toolchains["@aspect_bazel_lib//lib:copy_to_directory_toolchain_type"].copy_to_directory_info.bin
    stamp_files = [ctx.info_file, ctx.version_file]
    chart_name = ctx.attr.chart_name or ctx.attr.package_name

    # data structure to hold info about all chart dependencies
    # it's a tuples array with the form: (dependency_name, dependency_version, dep src_files)
    chart_deps = [
        struct(
            name=chart_dep[ChartInfo].chart_name,
            version=chart_dep[ChartInfo].chart_version,
            srcs=chart_dep[ChartInfo].chart_srcs,
        ) for chart_dep in ctx.attr.deps
    ]

    # locate rootpath of the chart
    chart_files = _locate_chart_roots(ctx.files.srcs, ctx.attr.path_to_chart)
    chart_root_path = chart_files.root
    chart_yaml = chart_files.manifest
    requirements_yaml = chart_files.requirements

    if chart_files.values:
        values_inputs_depsets = [depset([yq_bin, chart_files.values])]
    else:
        values_inputs_depsets = [depset([yq_bin])]

    copied_src_files = []

    # copy all chart source files to the output bin directory
    # values.yaml are not copied to the output dir here to be able to modify the sources
    for file in _filter_manifest_and_values_from_files(ctx.files.srcs):
        copied_file = ctx.actions.declare_file(paths.join(ctx.attr.name, chart_name, file.path.replace(chart_root_path + "/", "")))
        copied_src_files += [copied_file]
        copy_file_action(
            ctx=ctx,
            src=file,
            dst=copied_file,
        )

    additional_templates = ctx.files.templates or ctx.files.additional_templates

    copied_tpl_files = []

    for template in additional_templates:
        copied_tpl = ctx.actions.declare_file(paths.join(ctx.attr.name, chart_name, "templates", template.basename))
        copied_tpl_files += [copied_tpl]
        copy_file_action(
            ctx=ctx,
            src=template,
            dst=copied_tpl,
        )

    # rewrite Chart.yaml to override chart info
    out_chart_yaml = ctx.actions.declare_file(paths.join(ctx.attr.name, chart_name, "Chart.yaml"))

    yq_subst_expr = _create_yq_substitution_file(ctx, "%s_yq_chart_subst_expr" % ctx.attr.name, _get_manifest_subst_args(ctx, chart_deps, chart_yaml == None))

    write_manifest_action_inputs = [yq_bin, yq_subst_expr]

    if ctx.file.version_manifest:
        write_manifest_action_inputs += [ctx.file.version_manifest]

    if ctx.file.app_version_manifest:
        write_manifest_action_inputs += [ctx.file.app_version_manifest]

    if chart_yaml:
        write_manifest_action_inputs += [chart_yaml]

    ctx.actions.run_shell(
        inputs = write_manifest_action_inputs,
        outputs = [out_chart_yaml],
        command = "cat {chart_manifest}| {yq} --from-file {expr_file} > {out_path}".format(
            yq = yq_bin.path,
            expr_file = yq_subst_expr.path,
            out_path = out_chart_yaml.path,
            chart_manifest = chart_yaml.path if chart_yaml else "",
        ),
        progress_message = "Writing Chart.yaml file to chart output dir...",
        mnemonic = "SubstChartManifest",
    )

    # rewrite requirements.yaml to override chart info
    out_requirements_yaml = ctx.actions.declare_file(paths.join(ctx.attr.name, chart_name, "requirements.yaml"))

    yq_subst_expr_requirements = _create_yq_substitution_file(ctx, "%s_yq_requirements_subst_expr" % ctx.attr.name, _get_manifest_subst_args(ctx, chart_deps, chart_yaml == None))

    write_manifest_action_inputs_requirements = [yq_bin, yq_subst_expr_requirements]

    if requirements_yaml:
        write_manifest_action_inputs_requirements += [requirements_yaml]

    ctx.actions.run_shell(
        inputs = write_manifest_action_inputs_requirements,
        outputs = [out_requirements_yaml],
        command = "cat {requirements_manifest}| {yq} --from-file {expr_file} > {out_path}".format(
            yq = yq_bin.path,
            expr_file = yq_subst_expr_requirements.path,
            out_path = out_requirements_yaml.path,
            requirements_manifest = requirements_yaml.path if requirements_yaml else "",
        ),
        progress_message = "Writing requirements.yaml file to chart output dir...",
        mnemonic = "SubstRequirementsManifest",
    )

    # Dictionary structure to hold substitute values
    # Used to replace values.yaml chart file
    values = {}

    src_values_path = paths.join(chart_root_path, "values.yaml")

    is_image_from_oci = ctx.attr.image

    # image digest is extracted from a file placed in bazel out
    sha_extr_expr = ""

    sha_info = _image_digest_processor(ctx)

    values_repo_path = ctx.attr.values_repo_yaml_path or DEFAULT_VALUES_REPO_YAML

    if sha_info:
        sha_extr_expr = sha_info.sha_expr
        values_inputs_depsets.append(depset([sha_info.sha_file]))

    if ctx.attr.image_tag:
        # extract oci image info from make variable or from rule attribute
        values[ctx.attr.values_tag_yaml_path] = ctx.attr.image_tag

    if ctx.attr.image_repository:
        values[values_repo_path] = ctx.attr.image_repository

    # image repository substitution is extracted from values.yaml if force_repository_append attr is provided
    image_repo_shell_expr = ''

    if ctx.attr.force_repository_append:
        _image_repository = ctx.attr.image_repository

        if is_image_from_oci:
            if not _image_repository:
                # Add @sha256 suffix to image repository based on actual values
                image_repo_shell_expr = "$({yq} {repo} {values})@".format(
                    yq=yq_bin.path,
                    repo=values_repo_path,
                    values=src_values_path,
                )
            else:
                values[values_repo_path] = _image_repository + "@"

    all_values = dicts.add({}, ctx.attr.values, values)

    stamp = maybe_stamp(ctx)

    if stamp:
        all_values = _replace_stamp_values(all_values)

    yq_expression_file = _create_yq_substitution_file(ctx, "%s_yq_values_subst_expression_file" % ctx.attr.name, all_values)

    output_values_script_yaml = ctx.actions.declare_file("%s_subst_values.sh" % ctx.attr.name)
    output_values_yaml = ctx.actions.declare_file(paths.join(ctx.attr.name, chart_name, "values.yaml"))

    values_substitutions = {
        "{yq}": yq_bin.path,
        "{expression}": yq_expression_file.path,
        "{out}": output_values_yaml.path,
        "{values}": src_values_path,
        "{image_digest_expr}": sha_extr_expr,
        "{image_tag_path}": _normalize_yaml_path(ctx.attr.values_tag_yaml_path),
        "{image_repo_expr}": image_repo_shell_expr,
        "{image_repo_path}": _normalize_yaml_path(values_repo_path)
    }

    if stamp:
        stamp_files = [stamp.volatile_status_file, stamp.stable_status_file]
        values_inputs_depsets.append(depset(stamp_files))
        values_substitutions = dicts.add(values_substitutions, {
            "{stable}": stamp.stable_status_file.path,
            "{volatile}": stamp.volatile_status_file.path,
            "{stamp}": "true",
            "%{stamp_statements}": "\n".join([
                "\tread_stamp_variables %s" % f.path
                for f in stamp_files
            ]),
        })

    ctx.actions.expand_template(
        template = ctx.file._subst_template,
        output = output_values_script_yaml,
        is_executable = True,
        substitutions = values_substitutions,
    )

    values_inputs_depsets.append(depset([yq_expression_file, output_values_script_yaml]))

    ctx.actions.run(
        inputs = depset(transitive=values_inputs_depsets),
        outputs = [output_values_yaml],
        executable = output_values_script_yaml,
        progress_message = "Writing values to chart values.yaml file...",
        mnemonic = "SubstChartValues",
    )

    dep_copied_files_depset = []

    for dep in chart_deps:

        dep_chart_files = _locate_chart_roots(dep.srcs, "", dep.name)

        for dep_src in dep.srcs:
            out_path = paths.join(ctx.attr.name, chart_name, "charts", dep.name, dep_src.path.replace(dep_chart_files.root + "/", ""))

            dep_out = ctx.actions.declare_file(out_path)

            copy_file_action(
                ctx=ctx,
                src=dep_src,
                dst=dep_out,
            )

            dep_copied_files_depset.append(depset([dep_out]))

    return [
        DefaultInfo(
            files = depset(
                direct = copied_src_files + copied_tpl_files + [out_chart_yaml, output_values_yaml, out_requirements_yaml],
                transitive = dep_copied_files_depset
            )
        )
    ]

chart_srcs = rule(
    implementation = _chart_srcs_impl,
    attrs = _ATTRS,
    doc = _DOC,
    toolchains = [
        "@aspect_bazel_lib//lib:yq_toolchain_type",
        "@aspect_bazel_lib//lib:copy_to_directory_toolchain_type",

    ] + COPY_FILE_TOOLCHAINS,
)
