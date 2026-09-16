<!-- Generated with Stardoc: http://skydoc.bazel.build -->



<a id="helm_pull"></a>

## helm_pull

<pre>
helm_pull(<a href="#helm_pull-name">name</a>, <a href="#helm_pull-chart_name">chart_name</a>, <a href="#helm_pull-repo_mapping">repo_mapping</a>, <a href="#helm_pull-repo_name">repo_name</a>, <a href="#helm_pull-repo_url">repo_url</a>, <a href="#helm_pull-repository_config">repository_config</a>, <a href="#helm_pull-version">version</a>)
</pre>

    Repository rule to download a `helm_chart` from a remote registry.

    To load the rule use:
    ```starlark
    load("//helm:defs.bzl", "helm_pull")
    ```

    It uses `helm` binary to download the chart, so `helm` has to be available in the PATH of the host machine where bazel is running.

    Default credentials on the host machine are used to authenticate against the remote registry.
    To use basic auth you must provide the basic credentials through env variables: `HELM_USER` and `HELM_PASSWORD`.

    OCI registries are supported.

    The downloaded chart is defined using the `helm_chart` rule and it's available as `:chart` target inside the repo name.

    ```starlark
    # With bzlmod, you typically will:
    # MODULE.bazel
    bazel_dep(name = "masorange_rules_helm", version = "1.8.2")

    helm = use_extension("@masorange_rules_helm//:extensions.bzl", "utils")

    helm.pull(
        name = "some_chart",
        chart_name = "chart_name",
        # do not add the chart name to the end of the url
        repo_url = "oci://docker.pkg.dev/helm-charts",
        version = "v1-stable",
    )
    use_repo(helm, "some_chart")
```

In non bzlmod workspaces:
```starlark
    # WORKSPACE
    load("//helm:defs.bzl", "helm_pull")

    helm_pull(
        name = "example_helm_chart",
        chart_name = "example",
        repo_url = "oci://docker.pkg.dev/project/helm-charts",
        version = "1.0.0",
    )
    ```

    It can be later referenced in a BUILD file in `helm_chart` dep:

```starlark
    helm_chart(
        ...
        deps = [
            "@example_helm_chart//:chart",
        ]
    )
    ```

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="helm_pull-name"></a>name |  A unique name for this repository.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="helm_pull-chart_name"></a>chart_name |  The name of the helm_chart to download. It will be appendend at the end of the repository url.   | String | required |  |
| <a id="helm_pull-repo_mapping"></a>repo_mapping |  A dictionary from local repository name to global repository name. This allows controls over workspace dependency resolution for dependencies of this repository.<p>For example, an entry `"@foo": "@bar"` declares that, for any time this repository depends on `@foo` (such as a dependency on `@foo//some:target`, it should actually resolve that dependency within globally-declared `@bar` (`@bar//some:target`).   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | required |  |
| <a id="helm_pull-repo_name"></a>repo_name |  The name of the repository. This is only useful if you provide a `repository_config` file and you want the repo url to be located within the repo config.   | String | optional |  `""`  |
| <a id="helm_pull-repo_url"></a>repo_url |  The url where the chart is located. You have to omit the chart name from the url.   | String | required |  |
| <a id="helm_pull-repository_config"></a>repository_config |  The repository config file.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="helm_pull-version"></a>version |  The version of the chart to download. If no specified, the latest version will be pulled.   | String | optional |  `""`  |


