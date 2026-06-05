KUBECTL_DEFAULT_VERSION = "v1.28.2"

KUBECTL_VERSIONS = {
    "v1.28.2": {
        "linux_amd64": "c922440b043e5de1afa3c1382f8c663a25f055978cbc6e8423493ec157579ec5",
        "linux_arm64": "ea6d89b677a8d9df331a82139bb90d9968131530b94eab26cee561531eff4c53",
        "linux_386": "4433dfae47fb700f49233f5e8631944d8dd1e0572ee025c2cc44fee0aa431c2c",
        "darwin_amd64": "fb90ffc2b1751537ec1131276dd3a2f165464191025c3392a0ee2ed1575a19f0",
        "darwin_arm64": "a00300f8463f659f4eeb04ff2ad92fec5f552e3de041bf4eae23587cc7408fbc",
        "windows_amd64": "b52b17a1fcfa6cc1cb3e480a0d6066c7d7175159ecd4a62ac8e44d8ce2c7a931",
        "windows_386": "fe876c2123834217abef216ef170d58f3266956fb835d1b1f63538f00fb82db8",
    }
}

KUBECTL_PLATFORMS = {
    "darwin_amd64": struct(
        compatible_with = [
            "@platforms//os:macos",
            "@platforms//cpu:x86_64",
        ],
    ),
    "darwin_arm64": struct(
        compatible_with = [
            "@platforms//os:macos",
            "@platforms//cpu:aarch64",
        ],
    ),
    "linux_386": struct(
        compatible_with = [
            "@platforms//os:linux",
            "@platforms//cpu:x86_32",
        ],
    ),
    "linux_amd64": struct(
        compatible_with = [
            "@platforms//os:linux",
            "@platforms//cpu:x86_64",
        ],
    ),
    "linux_arm64": struct(
        compatible_with = [
            "@platforms//os:linux",
            "@platforms//cpu:aarch64",
        ],
    ),
    "windows_amd64": struct(
        compatible_with = [
            "@platforms//os:windows",
            "@platforms//cpu:x86_64",
        ],
    ),
    "windows_386": struct(
        compatible_with = [
            "@platforms//os:windows",
            "@platforms//cpu:x86_32",
        ],
    ),
}

KubectlToolchainInfo = provider(
    doc = "Kubectl toolchain",
    fields = {
        "bin": "Kubectl executable binary"
    },
)

def _kubectl_toolchain_impl(ctx):
    binary = ctx.attr.bin.files.to_list()[0]

    template_variables = platform_common.TemplateVariableInfo({
        "KUBECTL_BIN": binary.path,
    })
    default_info = DefaultInfo(
        files = depset([binary]),
        runfiles = ctx.runfiles(files = [binary]),
    )
    kubectlinfo = KubectlToolchainInfo(
        bin = binary
    )

    toolchain_info = platform_common.ToolchainInfo(
        default = default_info,
        template_variables = template_variables,
        kubectlinfo = kubectlinfo,
    )

    return [toolchain_info]

kubectl_toolchain = rule(
    implementation = _kubectl_toolchain_impl,
    attrs = {
        "bin": attr.label(mandatory = True, allow_single_file = True),
    },
)

def _kubectl_repo_impl(rctx):
    version = rctx.attr.version
    platform = rctx.attr.platform
    sha = rctx.attr.sha

    normalized_platform = platform.replace("_", "/")

    rctx.report_progress("Downloading kubectl-{version}-{platform}...".format(
        version=version,
        platform=normalized_platform,
    ))

    rctx.download(
        url = "https://dl.k8s.io/release/{version}/bin/{platform}/kubectl".format(
            version=version,
            platform=normalized_platform,
        ),
        executable = True,
        output = "kubectl",
        sha256 = sha,
    )

    build_content = """
load("@masorange_rules_helm//k8s/private:kubectl_toolchain.bzl", "kubectl_toolchain")

exports_files(["kubectl"])

kubectl_toolchain(name = "kubectl_toolchain", bin = "kubectl", visibility = ["//visibility:public"])
"""

    # Base BUILD file for this repository
    rctx.file("BUILD.bazel", build_content)

kubectl_repo = repository_rule(
    implementation = _kubectl_repo_impl,
    doc = "Fetch kubectl binary",
    attrs = {
        "version": attr.string(mandatory = True, values = KUBECTL_VERSIONS.keys()),
        "platform": attr.string(mandatory = True,),
        "sha": attr.string(mandatory = True),
    },
)

def _kubectl_toolchain_configure_impl(rctx):

    # Expose a concrete toolchain which is the result of Bazel resolving the toolchain
    # for the execution or target platform.
    # Workaround for https://github.com/bazelbuild/bazel/issues/14009
    starlark_content = """

# Forward all the providers
def _resolved_toolchain_impl(ctx):
    toolchain_info = ctx.toolchains["@masorange_rules_helm//k8s:kubectl_toolchain_type"]
    return [
        toolchain_info,
        toolchain_info.default,
        toolchain_info.kubectlinfo,
        toolchain_info.template_variables,
    ]

# Copied from java_toolchain_alias
# https://cs.opensource.google/bazel/bazel/+/master:tools/jdk/java_toolchain_alias.bzl
resolved_toolchain = rule(
    implementation = _resolved_toolchain_impl,
    toolchains = ["@masorange_rules_helm//k8s:kubectl_toolchain_type"],
)
"""
    rctx.file("defs.bzl", starlark_content)

    build_content = """
package(default_visibility = ["//visibility:public"])

load(":defs.bzl", "resolved_toolchain")

resolved_toolchain(name = "resolved_toolchain", visibility = ["//visibility:public"])
    """

    for [platform, meta] in KUBECTL_PLATFORMS.items():
        # TODO: make repo name a variable with a default to enable override toolchain versions
        build_content += """
toolchain(
    name = "{platform}_toolchain",
    exec_compatible_with = {compatible_with},
    toolchain = "@kubectl_{platform}//:kubectl_toolchain",
    toolchain_type = "@masorange_rules_helm//k8s:kubectl_toolchain_type",
)
""".format(
            platform = platform,
            compatible_with = meta.compatible_with,
            # user_repository_name = rctx.attr.user_repository_name,
        )

    rctx.file("BUILD.bazel", build_content)


kubectl_toolchain_configure = repository_rule(
    implementation = _kubectl_toolchain_configure_impl,
    doc = """Creates a repository with toolchain definitions for all known platforms
     which can be registered or selected.""",
    attrs = {},
)
