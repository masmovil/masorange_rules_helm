load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

exports_files(
    glob(["*.bzl"]),
    visibility = ["//docs:__pkg__"],
)

exports_files(["substitute.sh.tpl"])

bzl_library(
    name = "helm_chart_providers",
    srcs = ["helm_chart_providers.bzl"],
    visibility = [
        "//docs:__pkg__",
        "//helm:__subpackages__",
    ],
    deps = [
        "@aspect_bazel_lib//lib:copy_to_bin",
        "@bazel_skylib//lib:dicts",
        "@bazel_skylib//lib:paths",
        "@bazel_skylib//lib:shell",
    ],
)

bzl_library(
    name = "chart_srcs",
    srcs = ["chart_srcs.bzl"],
    visibility = [
        "//docs:__pkg__",
        "//helm:__subpackages__",
    ],
    deps = [
        ":helm_chart_providers",
        "@aspect_bazel_lib//lib:copy_file",
        "@aspect_bazel_lib//lib:stamping",
        "@bazel_skylib//lib:dicts",
        "@bazel_skylib//lib:paths",
    ],
)

bzl_library(
    name = "helm_lint",
    srcs = ["helm_lint_test.bzl"],
    visibility = [
        "//docs:__pkg__",
        "//helm:__subpackages__",
    ],
    deps = [
        "@bazel_skylib//rules:write_file",
        ":helm_chart_providers",
    ],
)

bzl_library(
    name = "helm_chart",
    srcs = ["helm_chart.bzl"],
    visibility = [
        "//docs:__pkg__",
        "//helm:__subpackages__",
    ],
    deps = [
        ":chart_srcs",
        ":helm_chart_providers",
        ":helm_lint",
        "@rules_pkg//pkg:bzl_srcs",
    ],
)

bzl_library(
    name = "helm_pull",
    srcs = ["helm_pull.bzl"],
    visibility = [
        "//docs:__pkg__",
        "//helm:__subpackages__",
    ],
    deps = [
        "@bazel_skylib//lib:paths",
    ],
)

bzl_library(
    name = "helm_push",
    srcs = ["helm_push.bzl"],
    visibility = [
        "//docs:__pkg__",
        "//helm:__subpackages__",
    ],
    deps = [
        ":helm_chart_providers",
    ],
)

bzl_library(
    name = "helm_release",
    srcs = ["helm_release.bzl"],
    visibility = [
        "//docs:__pkg__",
        "//helm:__subpackages__",
    ],
    deps = [
        "//k8s",
    ],
)

bzl_library(
    name = "helm_uninstall",
    srcs = ["helm_uninstall.bzl"],
    visibility = [
        "//docs:__pkg__",
        "//helm:__subpackages__",
    ],
    deps = [
        "//k8s",
    ],
)
