load("@aspect_bazel_lib//lib:diff_test.bzl", "diff_test")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("@aspect_bazel_lib//lib:run_binary.bzl", "run_binary")
load("@aspect_bazel_lib//lib:tar.bzl", "tar")

def add_prefix_to_paths(prefix, files_path):
  return [paths.join(prefix, path) for path in files_path]

def filter_man_values_from_files(files):
    return [file_path for file_path in files if not file_path.endswith("Chart.yaml") and not file_path.endswith("values.yaml")]

def compare_to_yaml_file_test(name, yaml_file_path, explicit_yaml_to_compare, chart):
    sh_test_rulename = "_%s_diff" % name
    expected_yaml_rulename = "_%s_expected" % name
    test_rulename =  "%s_diff" % name

    write_file(
        name = expected_yaml_rulename,
        out = "%s_expected.yaml" % name,
        content = [explicit_yaml_to_compare],
    )

    write_file(
        name = sh_test_rulename,
        out = "%s_diff.sh" % name,
        content = [
            "diff <($1 -P 'sort_keys(..)' -o=props $2) <($1 -P 'sort_keys(..)' -o=props $3)"
        ],
    )

    native.sh_test(
        name = test_rulename,
        srcs = [sh_test_rulename],
        data = ["@yq_toolchains//:resolved_toolchain", expected_yaml_rulename, chart],
        args = [
            "$(YQ_BIN)",
            yaml_file_path,
            "$(location %s)" % expected_yaml_rulename
        ],
        toolchains = ["@yq_toolchains//:resolved_toolchain"],
    )

    return  test_rulename

def untar_chart(name, chart_tar, out_dir):
    write_file(
        name = "{}_tar_sh".format(name),
        out = "{}_tar.sh".format(name),
        content = [
            "#!/usr/bin/env bash",
            "set -e",
            "$BSDTAR_BIN $@",
        ],
    )

    native.sh_binary(
        name = "{}_tar_bin".format(name),
        srcs = [ ":{}_tar_sh".format(name) ],
    )

    # Extract the tar
    run_binary(
        name = name,
        srcs = [
            chart_tar,
            "@bsd_tar_toolchains//:resolved_toolchain",
        ],
        out_dirs = [ out_dir ],
        env = {
            "BSDTAR_BIN": "$(BSDTAR_BIN)",
        },
        args = [
            "-xvzf",
            "$(location {})".format(chart_tar),
            "-C",
            "$(@)",
        ],
        tool = "{}_tar_bin".format(name),
        toolchains = [ "@bsd_tar_toolchains//:resolved_toolchain" ],
    )


def chart_test(name, chart, chart_name, prefix_srcs = "", expected_files=[], expected_values="", expected_manifest="", expected_deps=[]):
    unpacked_chart_rule_name = "%s_unpacked" % name

    untar_chart(
        name = unpacked_chart_rule_name,
        chart_tar = chart,
        out_dir = "%s_out_dir" % unpacked_chart_rule_name,
    )

    # # unpack helm_chart output targz
    # run_binary(
    #     name = unpacked_chart_rule_name,

    #     out_dirs = ["%s_out_dir" % unpacked_chart_rule_name],
    # )
    # native.genrule(
    #     name = unpacked_chart_rule_name,
    #     outs = ["%s_out_dir" % unpacked_chart_rule_name],
    #     tools = [chart],
    #     cmd_bash = "mkdir -p $@ && tar -xvf $(location %s) -C $@" % chart,
    # )

    tests = []

    if expected_values != "":
        # test_diff of values.yaml
        tests += [compare_to_yaml_file_test(
            name = "%s_values_test_diff" % name,
            yaml_file_path = "$(location %s)/%s/values.yaml" % (unpacked_chart_rule_name, chart_name),
            explicit_yaml_to_compare = expected_values,
            chart = unpacked_chart_rule_name,
        )]

    if expected_manifest != "":
        # test_diff of Chart.yaml
        tests += [compare_to_yaml_file_test(
            name = "%s_manifest_test_diff" % name,
            yaml_file_path = "$(location %s)/%s/Chart.yaml" % (unpacked_chart_rule_name, chart_name),
            explicit_yaml_to_compare = expected_manifest,
            chart = unpacked_chart_rule_name,
        )]

    sh_diff_rulename = "_%s_src_diff.sh" % name

    write_file(
        name = sh_diff_rulename,
        out = "%s_src_diff.sh" % name,
        content = [
            "diff $1 $2"
        ],
    )

    filtered_expected_files = filter_man_values_from_files(expected_files)

    for i, expected_file in enumerate(filtered_expected_files):
        # test_diff of chart src file vs dest files
        src_diff_test_rulename = "%s_%s_src_diff_test_%d" % (name, paths.basename(expected_file), i)
        src_orig_path = paths.join(prefix_srcs, expected_file)
        native.sh_test(
            name = src_diff_test_rulename,
            srcs = [sh_diff_rulename],
            data = [src_orig_path, unpacked_chart_rule_name],
            args = [
                "$(location %s)/%s/%s" % (unpacked_chart_rule_name, chart_name, expected_file),
                "$(location %s)" % src_orig_path,
            ]
        )
        tests += [src_diff_test_rulename]

    for dep in expected_deps:
        dep_name = dep.get("name")
        dep_values = dep.get("expected_values")
        dep_manifest = dep.get("expected_manifest")
        dep_files = dep.get("expected_files")
        dep_prefix_src = dep.get("prefix_srcs")

        filtered_dep_files = filter_man_values_from_files(dep_files)

        if dep_values:
            tests += [
                # test_diff of values.yaml in chart dependency
                compare_to_yaml_file_test(
                    name = "%s_%s_values_dep_test_diff" % (dep_name, name),
                    yaml_file_path = "$(location %s)/%s/charts/%s/values.yaml" % (unpacked_chart_rule_name, chart_name, dep_name),
                    explicit_yaml_to_compare = dep_values,
                    chart = unpacked_chart_rule_name,
                )
            ]

        if dep_manifest:
            tests += [
                # test_diff of Chart.yaml in chart dependency
                compare_to_yaml_file_test(
                    name = "%s_%s_manifest_dep_test_diff" % (dep_name, name),
                    yaml_file_path = "$(location %s)/%s/charts/%s/Chart.yaml" % (unpacked_chart_rule_name, chart_name, dep_name),
                    explicit_yaml_to_compare = dep_manifest,
                    chart = unpacked_chart_rule_name,
                )
            ]

        for i, file in enumerate(filtered_dep_files):
            # test_diff of chart src file vs dest files
            src_diff_test_rulename = "%s_%s_%s_src_diff_test_%d" % (dep_name, name, paths.basename(file), i)
            dep_file_src = paths.join(dep_prefix_src, file)
            native.sh_test(
                name = src_diff_test_rulename,
                srcs = [sh_diff_rulename],
                data = [dep_file_src, unpacked_chart_rule_name],
                args = [
                    "$(location %s)/%s/charts/%s/%s" % (unpacked_chart_rule_name, chart_name, dep_name, file),
                    "$(location %s)" % dep_file_src,
                ]
            )
            tests += [src_diff_test_rulename]

    # group all tests in a test_suite rule
    native.test_suite(
        name = name,
        tests = tests,
    )
