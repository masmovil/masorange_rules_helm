load(":chart_srcs.bzl", "chart_srcs")
load(":helm_lint_test.bzl", "helm_lint_test")
load(":helm_chart_providers.bzl", "helm_chart_providers")
load("@rules_pkg//pkg:tar.bzl", "pkg_tar")
load("@rules_pkg//pkg:mappings.bzl", "pkg_filegroup", "pkg_files", "strip_prefix")

def helm_chart(name, chart_name, **kwargs):
    """Bazel macro function to package a helm chart in to a targz archive file.

    The macro is intended to be used as the public API for packaging a chart. It is a wrapper around `chart_srcs` rule. All the args are propagated to `chart_srcs` rule.
    See [chart_srcs](#chart_srcs) arguments to see the available config.


    To load the rule use:
    ```starlark
    load("//helm:defs.bzl", "helm_chart")
    ```

    It also defines a %name%_lint test target to be able to test that your chart is well-formed (using `helm lint`).

    To make the output reproducible this macro does not use `helm package` to package the chart into a versioned chart archive file.
    It uses `pkg_tar` bazel rule instead to create the archive file. Check this to find more info about it:
    - https://github.com/masmovil/bazel-rules/issues/55
    - https://github.com/helm/helm/issues/3612#issuecomment-525340295

    This macro exports some providers to share info about charts between rules. Check [helm_chart providers](#providers).

    The args are the same that the `chart_srcs` rule, check [chart_srcs](#chart_srcs).

    ```starlark
    load("//helm:defs.bzl", "helm_chart")

    helm_chart(
        name = "basic_chart",
        chart_name = "example",
        srcs = glob(["**"]),
    )

    helm_chart(
        name = "basic_chart",
        chart_name = "example",
        srcs = glob(["**"]),
        values = {
            "override.value": "valueoverrided",
        }
    )

    helm_chart(
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

    # version file version.json
    {
        "version": "v1.0.0",
    }

    # BULD.bazel
    helm_chart(
        name = "chart",
        chart_name = "example",
        version_file = ":version.json",
        app_version = "v2.3.4",
        api_version = "v2",
        description = "Helm chart description placed inside Chart.yaml",
        image = ":oci_image",
        values = {
            "yaml.path.to.value": "value",
        },
    )
    ```

    Args:

        All: This is a wrapper around `chart_srcs` rule. All the args are propagated to `chart_srcs`. See [chart_srcs](#chart_srcs)
            to check the available config.
    """


    helm_pkg_target = "%s_package" % name
    helm_pkg_out_strip_target = "%s_src_helm_files" % name
    tar_target = "%s_tar" % name

    image = kwargs.get("image")
    chart_version = kwargs.get("version") or kwargs.get("helm_chart_version")
    # TODO: change how visibility is propagated
    visibility = kwargs.get("visibility") or ["//visibility:public"]

    chart_srcs_attrs = dict({}, **kwargs)

    if image:
       chart_srcs_attrs["image_digest"] = image + ".digest"

    chart_srcs(
        name = helm_pkg_target,
        chart_name = chart_name,
        **chart_srcs_attrs,
    )

    pkg_files(
        name = helm_pkg_out_strip_target,
        srcs = [helm_pkg_target],
        strip_prefix = strip_prefix.from_pkg(),
        visibility = visibility,
    )

    pkg_tar(
        name = tar_target,
        out = chart_name + ".tgz",
        extension = "tgz",
        srcs = [helm_pkg_out_strip_target],
        visibility = visibility,
    )

    helm_chart_providers(
        name = name,
        chart_name = chart_name,
        chart_targz = tar_target,
        chart_version = chart_version,
        chart_bin_srcs = helm_pkg_target,
        visibility = visibility,
    )

    helm_lint_test(
        name = "%s_lint" % name,
        chart = name,
    )
