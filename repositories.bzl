# Internal use only.
# Install rule dependencies for local testing pourposes only (rule authors).

load("//:toolchains.bzl", "register_helm_toolchains", "register_sops_toolchains", "register_gcloud_toolchains", "register_kubectl_toolchains")
load("//helm/private:helm_toolchain.bzl", "HELM_DEFAULT_VERSION")
load("//gcs/private:gcloud_toolchain.bzl", "GCLOUD_DEFAULT_VERSION")
load("//k8s/private:kubectl_toolchain.bzl", "KUBECTL_DEFAULT_VERSION")
load("//sops/private:sops_toolchain.bzl", "SOPS_DEFAULT_VERSION")
load("@bazel_tools//tools/build_defs/repo:http.bzl", _http_archive = "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def http_archive(**kwargs):
    maybe(_http_archive, **kwargs)

def masorange_rules_helm_repositories():
    http_archive(
        name = "bazel_skylib",
        sha256 = "cd55a062e763b9349921f0f5db8c3933288dc8ba4f76dd9416aac68acee3cb94",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.5.0/bazel-skylib-1.5.0.tar.gz",
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.5.0/bazel-skylib-1.5.0.tar.gz",
        ],
    )

    http_archive(
        name = "rules_pkg",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/rules_pkg/releases/download/0.10.0/rules_pkg-0.10.0.tar.gz",
            "https://github.com/bazelbuild/rules_pkg/releases/download/0.10.0/rules_pkg-0.10.0.tar.gz",
        ],
        sha256 = "e93b7309591cabd68828a1bcddade1c158954d323be2205063e718763627682a",
    )

    http_archive(
        name = "rules_oci",
        sha256 = "58b7a175ee90c12583afeca388523adf6a4e5a0528f330b41c302b91a4d6fc06",
        strip_prefix = "rules_oci-1.6.0",
        url = "https://github.com/bazel-contrib/rules_oci/releases/download/v1.6.0/rules_oci-v1.6.0.tar.gz",
    )

    http_archive(
        name = "aspect_bazel_lib",
        sha256 = "bda4a69fa50411b5feef473b423719d88992514d259dadba7d8218a1d02c7883",
        strip_prefix = "bazel-lib-2.3.0",
        url = "https://github.com/aspect-build/bazel-lib/releases/download/v2.3.0/bazel-lib-v2.3.0.tar.gz",
    )


def internal_deps():
    http_archive(
        name = "io_bazel_stardoc",
        sha256 = "62bd2e60216b7a6fec3ac79341aa201e0956477e7c8f6ccc286f279ad1d96432",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/stardoc/releases/download/0.6.2/stardoc-0.6.2.tar.gz",
            "https://github.com/bazelbuild/stardoc/releases/download/0.6.2/stardoc-0.6.2.tar.gz",
        ],
    )
