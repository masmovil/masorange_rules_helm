# masorange_rules_helm

[![CI](https://github.com/masmovil/masorange_rules_helm/actions/workflows/ci-tests.yaml/badge.svg?branch=master)](https://github.com/masmovil/masorange_rules_helm/actions/workflows/ci-tests.yaml)
[![Bazel Central Registry](https://img.shields.io/badge/BCR-masorange__rules__helm-blue)](https://registry.bazel.build/modules/masorange_rules_helm)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue)](LICENSE.txt)

Bazel rules to package, lint, publish and deploy [Helm](https://helm.sh) charts, plus a few companions used around a deployment: decrypting [sops](https://github.com/getsops/sops) secrets, creating Kubernetes namespaces (with GKE Workload Identity) and uploading files to Google Cloud Storage.

Every external tool (`helm`, `sops`, `kubectl`, `gcloud`) is fetched by Bazel as a toolchain, so builds do not depend on what is installed on the host.

## Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Rules](#rules)
- [Toolchains](#toolchains)
- [Stamping values](#stamping-values)
- [Examples](#examples)
- [Development](#development)
- [Releases](#releases)
- [License](#license)

## Requirements

| | |
| --- | --- |
| Bazel | 7.x, 8.x and 9.x (`bazel_compatibility = [">=7.0.0"]`). The test suite runs on Bazel 8.3.1 in CI; the `examples/` module is built against 7.x, 8.x and 9.x by the BCR presubmit. |
| Dependency management | bzlmod (recommended) or a legacy `WORKSPACE`. |
| Host platforms | Linux and macOS, amd64 and arm64 (the toolchains also ship Windows binaries, untested). |
| Container images | `helm_chart` can take the digest of an image built with [rules_oci](https://github.com/bazel-contrib/rules_oci). |

## Installation

Check the [releases page](https://github.com/masmovil/masorange_rules_helm/releases) for the latest version: every release carries a ready-to-paste snippet for both setups.

### bzlmod

```starlark
# MODULE.bazel
bazel_dep(name = "masorange_rules_helm", version = "1.8.2")
```

The module registers the `helm`, `sops`, `kubectl` and `gcloud` toolchains for you. See [Toolchains](#toolchains) to pin different versions.

### WORKSPACE

```starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "masorange_rules_helm",
    sha256 = "<sha256 from the release notes>",
    strip_prefix = "masorange_rules_helm-1.8.2",
    urls = ["https://github.com/masmovil/masorange_rules_helm/releases/download/v1.8.2/masorange_rules_helm-v1.8.2.tar.gz"],
)

load("@masorange_rules_helm//:repositories.bzl", "masorange_rules_helm_repositories")

masorange_rules_helm_repositories()

load("@masorange_rules_helm//:config.bzl", "masorange_rules_helm_configure")

masorange_rules_helm_configure()
```

`masorange_rules_helm_repositories()` fetches the dependencies (`bazel_skylib`, `rules_pkg`, `rules_oci`, `aspect_bazel_lib`) and `masorange_rules_helm_configure()` sets them up and registers the toolchains. `WORKSPACE` support is legacy: Bazel 8 disables it by default and Bazel 9 removes it, so prefer bzlmod.

## Quick start

Package a chart from its sources, stamp the digest of the image it deploys into `values.yaml`, lint it, publish it and install it:

```starlark
load("@masorange_rules_helm//helm:defs.bzl", "helm_chart", "helm_lint_test", "helm_push", "helm_release", "helm_uninstall")
load("@rules_oci//oci:defs.bzl", "oci_image")

oci_image(
    name = "image",
    base = "@distroless_java",
    entrypoint = ["java", "-jar", "/app.jar"],
)

helm_chart(
    name = "chart",
    chart_name = "my-service",
    srcs = glob(["chart/**"]),
    version = "1.4.0",
    app_version = "2.3.1",
    # writes the image digest into .image.tag and appends "@" to .image.repository
    image = ":image",
    values = {
        "replicaCount": "3",
        "ingress.host": "my-service.example.com",
    },
    deps = ["//charts/base:chart"],
)

# bazel test //my-service:lint
helm_lint_test(
    name = "lint",
    chart = ":chart",
)

# bazel run //my-service:push
helm_push(
    name = "push",
    chart = ":chart",
    repository_url = "oci://europe-docker.pkg.dev/my-project/helm-charts",
)

# bazel run //my-service:install
helm_release(
    name = "install",
    chart = ":chart",
    release_name = "my-service",
    namespace = "my-namespace",
    values = ["values-prod.yaml"],
    kubernetes_context = "my-cluster",
)

# bazel run //my-service:uninstall
helm_uninstall(
    name = "uninstall",
    release_name = "my-service",
    namespace = "my-namespace",
    kubernetes_context = "my-cluster",
)
```

`bazel build //my-service:chart` produces `my-service-1.4.0.tgz`. Rules that talk to a registry or a cluster (`helm_push`, `helm_release`, `helm_uninstall`, `k8s_namespace`, `gcs_upload`) build an executable: run them with `bazel run`.

## Rules

### Helm

Load from `@masorange_rules_helm//helm:defs.bzl`.

| Rule | What it does |
| --- | --- |
| [`helm_chart`](docs/helm_chart.md#helm_chart) | Packages a chart into a reproducible `<chart_name>-<version>.tgz`. Overrides `Chart.yaml` fields (`version`, `app_version`, `api_version`, `description`, also from a JSON/YAML version file), sets values by YAML path, adds templates, embeds chart dependencies under `charts/` and stamps an `oci_image` digest into the values. Sources can be checked-in files or outputs of other rules; a chart can even be declared without sources. The macro is a wrapper around the [`chart_srcs`](docs/helm_chart.md#chart_srcs) rule, which documents every attribute. |
| [`helm_lint_test`](docs/helm_lint.md) | Test target running `helm lint` on a packaged chart. |
| [`helm_push`](docs/helm_push.md) | Publishes a packaged chart to an OCI registry (`oci://`, with `helm push`) or to an HTTP chart repository (ChartMuseum-style API). Credentials come from the host `helm` config or from `HELM_USER`/`HELM_PASSWORD`. |
| [`helm_pull`](docs/helm_pull.md) | Repository rule (and `utils.pull` bzlmod extension) that downloads a chart from a remote registry and exposes it as `@<repo>//:chart`, ready to be used in `deps`. Needs `helm` on the host `PATH`. |
| [`helm_release`](docs/helm_release.md) | Installs or upgrades a release (`helm upgrade --install`) from a packaged chart or a remote chart, with values files (including decrypted secrets), `--set` overrides, namespace creation and kube context selection. |
| [`helm_uninstall`](docs/helm_uninstall.md) | Uninstalls a release. |

`helm_chart` also exposes a [`ChartInfo`](docs/helm_chart.md#chartinfo) provider (chart name, version, sources and archive) for rules that want to consume charts.

### Sops

Load from `@masorange_rules_helm//sops:defs.bzl`.

| Rule | What it does |
| --- | --- |
| [`sops_decrypt`](docs/sops_decrypt.md) | Decrypts sops-encrypted files with an [age](https://github.com/FiloSottile/age) key file or a `.sops.yaml` config. Its outputs can be fed to `helm_release` as values files. |

### Kubernetes

Load from `@masorange_rules_helm//k8s:defs.bzl`.

| Rule | What it does |
| --- | --- |
| [`k8s_namespace`](docs/k8s_namespace.md) | Creates a namespace with `kubectl`, optionally annotating a service account and binding it to a GCP service account through GKE Workload Identity (`gcloud`). Use it as `namespace_dep` of `helm_release`. |

### Google Cloud Storage

Load from `@masorange_rules_helm//gcs:defs.bzl`.

| Rule | What it does |
| --- | --- |
| [`gcs_upload`](docs/gcs_upload.md) | Uploads a single file to a `gs://` bucket. |

## Toolchains

The binaries are downloaded from their official release channels and pinned by sha256:

| Tool | Default version | Available versions |
| --- | --- | --- |
| helm | v3.16.3 | v3.16.3, v3.13.2, v3.13.1 |
| sops | v3.8.1 | v3.8.1 |
| kubectl | v1.28.2 | v1.28.2 |
| gcloud | 502.0.0 | 502.0.0, 473.0.0, 450.0.0 |

With bzlmod the module registers the default versions. To pin another one, declare your own installation with a distinct name and register it; toolchains registered by the root module take precedence:

```starlark
# MODULE.bazel
tools = use_extension("@masorange_rules_helm//:extensions.bzl", "toolchains")
tools.install(
    helm_name = "helm_pinned",
    helm_version = "v3.13.2",
)
use_repo(tools, "helm_pinned_toolchains")

register_toolchains("@helm_pinned_toolchains//:all")
```

The same tag accepts `sops_name`/`sops_version`, `kubectl_name`/`kubectl_version` and `gcloud_name`/`gcloud_version`. Versions must be one of the listed ones (each entry carries its checksums in `*/private/*_toolchain.bzl`; adding a version is a small PR).

With `WORKSPACE`, `masorange_rules_helm_configure()` registers the defaults; the `register_*_toolchains(name, version, register = True)` helpers in `toolchains.bzl` let you register a different version.

## Stamping values

`values` accepts Bazel workspace status variables. Enable stamping on the target and pass `--stamp` together with a `--workspace_status_command`:

```starlark
helm_chart(
    name = "chart",
    chart_name = "my-service",
    srcs = glob(["chart/**"]),
    stamp = -1,  # follow --stamp / --nostamp
    values = {
        "deployment.branch": "${STABLE_GIT_BRANCH}",
        "deployment.buildTime": "${BUILD_TIMESTAMP}",
    },
)
```

```sh
bazel build //my-service:chart --stamp --workspace_status_command=./stamp.sh
```

Both stable and volatile variables are supported. Stamped charts are rebuilt whenever the status changes, so keep `stamp` off for charts that must stay cacheable.

## Examples

The [`examples/`](examples) directory is a standalone Bazel module that consumes these rules the way a user would; it is built by CI and by the BCR presubmit on Bazel 7, 8 and 9.

| Example | Shows |
| --- | --- |
| [`simple_chart`](examples/simple_chart) | Package, lint and push a chart (also with the retro-compatible `helm/helm.bzl` API). |
| [`chart_override`](examples/chart_override) | Override `Chart.yaml` fields from the rule. |
| [`chart_version_file`](examples/chart_version_file) | Take the chart version or appVersion from a JSON or YAML file. |
| [`chart_multi_version`](examples/chart_multi_version) | Package the same sources under two versions. |
| [`chart_with_image`](examples/chart_with_image) | Stamp an `oci_image` digest into the values. |
| [`chart_with_deps`](examples/chart_with_deps) | Embed another `helm_chart` as a dependency. |
| [`empty_chart`](examples/empty_chart) | Declare a chart with no source files at all. |
| [`release_local_chart`](examples/release_local_chart), [`release_remote_chart`](examples/release_remote_chart) | Install a packaged or a remote chart with `helm_release`. |
| [`release_with_secrets`](examples/release_with_secrets) | Decrypt sops secrets with age and pass them as values. |

## Development

```sh
bazel test //...                      # rules and integration tests (uses stamp.sh in CI: --config=ci)
(cd examples && bazel test //...)     # the examples module, against the local checkout
bazel run //docs:write_docs_md        # regenerate docs/*.md with Stardoc after changing a docstring
```

Rule implementations live under `<area>/private/`; the public API is re-exported from `<area>/defs.bzl` (and `helm/helm.bzl` for the pre-1.0 load path). Tests for `helm_chart` are in `helm/tests/helm_chart` and unpack the produced archive to compare it with the expected files.

## Releases

Pushing a tag `vX.Y.Z` runs [`release.yaml`](.github/workflows/release.yaml): it runs the tests, builds the source archive, creates the GitHub release with the installation snippet and opens the publication PR against the [Bazel Central Registry](https://registry.bazel.build/modules/masorange_rules_helm) through [`publish.yaml`](.github/workflows/publish.yaml).

## License

[Apache 2.0](LICENSE.txt)
