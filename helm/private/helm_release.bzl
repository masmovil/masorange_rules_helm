load("//k8s:k8s.bzl", "NamespaceDataInfo")

_DOC = """
  Installs or upgrades a helm release of a chart in to a cluster using helm binary.

  To load the rule use:
  ```starlark
  load("//helm:defs.bzl", "helm_release")
  ```

  This rule builds an executable. Use `run` instead of `build` to execute it.

  ```starklark
helm_release(
    name = "install",
    remote_chart = "oci://docker.pkg.dev/helm-charts/test_helm_chart",
    version = "0.7.5",
    namespace = "myapp",
    release_name = "helm-release-name",
    values = ["additional_values.yaml"],
)

helm_release(
    name = "install",
    chart = ":chart",
    namespace = "myapp",
    release_name = "helm-release-name",
    values = glob(["charts/myapp/values.yaml"]),
)
```

Example of use providing a kubernetes context config:
```starklark
helm_release(
    name = "chart_install",
    chart = ":chart",
    release_name = "release-name",
    values = glob(["charts/myapp/values.yaml"]),
    kubernetes_context = "mm-k8s-context",
)
```

Example of use decryptying sops secrets:
```starklark

sops_decrypt(
  name = "secret",
  srcs = ["secrets.yaml"],
)

helm_release(
    name = "chart_install",
    chart = ":chart",
    release_name = "release-name",
    values = glob(["charts/myapp/values.yaml"]) + [":secret"],
)
```

Example of use with k8s_namespace annotated with a GCP SA:
```starklark
k8s_namespace(
  name = "test-namespace",
  namespace_name = "test-namespace",
  kubernetes_sa = "test-kubernetes-sa",
  kubernetes_context = "mm-k8s-context",
)

helm_release(
    name = "chart_install",
    chart = ":chart",
    namespace_dep = ":test-namespace",
    release_name = "release-name",
    values = glob(["charts/myapp/values.yaml"]),
)
```

"""

_ATTRS = {
  "remote_chart": attr.string(mandatory = False, doc = "Helm registry url of the chart to be installed. If `chart` attribute is also providedd, `remote_chart` has preference."),
  "chart": attr.label(allow_single_file = True, mandatory = False, doc = """
    The packaged chart archive to be published. It can be a reference to a `helm_chart` rule or a reference to a helm archived file. To specify a helm chart from a remote repository use `remote_chart` instead."""
  ),
  "version": attr.string(mandatory = False, doc = "Chart version to be installed in a kubernetes cluster. This option will only be used if the `remote_chart` attribute is used."),
  "namespace": attr.string(mandatory = False, doc = "The namespace literal where to install the helm release. Set to `\"\"` to use namespace from current kube context"),
  "namespace_dep": attr.label(mandatory = False, doc = "A reference to a `k8s_namespace` rule from where to extract the namespace to be used to install the release.Namespace where this release is installed to. Must be a label to a k8s_namespace rule. It takes precedence over namespace"),
  "values": attr.label_list(allow_files = True, default = [], doc = "A list of value files to be provided to helm install command through -f flag."),
  "release_name": attr.string(mandatory = True, doc = "The name of the helm release to be installed or upgraded."),
  "kubernetes_context": attr.string(mandatory = False, doc = "The name of the kubeconfig context to use"),
  "create_namespace": attr.bool(default = True, doc = "A flag to indicate helm binary to create the kubernetes namespace if it is not already present in the cluster."),
  "wait": attr.bool(default = True, doc = "Helm flag to wait for all resources to be created to exit."),
  "set": attr.string_dict(doc = """
    A dictionary of key value pairs consisting on yaml paths and values to be replaced in the chart via --set helm option before installing it:
    "yaml.path": "value"
  """, default = {}),
  # deprecated
  "values_yaml": attr.label_list(allow_files = True, mandatory = False, doc = "[Deprecated] Use `values` attr instead"),
}

def _helm_release_impl(ctx):
    files = []

    print("helm_info {}", ctx.toolchains["@masorange_rules_helm//helm:helm_toolchain_type"].helminfo.bin)
    helm_bin = ctx.toolchains["@masorange_rules_helm//helm:helm_toolchain_type"].helminfo.bin

    namespace = ctx.attr.namespace_dep[NamespaceDataInfo].namespace if ctx.attr.namespace_dep else ctx.attr.namespace

    args = ["upgrade", ctx.attr.release_name]

    if not ctx.attr.remote_chart and ctx.attr.chart:
      files += [ctx.file.chart]
      args.append(ctx.file.chart.short_path)

    args.append('--install')

    if ctx.attr.remote_chart:
      if not ctx.attr.version:
        print("WARN: No chart version has been provided via `version` attribute. The latest chart published to the registry will be used.")

      args += ["--version", ctx.attr.version]

    if namespace:
      args += ["--namespace", namespace]

    if ctx.attr.create_namespace:
      args.append("--create-namespace")

    if ctx.attr.kubernetes_context:
      args += ["--kube-context", ctx.attr.kubernetes_context]

    if ctx.attr.wait:
      args.append("--wait")

    if not ctx.attr.chart and not ctx.attr.remote_chart:
      fail("You must provide a valid reference to a helm chart in order to install one. Use `chart` or `remote_chart` to do it.")

    if ctx.attr.chart and ctx.attr.remote_chart:
      print("WARN: You have provide both `remote_chart` and `chart` attributes, only `remote_chart` will be used.")

    for values in ctx.files.values:
      args += ["-f", values.short_path]

    if ctx.attr.values_yaml:
      print("WARN: values_yaml attr is marked as DEPRECATED in helm_release bazel rule. Use `values` attr instead")

      for values in ctx.files.values_yaml:
        args += ["-f", values.short_path]

    for key, value in ctx.attr.set.items():
      args += ["--set", key + '=' + value]

    exec_file = ctx.actions.declare_file(ctx.label.name + "_helm_release.sh")

    ctx.actions.write(
        output = exec_file,
        content = """
          {helm} {args}
        """.format(helm=helm_bin.short_path, args=" ".join(args)),
        is_executable = True
    )

    runfiles = ctx.runfiles(
        files = files + [
            helm_bin,
            ctx.info_file,
            ctx.version_file,
        ] + ctx.files.values_yaml + ctx.files.values
    )

    return [DefaultInfo(
      executable = exec_file,
      runfiles = runfiles,
    )]

helm_release = rule(
    implementation = _helm_release_impl,
    attrs = _ATTRS,
    doc = _DOC,
    toolchains = [
        "@masorange_rules_helm//helm:helm_toolchain_type",
    ],
    executable = True,
)
