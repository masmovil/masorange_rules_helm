load("@masmovil_bazel_rules//helm:defs.bzl", "helm_pull")
load("@masmovil_bazel_rules//toolchains:register.bzl", "register_helm_toolchains", "register_sops_toolchains", "register_gcloud_toolchains", "register_kubectl_toolchains")
load("@masmovil_bazel_rules//toolchains/helm:toolchain.bzl", "HELM_DEFAULT_VERSION")
load("@masmovil_bazel_rules//toolchains/sops:toolchain.bzl", "SOPS_DEFAULT_VERSION")
load("@masmovil_bazel_rules//toolchains/gcloud:toolchain.bzl", "GCLOUD_DEFAULT_VERSION")
load("@masmovil_bazel_rules//toolchains/kubectl:toolchain.bzl", "KUBECTL_DEFAULT_VERSION")

pull_attrs = {
    "chart_name": attr.string(mandatory = True),
    "name": attr.string(mandatory = True),
    "url": attr.string(mandatory = True),
    "version": attr.string(mandatory = True),
    "sha256": attr.string(mandatory = False, doc = "Sha of the helm chart"),
}

def _toolchains_extension_impl(mctx):
    for mod in mctx.modules:
        for attr in mod.tags.helm:
            register_helm_toolchains(attr.name, attr.version)

        for attr in mod.tags.sops:
            register_sops_toolchains(attr.name, attr.version)

        for attr in mod.tags.gcloud:
            register_gcloud_toolchains(attr.name, attr.version)

        for attr in mod.tags.kubectl:
            register_kubectl_toolchains(attr.name, attr.version)

        for pull in mod.tags.pull:
            helm_pull(
                chart_name = pull.chart_name,
                name = pull.name,
                url = pull.url,
                version = pull.version,
                sha256 = pull.sha256,
            )


toolchains = module_extension(
    implementation = _toolchains_extension_impl,
    tag_classes = {
        "pull": tag_class(attrs = pull_attrs),
        "helm": tag_class(attrs = {"name": attr.string(default = "helm"), "version": attr.string(default = HELM_DEFAULT_VERSION)}),
        "kubectl": tag_class(attrs = {"name": attr.string(default = "kubectl"), "version": attr.string(default = KUBECTL_DEFAULT_VERSION)}),
        "gcloud": tag_class(attrs = {"name": attr.string(default = "gcloud"), "version": attr.string(default = GCLOUD_DEFAULT_VERSION)}),
        "sops": tag_class(attrs = {"name": attr.string(default = "sops"), "version": attr.string(default = SOPS_DEFAULT_VERSION)}),
    },
)