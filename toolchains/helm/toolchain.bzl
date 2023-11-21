HELM_DEFAULT_VERSION = "v3.13.1"

HELM_VERSIONS = {
    "v3.13.1": {
        "linux_amd64": "98c363564d00afd0cc3088e8f830f2a0eeb5f28755b3d8c48df89866374a1ed0",
        "linux_arm64": "8c4a0777218b266a7b977394aaf0e9cef30ed2df6e742d683e523d75508d6efe",
        # "linux_arm": "a9c188c1a79d2eb1721aece7c4e7cfcd56fa76d1e37bd7c9c05d3969bb0499b4",
        "linux_i386": "384e1f97b6dafad62ccdd856e9453b68143e4dbdc7b9cf9a2a2f79c2aa7c2cc9",
        "darwin_amd64": "e207e009b931162b0383b463c333a2792355200e91dbcf167c97c150e9f5fedb",
        "darwin_arm64": "46596d6d2d9aa545eb74f40684858fac0841df373ca760af1259d3493161d8c9",
        "windows_amd64": "6e16fbc5e50a5841be2dc725e790234f09aa2a5ebe289493c90f65ecae7b156f",
    }
}

HELM_PLATFORMS = {
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
    "linux_arm64": struct(
        compatible_with = [
            "@platforms//os:linux",
            "@platforms//cpu:aarch64",
        ],
    ),
    "linux_arm": struct(
        compatible_with = [
            "@platforms//os:linux",
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
    "windows_amd64": struct(
        compatible_with = [
            "@platforms//os:windows",
            "@platforms//cpu:x86_64",
        ],
    ),
}

HelmToolchainInfo = provider(
    doc = "Helm toolchain",
    fields = {
        "bin": "Helm executable binary",
        # "helm_xdg_data_home": "Helm data home path",
        # "helm_xdg_config_home": "Helm config home path",
        # "helm_xdg_cache_home": "Helm cache home path"
    },
)

def _helm_toolchain_impl(ctx):
    binary = ctx.attr.bin.files.to_list()[0]

    template_variables = platform_common.TemplateVariableInfo({
        "HELM_BIN": binary.path,
    })

    toolchain_info = platform_common.ToolchainInfo(
        helminfo = HelmToolchainInfo(
            bin = binary,
            # helm_xdg_data_home = ctx.attr.helm_xdg_data_home,
            # helm_xdg_config_home = ctx.attr.helm_xdg_config_home,
            # helm_xdg_cache_home = ctx.attr.helm_xdg_cache_home
        ),
    )
    return [toolchain_info, template_variables]

helm_toolchain = rule(
    implementation = _helm_toolchain_impl,
    attrs = {
        "bin": attr.label(mandatory = True, allow_single_file = True),
        # "helm_xdg_data_home": attr.string(),
        # "helm_xdg_config_home": attr.string(),
        # "helm_xdg_cache_home": attr.string()
    },
)

def _helm_repo_impl(rctx):
    version = rctx.attr.version
    platform = rctx.attr.platform
    sha = rctx.attr.sha
    is_windows = platform.startswith("windows_")

    processed_platform = platform.replace("_", "-").replace("i386", "386")

    rctx.report_progress("Downloading helm binary helm-{version}-{platform}...".format(
        version=version,
        platform=processed_platform,
    ))

    rctx.download_and_extract(
        url = "https://get.helm.sh/helm-{version}-{platform}.tar.gz".format(
            version=version,
            platform=processed_platform,
        ),
        sha256 = sha,
        output = "helm",
        # executable = True,
        stripPrefix = processed_platform,
    )

    build_content = """
load("@masmovil_bazel_rules//toolchains/helm:toolchain.bzl", "helm_toolchain")

exports_files(["{0}"])

helm_toolchain(name = "helm_toolchain", bin = "{0}", visibility = ["//visibility:public"])
""".format("helm")
    # .format("helm.exe" if is_windows else "helm")

    # Base BUILD file for this repository
    rctx.file("BUILD.bazel", build_content)

helm_repo = repository_rule(
    implementation = _helm_repo_impl,
    doc = "Fetch external tools needed for helm toolchain",
    attrs = {
        "version": attr.string(mandatory = True, values = HELM_VERSIONS.keys()),
        "platform": attr.string(mandatory = True,),
        "sha": attr.string(mandatory = True),
    },
)

def _helm_toolchain_configure_impl(rctx):

    build_content = """
package(default_visibility = ["//visibility:public"])
    """

    for [platform, meta] in HELM_PLATFORMS.items():
        # TODO: make repo name a variable with a default to enable override toolchain versions
        build_content += """
toolchain(
    name = "{platform}_toolchain",

    exec_compatible_with = {compatible_with},
    toolchain = "@helm_{platform}//:helm_toolchain",
    toolchain_type = "@masmovil_bazel_rules//toolchains/helm:toolchain_type",
)
""".format(
            platform = platform,
            compatible_with = meta.compatible_with,
            # user_repository_name = rctx.attr.user_repository_name,
        )

    rctx.file("BUILD.bazel", build_content)


helm_toolchain_configure = repository_rule(
    implementation = _helm_toolchain_configure_impl,
    doc = """Creates a repository with toolchain definitions for all known platforms
     which can be registered or selected.""",
    attrs = {},
)