<!-- Generated with Stardoc: http://skydoc.bazel.build -->



<a id="helm_uninstall"></a>

## helm_uninstall

<pre>
helm_uninstall(<a href="#helm_uninstall-name">name</a>, <a href="#helm_uninstall-kubernetes_context">kubernetes_context</a>, <a href="#helm_uninstall-namespace">namespace</a>, <a href="#helm_uninstall-namespace_dep">namespace_dep</a>, <a href="#helm_uninstall-release_name">release_name</a>, <a href="#helm_uninstall-wait">wait</a>)
</pre>

Uninstall a helm release.

To load the rule use:
```starlark
load("//helm:defs.bzl", "helm_uninstall")
```

This rule builds an executable. Use `run` instead of `build` to be uninstall the helm release.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="helm_uninstall-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="helm_uninstall-kubernetes_context"></a>kubernetes_context |  The name of the kubeconfig context to use.  | String | optional |  `None`  |
| <a id="helm_uninstall-namespace"></a>namespace |  The namespace where the helm release is installed.   | String | optional |  `""`  |
| <a id="helm_uninstall-namespace_dep"></a>namespace_dep |  A reference to a `k8s_namespace` rule from where to extract the namespace where the helm release is installed.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="helm_uninstall-release_name"></a>release_name |  The name of the helm release to be installed or upgraded.   | String | required |  |
| <a id="helm_uninstall-wait"></a>wait |  Helm flag to wait for all resources to be created to exit.   | Boolean | optional |  `True`  |


