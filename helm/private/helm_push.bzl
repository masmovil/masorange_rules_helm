load(":helm_chart_providers.bzl", "ChartInfo")

_DOC = """
    Publish a helm chart produced by `helm_chart` rule to a remote registry.

    To load the rule use:
    ```starlark
    load("//helm:defs.bzl", "helm_push")
    ```

    This rule builds an executable. Use `run` instead of `build` to publish the chart.
"""

push_attrs = {
    "chart": attr.label(allow_single_file = True, mandatory = True, providers = [ChartInfo], doc = """
        The packaged chart archive to be published. It can be a reference to a `helm_chart` rule or a reference to a helm archived file"""
    ),
    "repository_url": attr.string(mandatory = False, doc = """
        The remote url of the registry. Do not add the chart name to the url. If you provide `repository_config` and a `repository_name` attributes
        this field will be omitted.
    """),
    "repository_name": attr.string(mandatory = False, doc = """The name of the repository from the repository config file provided to this rule.
        You must provide a repository_config in order to use this as the name of the repository. It only works with oci repos by now.
    """),
    "repository_config": attr.label(allow_single_file = True, mandatory = False, doc="""
        The repository config file. Used in conjunction with repository_name. It only works with oci repos by now.
    """),
}

def _curl_fallback(ctx):
    script_template = ctx.actions.declare_file(ctx.attr.name + "_run_curl_script.tpl")

    chart = ctx.file.chart

    inputs = [ctx.file.chart]

    ctx.actions.write(
        output = script_template,
        content = """
EXTRA_ARGS=""

if [ "$HELM_USER" != "" ] && [ "$HELM_PASSWORD" != "" ]; then
    EXTRA_ARGS="-u $VAR_BASIC_USER:$VAR_BASIC_PSWD"
fi

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}\n" --data-binary "@{CHART_PATH}" $EXTRA_ARGS {REMOTE})

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "409" ]; then
    echo "Success - http post response code: "$HTTP_CODE
exit 0
else
    echo "Error - http post response code: "$HTTP_CODE
    exit 1
fi
    """)

    runfile_helm_push_script = ctx.actions.declare_file(ctx.attr.name + "_run_curl_script")

    ctx.actions.expand_template(
        template = script_template,
        output = runfile_helm_push_script,
        is_executable = True,
        substitutions = {
            # We use short_path because it's a runfile
            "{CHART_PATH}": chart.short_path,
            "{REMOTE}": ctx.attr.repository_url,
        },
    )

    runfiles = ctx.runfiles(files = inputs)

    return [DefaultInfo(
      executable = runfile_helm_push_script,
      runfiles = runfiles,
    )]


def _helm_push_impl(ctx):
    chart_name = ctx.attr.chart[ChartInfo].chart_name
    chart = ctx.file.chart

    repo_name = ctx.attr.repository_name
    repo_config = ctx.attr.repository_config
    repo_url = repo_name if repo_name and repo_config else ctx.attr.repository_url

    if not repo_url and not repo_name:
        fail("You must provide a repository_url or a repository_name attribute")

    if repo_name and not repo_config:
        if not repo_url:
            fail("You must provide a repository_config to be able to use repository_name attr for pushing the chart")
        else:
            print("You should provide a repository_config to be able to use repository_name attr for pushing the chart")

    is_repo_from_conf = True if repo_name and repo_config else False
    is_oci = True if repo_url.startswith("oci://") else False
    repo_config_path = ctx.file.repository_config.short_path if is_repo_from_conf else ""

    if not is_oci:
        return _curl_fallback(ctx)

    helm_bin = ctx.toolchains["@masorange_rules_helm//helm:helm_toolchain_type"].helminfo.bin

    script_template = ctx.actions.declare_file(ctx.attr.name + "_run_oci_script.tpl")

    ctx.actions.write(
        output = script_template,
        content = """
EXTRA_ARGS=""

if [ "{REPO_CONFIG_PATH}" != "" ]; then
    EXTRA_ARGS="--repository-config {REPO_CONFIG_PATH}"
fi

{HELM_BINARY} push {CHART_PATH} {REMOTE}
    """)

    runfile_helm_push_script = ctx.actions.declare_file(ctx.attr.name + "_run_oci_script")

    inputs = [helm_bin, chart]

    ctx.actions.expand_template(
        template = script_template,
        output = runfile_helm_push_script,
        is_executable = True,
        substitutions = {
            # We use short_path because it's a runfile
            "{CHART_PATH}": chart.short_path,
            "{CHART_NAME}": chart_name,
            "{HELM_BINARY}": helm_bin.short_path,
            "{REMOTE}": repo_url,
            "{REPO_CONFIG_PATH}": repo_config_path
        },
    )

    runfiles = ctx.runfiles(files = inputs)

    return [DefaultInfo(
      executable = runfile_helm_push_script,
      runfiles = runfiles,
    )]

helm_push = rule(
    implementation = _helm_push_impl,
    attrs = push_attrs,
    doc = _DOC,
    toolchains = [
        "@masorange_rules_helm//helm:helm_toolchain_type",
    ],
    executable = True,
)
