load("//k8s:k8s.bzl", "NamespaceDataInfo")

_DOC = """
  Uninstall a helm release.

  To load the rule use:
  ```starlark
  load("//helm:defs.bzl", "helm_uninstall")
  ```

  This rule builds an executable. Use `run` instead of `build` to be uninstall the helm release.
"""

_ATTRS = {
  "namespace": attr.string(mandatory = False, doc = "The namespace where the helm release is installed."),
  "namespace_dep": attr.label(mandatory = False, doc = "A reference to a `k8s_namespace` rule from where to extract the namespace where the helm release is installed."),
  "release_name": attr.string(mandatory = True, doc = "The name of the helm release to be installed or upgraded."),
  "kubernetes_context": attr.string(mandatory = False, doc = "The name of the kubeconfig context to use"),
  "wait": attr.bool(default = True, doc = "Helm flag to wait for all resources to be created to exit."),
}
def _helm_uninstall_impl(ctx):
    """Uninstall a helm release.
    Args:
        name: A unique name for this rule.
        namespace: Namespace where the release is installed
        namespace_dep: Namespace from k8s rule
        release_name: Name of the helm release
    """
    helm_bin = ctx.toolchains["@masorange_rules_helm//helm:helm_toolchain_type"].helminfo.bin

    namespace = ctx.attr.namespace_dep[NamespaceDataInfo].namespace if ctx.attr.namespace_dep else ctx.attr.namespace

    args = ['uninstall', ctx.attr.release_name]

    if namespace:
        args += ["--namespace", namespace]

    if ctx.attr.kubernetes_context:
      args += ['--kube-context', ctx.attr.kubernetes_context]

    if ctx.attr.wait:
      args.append('--wait')

    exec_file = ctx.actions.declare_file(ctx.label.name + "_helm_uninstall.sh")

    ctx.actions.write(
        output = exec_file,
        content = """
          {helm} {args}
        """.format(helm=helm_bin.short_path, args=" ".join(args)),
        is_executable = True
    )

    runfiles = ctx.runfiles(
        files = [
            helm_bin,
        ]
    )

    return [DefaultInfo(
      executable = exec_file,
      runfiles = runfiles,
    )]

helm_uninstall = rule(
    implementation = _helm_uninstall_impl,
    attrs = _ATTRS,
    doc = _DOC,
    toolchains = [
        "@masorange_rules_helm//helm:helm_toolchain_type",
    ],
    executable = True,
)
