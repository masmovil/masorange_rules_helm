load("@aspect_bazel_lib//lib:copy_to_bin.bzl", "copy_files_to_bin_actions")
load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:shell.bzl", "shell")

_PROVIDER_DOC = """
    `helm_chart` expose ChartInfo providers to be able to access info about a packaged chart. The info available is:
    - The name of the chart
    - The version of the chart
    - The ouput sources of the chart
    - The output archive file targz
"""

ChartInfo = provider(
    doc = _PROVIDER_DOC,
    fields = {
        "targz": "The output of helm_chart. This is the versioned packaged targz of the chart",
        "chart_name": "The name of the chart as is reflected in the Chart.yaml manifest and provided by the rule attribute",
        "chart_version": "If provided, the version of the chart",
        "chart_srcs": "The sources of the chart before beign packaged into the archived targz",
    }
)

_ATTRS = {
    "chart_name": attr.string(mandatory = True),
    "chart_targz": attr.label(allow_single_file = True, mandatory = True),
    "chart_bin_srcs": attr.label(allow_files = True, mandatory = True),
    "chart_version": attr.string(mandatory = False),
}

def _helm_chart_providers_impl(ctx):
    targz_deps = depset(ctx.files.chart_targz)

    return [
        DefaultInfo(
            files = targz_deps
        ),
        ChartInfo(
            targz = targz_deps,
            chart_srcs = ctx.files.chart_bin_srcs,
            chart_name = ctx.attr.chart_name,
            chart_version = ctx.attr.chart_version,
        ),
    ]

helm_chart_providers = rule(
    implementation = _helm_chart_providers_impl,
    attrs = _ATTRS,
)
