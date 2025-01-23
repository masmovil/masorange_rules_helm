GCLOUD_DEFAULT_VERSION = "502.0.0"

GCLOUD_VERSIONS = {
    "502.0.0": {
        "linux-x86_64": "b40e9fe64c3d2b0c7ff289b50ca39f572cce54c783c0f8579810f2307c8fdf0b",
        "linux-arm": "9a7315d287347d77f45e399ac13b51e6fcde8a1120d14faa7cd47e7ee959a6e6",
        "linux-x86": "cad9ef0f5072a967ff6eb495b7fffb550ee63455fde9231e6155b471fd583d98",
        "darwin-x86_64": "8af3013b524591ef5347a3df48caa9d4b1a3510c50c1d45b64442a365c021f65",
        "darwin-x86": "0c652a53cc577e9157e4ae48ead5d28645dc81901b5db3940c79171a401986c6",
        "darwin-arm": "40a14db24af99154b6b42aeb114f2828711d3209b72e7a583ad3ca0b4c669f87",
        "windows-x86": "19fd1d359d4efd0824f89e568b08d58d734d78c1bee66f34b0e29dd9c43b1ce2",
        "windows-x86_64": "82270ab11e486c50e552a8ec4e4152a234ddd97d23d062deb85d5d91faa8e5e7"
    },
    "473.0.0": {
        "linux-x86_64": "e15da3e41f24c072a3e8359dffca08d5ab7ee03f94e2e8711bbfbaf1cc3456f8",
        "linux-arm": "c16fa95ea22b27a887aafa9d86e439794b6c80b0f97a1210bf8b7c57afb03c27",
        "linux-x86": "85ef8a1303bbc2e919bfc3fb2fe2ea758a196435b935f88a297d6b1cb42ae570",
        "darwin-x86_64": "9ddd90144a004d9ff630781e9b8f144c21b2cea8fb45038073b7fb82399ed478",
        "darwin-x86": "7c15cd239528437f7f8f1718709c653c03edf2ff53907c4e834c5eeab7a3a55e",
        "darwin-arm": "4b534bf60585b6f6918daf0feeb0b68b39a689a794404e5a4f8fd8ce844de31c",
        "windows-x86": "e8166b3755f01ced1e8e7b5c289743eecc0cf89b4c2481ca48008d5f78bf404f",
        "windows-x86_64": "9eacd3f507d3e9fd7a9ed4b8651056be18124ee22369ffcea9f5a3646e0a70a2"
    },
    "450.0.0": {
        "linux-x86_64": "7a51d06c3edfcda8901983736f402c1024a058fa83790cd5d74a0c88c7ca6e24",
        "linux-arm": "c8ab1e46605ec3b457cf7c2b46ce3a22fce26f420743ec82dd81c8fbc85857a3",
        "linux-x86": "9a6c190a25c6f27e156e52d605e6caa64c67e18d39d903b49fa1536e1ccade08",
        "darwin-x86_64": "fe25b8b77a4f734fd5d00f5ef59adc077cec0818c1a168b068457034b2ede295",
        "darwin-x86": "544acdadd2dbf690a08b058f18d0d00eff2efafda8a3d5ff1f55f25da1bbc4f1",
        "darwin-arm": "3796e974808e321ac107593b15fe8c80f59a0a39dffbf5380ce1722a281e6049",
        "windows-x86": "8b52bbfa97fd83da8a489e3a720d58ce5ab11e5e60244a8fb5c9f8fc0b61be7f",
        "windows-x86_64": "2589b411cc9ccdc371e437149bcbfad4281f14153fd00dccfcd5ca9f6d334379"
    }
}

GCLOUD_PLATFORMS = {
    "darwin-x86": struct(
        compatible_with = [
            "@platforms//os:macos",
            "@platforms//cpu:x86_32",
        ],
    ),
    "darwin-x86_64": struct(
        compatible_with = [
            "@platforms//os:macos",
            "@platforms//cpu:x86_64",
        ],
    ),
    "darwin-arm": struct(
        compatible_with = [
            "@platforms//os:macos",
            "@platforms//cpu:aarch64",
        ],
    ),
    "linux-arm": struct(
        compatible_with = [
            "@platforms//os:linux",
            "@platforms//cpu:aarch64",
        ],
    ),
    "linux-x86": struct(
        compatible_with = [
            "@platforms//os:linux",
            "@platforms//cpu:x86_32",
        ],
    ),
    "linux-x86_64": struct(
        compatible_with = [
            "@platforms//os:linux",
            "@platforms//cpu:x86_64",
        ],
    ),
    "windows-x86": struct(
        compatible_with = [
            "@platforms//os:windows",
            "@platforms//cpu:x86_32",
        ],
    ),
    "windows-x86_64": struct(
        compatible_with = [
            "@platforms//os:windows",
            "@platforms//cpu:x86_64",
        ],
    ),
}

GcloudInfo = provider(
  doc = "Helm info",
  fields = {
    "gcloud_bin": "Gcloud executable binary",
    "gsutil_bin": "Gsutil executable binary",
    "gcloud_files": "Gcloud files",
  },
)

def _gcloud_toolchain_impl(ctx):
  gcloud=ctx.file.gcloud_bin
  gcloud_files_var=ctx.file.gcloud_files
  gsutil=ctx.file.gsutil_bin

  template_variables = platform_common.TemplateVariableInfo({
    "GCLOUD_BIN": gcloud.path,
    "GCLOUD_FILES": gcloud_files_var.path,
    "GSUTIL_BIN": gsutil.path,
  })
  default_info = DefaultInfo(
    files = depset([gcloud, gsutil]),
    runfiles = ctx.runfiles(files = [gcloud, gsutil]),
  )
  gcloudinfo = GcloudInfo(
    gcloud_bin = gcloud,
    gcloud_files = gcloud_files_var,
    gsutil_bin = gsutil,
  )

  toolchain_info = platform_common.ToolchainInfo(
    default = default_info,
    template_variables = template_variables,
    gcloudinfo = gcloudinfo,
  )

  return [toolchain_info]

gcloud_toolchain = rule(
  implementation = _gcloud_toolchain_impl,
  attrs = {
    "gcloud_bin": attr.label(allow_single_file = True, mandatory = True),
    "gsutil_bin": attr.label(allow_single_file = True, mandatory = True),
    "gcloud_files": attr.label(allow_single_file = True, mandatory = True),
  },
)

def _gcloud_repo_impl(rctx):
    version = rctx.attr.version
    platform = rctx.attr.platform
    sha = rctx.attr.sha

    url = "https://storage.googleapis.com/cloud-sdk-release/google-cloud-cli-{version}-{platform}.tar.gz".format(
        version=version,
        platform=platform,
    )

    rctx.report_progress("Downloading gcloud-sdk %s" % url)

    rctx.download_and_extract(
        url = url,
        sha256 = sha,
        stripPrefix = "google-cloud-sdk",
    )

    build_content = """
load("@masorange_rules_helm//gcs/private:gcloud_toolchain.bzl", "gcloud_toolchain")

exports_files(["bin/gcloud", "bin/gsutil", "lib/gcloud.py"])

gcloud_toolchain(name = "gcloud_toolchain", gcloud_bin = "bin/gcloud", gsutil_bin = "bin/gsutil", gcloud_files = ".", visibility = ["//visibility:public"])
"""

    # Base BUILD file for this repository
    rctx.file("BUILD.bazel", build_content)

gcloud_repo = repository_rule(
    implementation = _gcloud_repo_impl,
    doc = "Fetch external gcloud binaries",
    attrs = {
        "version": attr.string(mandatory = True, values = GCLOUD_VERSIONS.keys()),
        "platform": attr.string(mandatory = True,),
        "sha": attr.string(mandatory = True),
    },
)

def _gcloud_toolchain_configure_impl(rctx):

    # Expose a concrete toolchain which is the result of Bazel resolving the toolchain
    # for the execution or target platform.
    # Workaround for https://github.com/bazelbuild/bazel/issues/14009
    starlark_content = """

# Forward all the providers
def _resolved_toolchain_impl(ctx):
    toolchain_info = ctx.toolchains["@masorange_rules_helm//gcs:gcloud_toolchain_type"]
    return [
        toolchain_info,
        toolchain_info.default,
        toolchain_info.gcloudinfo,
        toolchain_info.template_variables,
    ]

# Copied from java_toolchain_alias
# https://cs.opensource.google/bazel/bazel/+/master:tools/jdk/java_toolchain_alias.bzl
resolved_toolchain = rule(
    implementation = _resolved_toolchain_impl,
    toolchains = ["@masorange_rules_helm//gcs:gcloud_toolchain_type"],
    incompatible_use_toolchain_transition = True,
)
"""
    rctx.file("defs.bzl", starlark_content)

    build_content = """
package(default_visibility = ["//visibility:public"])

load(":defs.bzl", "resolved_toolchain")

resolved_toolchain(name = "resolved_toolchain", visibility = ["//visibility:public"])
    """

    for [platform, meta] in GCLOUD_PLATFORMS.items():
        # TODO: make repo name a variable with a default to enable override toolchain versions
        build_content += """
toolchain(
    name = "{platform}_toolchain",
    exec_compatible_with = {compatible_with},
    toolchain = "@gcloud_{platform}//:gcloud_toolchain",
    toolchain_type = "@masorange_rules_helm//gcs:gcloud_toolchain_type",
)
""".format(
            platform = platform,
            compatible_with = meta.compatible_with,
            # user_repository_name = rctx.attr.user_repository_name,
        )

    rctx.file("BUILD.bazel", build_content)


gcloud_toolchain_configure = repository_rule(
    implementation = _gcloud_toolchain_configure_impl,
    doc = """Creates a repository with toolchain definitions for all known platforms
     which can be registered or selected.""",
    attrs = {},
)
