<!-- Generated with Stardoc: http://skydoc.bazel.build -->



<a id="k8s_namespace"></a>

## k8s_namespace

<pre>
k8s_namespace(<a href="#k8s_namespace-name">name</a>, <a href="#k8s_namespace-gcp_gke_project">gcp_gke_project</a>, <a href="#k8s_namespace-gcp_sa">gcp_sa</a>, <a href="#k8s_namespace-gcp_sa_project">gcp_sa_project</a>, <a href="#k8s_namespace-kubernetes_context">kubernetes_context</a>, <a href="#k8s_namespace-kubernetes_sa">kubernetes_sa</a>,
              <a href="#k8s_namespace-namespace_name">namespace_name</a>, <a href="#k8s_namespace-workload_identity_namespace">workload_identity_namespace</a>)
</pre>

Create a kubernetes namespace in a kubernetes cluster with workload identity support. You can also configure GKE Workload Identity with it.

  To load the rule use:
  ```starlark
  load("//k8s:defs.bzl", "k8s_namespace")
  ```

  You can annotate the kubernetes namespace with a kubernetes service account, and bind the service account with
  gcp workload identity.

  This rule uses kubectl client to create and annotate the kubernetes namespace and gcloud sdk to create the bindings
  between the kubernetes service account and the gcp workload identity user.

  This rule builds an executable. Use `run` instead of `build` to be create the namespace.

  ```starlark
  load("//k8s:defs.bzl", "k8s_namespace")

  k8s_namespace(
      name = "namespace",
      namespace_name = "ft-sesame-${DEPLOY_BRANCH}",
      kubernetes_sa = "default",
      gcp_sa_project = "mm-odissey-dev",
      gcp_sa = "odissey-dev@mm-odissey-dev.iam.gserviceaccount.com",
      gcp_gke_project = "mm-k8s-dev-01",
      workload_identity_namespace = "mm-k8s-dev-01.svc.id.goog",
      kubernetes_context = "mm-k8s-context",
  )
  ```

You can use `k8s_namespace` in combination with `helm_release` trough `napesmace_dep` attribute.

Example of use with `helm_release`:

```starlark
  load("//k8s:defs.bzl", "k8s_namespace")

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
      tiller_namespace = "tiller-system",
      release_name = "release-name",
      values_yaml = glob(["charts/myapp/values.yaml"]),
      kubernetes_context = "mm-k8s-context",
  )
```

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="k8s_namespace-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="k8s_namespace-gcp_gke_project"></a>gcp_gke_project |  -   | String | optional |  `""`  |
| <a id="k8s_namespace-gcp_sa"></a>gcp_sa |  GCP Service Account in e-mail format.   | String | optional |  `""`  |
| <a id="k8s_namespace-gcp_sa_project"></a>gcp_sa_project |  CP project name where Service Account lives.   | String | optional |  `""`  |
| <a id="k8s_namespace-kubernetes_context"></a>kubernetes_context |   The name of the kubeconfig context to use.    | String | optional |  `""`  |
| <a id="k8s_namespace-kubernetes_sa"></a>kubernetes_sa |  Kubernetes Service Account to associate with Workload Identity.   | String | optional |  `""`  |
| <a id="k8s_namespace-namespace_name"></a>namespace_name |  Name of the namespace to be created.   | String | required |  |
| <a id="k8s_namespace-workload_identity_namespace"></a>workload_identity_namespace |  Workload Identity Namespace e.g clustername.svc.id.goog   | String | optional |  `""`  |


<a id="NamespaceDataInfo"></a>

## NamespaceDataInfo

<pre>
NamespaceDataInfo(<a href="#NamespaceDataInfo-namespace">namespace</a>)
</pre>



**FIELDS**


| Name  | Description |
| :------------- | :------------- |
| <a id="NamespaceDataInfo-namespace"></a>namespace |  (Undocumented)    |


