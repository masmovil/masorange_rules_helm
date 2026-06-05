SOPS_DEFAULT_VERSION = "v3.8.1"

SOPS_VERSIONS = {
    "v3.8.1": {
        "linux_amd64": "d6bf07fb61972127c9e0d622523124c2d81caf9f7971fb123228961021811697",
        "linux_arm64": "15b8e90ca80dc23125cd2925731035fdef20c749ba259df477d1dd103a06d621",
        "darwin": "41aab990705bab9497fe9ee410aa6d43e04de2054c765015ebe84ef07c2f3704",
        "darwin_amd64": "aa3e79c1ff7a923d380b95b01fb0bc84ae1f5209b0a149b3f4c1936037792330",
        "darwin_arm64": "b5d172960c135c7b8cd9719cee94283bccdf5c046c7563391eee8dd4882d6573",
        "windows_amd64": "fe1f6299294b47ceda565e1091e843ee3f3db58764901d4298eb00558189e25f",
    }
}

SOPS_PLATFORMS = {
    "darwin": struct(
        compatible_with = [
            "@platforms//os:macos"
        ],
    ),
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

SopsToolchainInfo = provider(
    doc = "Sops toolchain",
    fields = {
        "bin": "Sops executable binary"
    }
)

def _sops_toolchain_impl(ctx):
    files = ctx.attr.bin.files.to_list()

    binary = files[0]

    template_variables = platform_common.TemplateVariableInfo({
        "SOPS_BIN": binary.path,
    })
    default_info = DefaultInfo(
        files = depset([binary]),
        runfiles = ctx.runfiles(files = [binary]),
    )
    sopsinfo = SopsToolchainInfo(
        bin = binary,
    )

    toolchain_info = platform_common.ToolchainInfo(
        default = default_info,
        template_variables = template_variables,
        sopsinfo = sopsinfo,
    )

    return [
        default_info,
        toolchain_info,
        template_variables
    ]

sops_toolchain = rule(
    implementation = _sops_toolchain_impl,
    attrs = {
        "bin": attr.label(mandatory = True, allow_single_file = True),
    },
)

def _sops_repo_impl(rctx):
    version = rctx.attr.version
    platform = rctx.attr.platform
    sha = rctx.attr.sha

    processed_platform = platform.replace("_", ".")

    rctx.report_progress("Downloading sops binary sops-{version}-{platform}...".format(
        version=version,
        platform=processed_platform,
    ))

    binary_name = "sops-{version}.{platform}".format(
        version=version,
        platform=processed_platform,
    )

    rctx.download(
        url = "https://github.com/getsops/sops/releases/download/{version}/{bin}".format(
            version=version,
            bin=binary_name,
        ),
        output = binary_name,
        executable = True,
        sha256 = sha,
    )

    build_content = """
load("@masorange_rules_helm//sops/private:sops_toolchain.bzl", "sops_toolchain")

exports_files(["{0}"])

sops_toolchain(name = "sops_toolchain", bin = "{0}", visibility = ["//visibility:public"])
""".format(binary_name)

    # Base BUILD file for this repository
    rctx.file("BUILD.bazel", build_content)

sops_repo = repository_rule(
    implementation = _sops_repo_impl,
    doc = "Fetch external tools needed for sops toolchain",
    attrs = {
        "version": attr.string(mandatory = True, values = SOPS_VERSIONS.keys()),
        "platform": attr.string(mandatory = True,),
        "sha": attr.string(mandatory = True),
    },
)

def _sops_toolchain_configure_impl(rctx):

    # Expose a concrete toolchain which is the result of Bazel resolving the toolchain
    # for the execution or target platform.
    # Workaround for https://github.com/bazelbuild/bazel/issues/14009
    starlark_content = """

# Forward all the providers
def _resolved_toolchain_impl(ctx):
    toolchain_info = ctx.toolchains["@masorange_rules_helm//sops:sops_toolchain_type"]
    return [
        toolchain_info,
        toolchain_info.default,
        toolchain_info.sopsinfo,
        toolchain_info.template_variables,
    ]

# Copied from java_toolchain_alias
# https://cs.opensource.google/bazel/bazel/+/master:tools/jdk/java_toolchain_alias.bzl
resolved_toolchain = rule(
    implementation = _resolved_toolchain_impl,
    toolchains = ["@masorange_rules_helm//sops:sops_toolchain_type"],
)
"""
    rctx.file("defs.bzl", starlark_content)

    build_content = """
package(default_visibility = ["//visibility:public"])

load(":defs.bzl", "resolved_toolchain")

resolved_toolchain(name = "resolved_toolchain", visibility = ["//visibility:public"])
    """

    for [platform, meta] in SOPS_PLATFORMS.items():
        # TODO: make repo name a variable with a default to enable override toolchain versions
        build_content += """
toolchain(
    name = "{platform}_toolchain",
    exec_compatible_with = {compatible_with},
    toolchain = "@sops_{platform}//:sops_toolchain",
    toolchain_type = "@masorange_rules_helm//sops:sops_toolchain_type",
)
""".format(
            platform = platform,
            compatible_with = meta.compatible_with,
            # user_repository_name = rctx.attr.user_repository_name,
        )

    rctx.file("BUILD.bazel", build_content)


sops_toolchain_configure = repository_rule(
    implementation = _sops_toolchain_configure_impl,
    doc = """Creates a repository with toolchain definitions for all known platforms
     which can be registered or selected.""",
    attrs = {},
)
