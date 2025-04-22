# Masorange rules helm

This repository contains Bazel rules to manipulate and operate Helm charts with Bazel, decrpyt sops secrets, and run operations over cloud services.

# Installation
These rules support installation via both `bzlmod` and `non-bzlmod`.

Check out [github releases page](https://github.com/masmovil/bazel-rules/releases) to see the latest version of the rules and how to install them using bazel.

## Helm
 - [helm_chart](docs/helm_chart.md) Reproducible rule to package a helm chart into a targz archive with custom values and configuration
 - [helm_lint_test](docs/helm_lint.md) Lint and test that a helm chart is well-formed. Wrapper around `helm lint` command
 - [helm_push](docs/helm_push.md) Publish a helm chart produced by `helm_chart` rule to a remote registry.
 - [helm_pull](docs/helm_pull.md) Repository rule to download a `helm_chart` from a remote registry.
 - [helm_release](docs/helm_release.md) Installs or upgrades a helm chart in to a cluster using the helm binary toolchain.
 - [helm_uninstall](docs/helm_uninstall.md) Uninstall a helm release.

## Sops
- [sops_decrypt](docs/sops_decrypt.md) Decrypt secrets using [sops](https://github.com/mozilla/sops)

## k8s
- [k8s_namespace](docs/k8s_namespace.md) Create a kubernetes namespace in a k8s cluster with workload identity support. You can also configure GKE Workload Identity with it.

## gcs
- [gcs_upload](docs/gcs_upload.md) Upload a file to a Google Cloud Storage bucket

## Toolchains
## Contribute
