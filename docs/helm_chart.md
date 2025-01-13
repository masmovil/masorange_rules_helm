<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Rules for manipulating helm charts. To load these rules:

```starlark
load("//helm:defs.bzl", "helm_chart", ...)
```

<a id="chart_srcs"></a>

## chart_srcs

<pre>
chart_srcs(<a href="#chart_srcs-name">name</a>, <a href="#chart_srcs-deps">deps</a>, <a href="#chart_srcs-srcs">srcs</a>, <a href="#chart_srcs-additional_templates">additional_templates</a>, <a href="#chart_srcs-api_version">api_version</a>, <a href="#chart_srcs-app_version">app_version</a>, <a href="#chart_srcs-chart_deps">chart_deps</a>, <a href="#chart_srcs-chart_name">chart_name</a>,
           <a href="#chart_srcs-deps_conditions">deps_conditions</a>, <a href="#chart_srcs-description">description</a>, <a href="#chart_srcs-force_repository_append">force_repository_append</a>, <a href="#chart_srcs-helm_chart_version">helm_chart_version</a>, <a href="#chart_srcs-image">image</a>,
           <a href="#chart_srcs-image_digest">image_digest</a>, <a href="#chart_srcs-image_repository">image_repository</a>, <a href="#chart_srcs-image_tag">image_tag</a>, <a href="#chart_srcs-package_name">package_name</a>, <a href="#chart_srcs-path_to_chart">path_to_chart</a>, <a href="#chart_srcs-stamp">stamp</a>, <a href="#chart_srcs-templates">templates</a>,
           <a href="#chart_srcs-values">values</a>, <a href="#chart_srcs-values_repo_yaml_path">values_repo_yaml_path</a>, <a href="#chart_srcs-values_tag_yaml_path">values_tag_yaml_path</a>, <a href="#chart_srcs-version">version</a>)
</pre>

Customize helm chart values and configuration.

This rule should not be used directly, users should use `helm_chart` macro instead. See [helm_chart](#helm_chart).
Despite, if you want to see the configuration arguments you can use to package a helm chart using `helm_chart` rule, check the arguments doc below for `chart_srcs` rule,
as `helm_chart` is just a wrapper around `chart_srcs` rule and all the arguments are propagated to `chart_srcs` rule.


This rule takes chart src files and write them to bazel output dir applying some modifications.
The rule is designed to be used with a packager to produce an archived file (`pkg_tar` is used).

```starlark
chart_srcs(
    name = "basic_chart",
    chart_name = "example",
    srcs = glob(["**"]),
)
```

You can customize the values of the chart overriding them via `values` rule attribute:

```starlark
chart_srcs(
    name = "basic_chart",
    chart_name = "example",
    srcs = glob(["**"]),
    values = {
        "override.value": "valueoverrided",
    }
)
```

Chart src files are not mandatory, you can specify all the chart configuration via rule attributes.
In this case the rule will take care of generating the chart files for you (Chart.yaml, values.yaml, template files, chart deps...).

```starlark
chart_srcs(
    name = "chart",
    chart_name = "example",
    version = "v1.0.0",
    app_version = "v2.3.4",
    api_version = "v2",
    description = "Helm chart description placed inside Chart.yaml",
    image = ":oci_image",
    values = {
        "yaml.path.to.value": "value",
    },
)
```

Stamp variables are supported in values attribute. To enable the use of stamp variables enable them via stamp attribute and --stamp flag in bazel.
You can customize stamped variables using bazel workspace status. See [the Bazel workspace status docs](https://docs.bazel.build/versions/master/user-manual.html#workspace_status)

All values with ${} format will be replaced by stamped variables (both volatile and stable are supported).

```starlark
chart_srcs(
    name = "chart",
    chart_name = "example",
    srcs = glob(["**"]),
    stamp = -1,
    values = {
        "stamped.value": "${STAMPED_VARIABLE}",
    },
)
```

For compatibility reasons, some attributes are still supported but marked as deprecated. Its use is discouraged.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="chart_srcs-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="chart_srcs-deps"></a>deps |  A list of helm chart that this helm chart depends on. They will be placed inside the `charts` directory. The dependencies will be traced inside the Chart.yaml manifest as well.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="chart_srcs-srcs"></a>srcs |  A list of helm chart source files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="chart_srcs-additional_templates"></a>additional_templates |  [Deprecated] Use templates instead.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="chart_srcs-api_version"></a>api_version |  Helm chart manifest apiVersion. The value is replaced in the output Chart.yaml manifest.   | String | optional |  `""`  |
| <a id="chart_srcs-app_version"></a>app_version |  Helm chart manifest appVersion. The value is replaced in the output Chart.yaml manifest.   | String | optional |  `""`  |
| <a id="chart_srcs-chart_deps"></a>chart_deps |  [Deprecated] Chart dependencies. Use deps attribute instead.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="chart_srcs-chart_name"></a>chart_name |  Name of the chart. It will be modified in the name field of the Chart.yaml   | String | required |  |
| <a id="chart_srcs-deps_conditions"></a>deps_conditions |  A dictionary containing the conditions that the dependencies of the chart should met to be rendered by helm. The key has to be the name of the dependency chart. The value will be the condition that the values of the chart should have. Check helm doc for more info https://helm.sh/docs/topics/charts/#the-chartyaml-file   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | optional |  `{}`  |
| <a id="chart_srcs-description"></a>description |  Helm chart manifest description. The value is replaced in the output Chart.yaml manifest.   | String | optional |  `""`  |
| <a id="chart_srcs-force_repository_append"></a>force_repository_append |  A flag to specify if @ should be appended to the repository value in the chart values.yaml (in case `image` rule attribute is specified). The rules will look for the specified repository value inside the values.yaml. This is intended to meet image url with digest format: `gcr.io/container@sha256:a12e258c58ab92be22e403d08c8ef7eefd6119235eddca01309fe6b21101e100`. If you have this already covered in your deployment templates, set this attr to false. If the flag is set to true, the image rule attr is provided and no `values_repo_yaml_path` is set, the rule will look for the default path of the repository value. .image.repository   | Boolean | optional |  `True`  |
| <a id="chart_srcs-helm_chart_version"></a>helm_chart_version |  [Deprecated] Helm chart version. Use version instead.   | String | optional |  `""`  |
| <a id="chart_srcs-image"></a>image |  Reference to image rule use to interpolate the image sha256 in the chart values.yaml. If provided, the sha256 of the image will be placed in the output values.yaml of the chart in the yaml path provided by `values_tag_yaml_path` attribute. Only oci_image rules are supported.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="chart_srcs-image_digest"></a>image_digest |  Reference to oci_image digest file. Used internally by the macro (do not use it).   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="chart_srcs-image_repository"></a>image_repository |  [Deprecated] You can use values attr dict to modify repository values.   | String | optional |  `""`  |
| <a id="chart_srcs-image_tag"></a>image_tag |  [Deprecated] Use image attribute instead.   | String | optional |  `""`  |
| <a id="chart_srcs-package_name"></a>package_name |  [Deprecated] Helm chart name. Use chart_name instead.   | String | optional |  `""`  |
| <a id="chart_srcs-path_to_chart"></a>path_to_chart |  Attribute to specify the path to the root of the chart. This attribute is mandatory if neither Chart.yaml nor values.yaml are provided, and the chart srcs attr is not empty to determinate where in the path of the source files is located the root of the helm chart.   | String | optional |  `""`  |
| <a id="chart_srcs-stamp"></a>stamp |  Whether to encode build information into the output. Possible values:<br><br>- `stamp = 1`: Always stamp the build information into the output, even in     [--nostamp](https://docs.bazel.build/versions/main/user-manual.html#flag--stamp) builds.     This setting should be avoided, since it is non-deterministic.     It potentially causes remote cache misses for the target and     any downstream actions that depend on the result. - `stamp = 0`: Never stamp, instead replace build information by constant values.     This gives good build result caching. - `stamp = -1`: Embedding of build information is controlled by the     [--[no]stamp](https://docs.bazel.build/versions/main/user-manual.html#flag--stamp) flag.     Stamped targets are not rebuilt unless their dependencies change.   | Integer | optional |  `-1`  |
| <a id="chart_srcs-templates"></a>templates |  A list of files that will be added to the chart. They will be added as addition to the chart templates refernced in the `srcs` attribute.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="chart_srcs-values"></a>values |  A dictionary of key values to be written in to the chart values. keys: `yaml.path` or `.yaml.path` values:  the value to be replaced inside the Chart values.yaml. This attr supports use of stamped values. To provide a stamped value you have to use ${STAMP_VARIABLE_NAME} as value of the dict with your stamped variable key. Make sure to enable stamping in your rule with the attribute `stamp`.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | optional |  `{}`  |
| <a id="chart_srcs-values_repo_yaml_path"></a>values_repo_yaml_path |  [Deprecated] Yaml path used to set the repo config provided by `image_repository` attribute (deprecated). .image.repository   | String | optional |  `""`  |
| <a id="chart_srcs-values_tag_yaml_path"></a>values_tag_yaml_path |  Yaml path used to set the image sha256 inside the chart values.yaml.   | String | optional |  `".image.tag"`  |
| <a id="chart_srcs-version"></a>version |  Helm chart version to be placed in Chart.yaml manifest   | String | optional |  `""`  |


<a id="ChartInfo"></a>

## ChartInfo

<pre>
ChartInfo(<a href="#ChartInfo-targz">targz</a>, <a href="#ChartInfo-chart_name">chart_name</a>, <a href="#ChartInfo-chart_version">chart_version</a>, <a href="#ChartInfo-chart_srcs">chart_srcs</a>)
</pre>

`helm_chart` expose ChartInfo providers to be able to access info about a packaged chart. The info available is:
- The name of the chart
- The version of the chart
- The ouput sources of the chart
- The output archive file targz

**FIELDS**


| Name  | Description |
| :------------- | :------------- |
| <a id="ChartInfo-targz"></a>targz |  The output of helm_chart. This is the versioned packaged targz of the chart    |
| <a id="ChartInfo-chart_name"></a>chart_name |  The name of the chart as is reflected in the Chart.yaml manifest and provided by the rule attribute    |
| <a id="ChartInfo-chart_version"></a>chart_version |  If provided, the version of the chart    |
| <a id="ChartInfo-chart_srcs"></a>chart_srcs |  The sources of the chart before beign packaged into the archived targz    |


<a id="helm_chart"></a>

## helm_chart

<pre>
helm_chart(<a href="#helm_chart-name">name</a>, <a href="#helm_chart-chart_name">chart_name</a>, <a href="#helm_chart-kwargs">kwargs</a>)
</pre>

Bazel macro function to package a helm chart in to a targz archive file.

The macro is intended to be used as the public API for packaging a chart. It is a wrapper around `chart_srcs` rule. All the args are propagated to `chart_srcs` rule.
See [chart_srcs](#chart_srcs) arguments to see the available config.


To load the rule use:
```starlark
load("//helm:defs.bzl", "helm_chart")
```

It also defines a %name%_lint test target to be able to test that your chart is well-formed (using `helm lint`).

To make the output reproducible this macro does not use `helm package` to package the chart into a versioned chart archive file.
It uses `pkg_tar` bazel rule instead to create the archive file. Check this to find more info about it:
- https://github.com/masmovil/bazel-rules/issues/55
- https://github.com/helm/helm/issues/3612#issuecomment-525340295

This macro exports some providers to share info about charts between rules. Check [helm_chart providers](#providers).

The args are the same that the `chart_srcs` rule, check [chart_srcs](#chart_srcs).

```starlark
load("//helm:defs.bzl", "helm_chart")

helm_chart(
    name = "basic_chart",
    chart_name = "example",
    srcs = glob(["**"]),
)

helm_chart(
    name = "basic_chart",
    chart_name = "example",
    srcs = glob(["**"]),
    values = {
        "override.value": "valueoverrided",
    }
)

helm_chart(
    name = "chart",
    chart_name = "example",
    version = "v1.0.0",
    app_version = "v2.3.4",
    api_version = "v2",
    description = "Helm chart description placed inside Chart.yaml",
    image = ":oci_image",
    values = {
        "yaml.path.to.value": "value",
    },
)
```


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="helm_chart-name"></a>name |  <p align="center"> - </p>   |  none |
| <a id="helm_chart-chart_name"></a>chart_name |  <p align="center"> - </p>   |  none |
| <a id="helm_chart-kwargs"></a>kwargs |  <p align="center"> - </p>   |  none |


