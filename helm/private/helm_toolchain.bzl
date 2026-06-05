HELM_DEFAULT_VERSION = "v3.16.3"

HELM_VERSIONS = {
    "v3.16.3": {
        "linux_amd64": "f5355c79190951eed23c5432a3b920e071f4c00a64f75e077de0dd4cb7b294ea",
        "linux_arm64": "5bd34ed774df6914b323ff84a0a156ea6ff2ba1eaf0113962fa773f3f9def798",
        "linux_arm": "02ba2f3b1524113f49be6df25a0b4b3190010d6e218c8e2b2fde4578a8439a9c",
        "linux_i386": "70318f60fec3219680fff86c9293e2a92fb8b9a691d41791661074588f22768e",
        "darwin_amd64": "495d75b404a96fb664f1ca3f8cb01db2210aacc62dbfa1bbab30916abbb20a57",
        "darwin_arm64": "3a39f690173086e6eea17674751eb3c8b970c02697e49cecd4093eaa3cf89dcd",
        "windows_amd64": "1a52aa56e55168c3d3d2e45fa833a32290e4e3790559851dce1e707eb7728b81",
        "windows_arm64": "247a63269a83bb73c14e8f62b0cfd5a2e1d32b7d3f93977d3a6ef3902d218ff1",
    },
    "v3.13.2": {
        "linux_amd64": "55a8e6dce87a1e52c61e0ce7a89bf85b38725ba3e8deb51d4a08ade8a2c70b2d",
        "linux_arm64": "f5654aaed63a0da72852776e1d3f851b2ea9529cb5696337202703c2e1ed2321",
        "linux_arm": "06e8436bde78d53ddb5095ba146fe6c7001297c7dceb9ef6b68992c3ecfde770",
        "linux_i386": "7d1307e708d4eb043686c8635df567773221397d5d0151d37000b7c472170b3a",
        "darwin_amd64": "977c2faa49993aa8baa2c727f8f35a357576d6278d4d8618a5a010a56ad2dbee",
        "darwin_arm64": "00f00c66165ba0dcd9efdbef66a5508fb4fe4425991c0e599e0710f8ff7aa02e",
        "windows_amd64": "1ef931cb40bfa049fa5ee337ec16181345d7d0c8ab863fe9b04abe320fa2ae6e",
    },
    "v3.13.1": {
        "linux_amd64": "98c363564d00afd0cc3088e8f830f2a0eeb5f28755b3d8c48df89866374a1ed0",
        "linux_arm64": "8c4a0777218b266a7b977394aaf0e9cef30ed2df6e742d683e523d75508d6efe",
        "linux_arm": "a9c188c1a79d2eb1721aece7c4e7cfcd56fa76d1e37bd7c9c05d3969bb0499b4",
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
            "@platforms//cpu:aarch32",
        ],
    ),
    "linux_i386": struct(
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
    "windows_arm64": struct(
        compatible_with = [
            "@platforms//os:windows",
            "@platforms//cpu:aarch64",
        ],
    ),
}

HelmToolchainInfo = provider(
    doc = "Helm toolchain",
    fields = {
        "bin": "Helm executable binary",
    },
)

def _helm_toolchain_impl(ctx):
    files = ctx.attr.bin.files.to_list()

    binary = files[0]

    template_variables = platform_common.TemplateVariableInfo({
        "HELM_BIN": binary.path,
    })
    default_info = DefaultInfo(
        files = depset([binary]),
        runfiles = ctx.runfiles(files = [binary]),
    )
    helm_info = HelmToolchainInfo(
        bin = binary,
    )

    toolchain_info = platform_common.ToolchainInfo(
        default = default_info,
        template_variables = template_variables,
        helminfo = helm_info,
    )

    return [
        default_info,
        toolchain_info,
        template_variables
    ]

helm_toolchain = rule(
    implementation = _helm_toolchain_impl,
    attrs = {
        "bin": attr.label(mandatory = True, allow_single_file = True),
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
        stripPrefix = processed_platform,
    )

    build_content = """
load("@masorange_rules_helm//helm/private:helm_toolchain.bzl", "helm_toolchain")

exports_files(["{0}"])

helm_toolchain(name = "helm_toolchain", bin = "{0}", visibility = ["//visibility:public"])
""".format("helm.exe" if is_windows else "helm")

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

    # Expose a concrete toolchain which is the result of Bazel resolving the toolchain
    # for the execution or target platform.
    # Workaround for https://github.com/bazelbuild/bazel/issues/14009
    starlark_content = """

# Forward all the providers
def _resolved_toolchain_impl(ctx):
    toolchain_info = ctx.toolchains["@masorange_rules_helm//helm:helm_toolchain_type"]
    return [
        toolchain_info,
        toolchain_info.default,
        toolchain_info.helminfo,
        toolchain_info.template_variables,
    ]

# Copied from java_toolchain_alias
# https://cs.opensource.google/bazel/bazel/+/master:tools/jdk/java_toolchain_alias.bzl
resolved_toolchain = rule(
    implementation = _resolved_toolchain_impl,
    toolchains = ["@masorange_rules_helm//helm:helm_toolchain_type"],
)
"""
    rctx.file("defs.bzl", starlark_content)

    build_content = """
package(default_visibility = ["//visibility:public"])

load(":defs.bzl", "resolved_toolchain")

resolved_toolchain(name = "resolved_toolchain", visibility = ["//visibility:public"])
    """

    for [platform, meta] in HELM_PLATFORMS.items():
        # TODO: make repo name a variable with a default to enable override toolchain versions
        build_content += """
toolchain(
    name = "{platform}_toolchain",
    exec_compatible_with = {compatible_with},
    toolchain = "@helm_{platform}//:helm_toolchain",
    toolchain_type = "@masorange_rules_helm//helm:helm_toolchain_type",
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
