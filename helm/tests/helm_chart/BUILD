package(default_visibility = ["//visibility:public"])

load("//helm:defs.bzl", "helm_chart")
load("@bazel_skylib//rules:build_test.bzl", "build_test")
load(":charts.bzl", "get_charts")
load("@rules_oci//oci:defs.bzl", "oci_image")
load("//helm/tests/helm_chart:chart_test.bzl", "chart_test", "add_prefix_to_paths")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//rules:write_file.bzl", "write_file")

[
  helm_chart(
    name = "chart_%s" % chart_data.name,
    chart_name = chart_data.name,
    srcs = getattr(chart_data, "srcs", "") or glob(["charts/%s/**" % chart_data.name], allow_empty = True),
    deps = getattr(chart_data, "deps", []),
    version = getattr(chart_data, "version", ""),
    path_to_chart = getattr(chart_data, "path_to_chart", ""),
  ) for chart_data in get_charts()
]

[
  build_test(
    name = "build_%s" % chart_data.name,
    targets = [
        ":chart_%s" % chart_data.name
    ],
  ) for chart_data in get_charts()
]

chart_a_srcs = [
  "Chart.yaml",
  "values.yaml",
  "templates/_helpers.tpl",
  "templates/deployment.yaml",
  "templates/svc.yaml",
]

helm_chart(
  name = "chart_a_values_overrides",
  chart_name = "a_values",
  srcs = add_prefix_to_paths("charts/a", chart_a_srcs),
  version = "0.0.0",
  values = {
    "labels.somelabel": "testvalue",
    "labels.data": "1",
    "labels.deep.data.dict.key1": "value1",
    "labels.deep.data.dict.key2": "value2",
    "labels.deep.data.dict.key3": "value3",
  }
)

chart_test(
  name = "chart_a_values_test",
  chart = ":chart_a_values_overrides",
  chart_name = "a_values",
  prefix_srcs = "charts/a",
  expected_files = chart_a_srcs,
  expected_values = """
labels:
  somelabel: testvalue
  data: 1
  deep:
    data:
      dict:
        key1: "value1"
        key2: "value2"
        key3: "value3"
image:
  tag: latest
  repository: aio
""",
  expected_manifest = """
apiVersion: v1
name: a_values
description: Helm chart with v1 apiVersion
version: 0.0.0
appVersion: 1.5.0
""",

)

chart_b_srcs = [
  "Chart.yaml",
  "values.yaml",
  "templates/_helpers.tpl",
  "templates/deployment.yaml",
]

helm_chart(
  name = "chart_b_manifest_overrides",
  chart_name = "b_manifest",
  srcs = add_prefix_to_paths("charts/b", chart_b_srcs),
  version = "v2.3.4",
  app_version = "v1.0.0",
  api_version = "v2",
  description = "some description with testing pourposes",
)

chart_test(
  name = "chart_b_manifest_test",
  chart = ":chart_b_manifest_overrides",
  chart_name = "b_manifest",
  prefix_srcs = "charts/b",
  expected_files = chart_b_srcs,
  expected_manifest = """
apiVersion: v2
name: b_manifest
description: some description with testing pourposes
version: v2.3.4
appVersion: v1.0.0
""",
)

IMAGE_SHA_256 = "sha256:161a1d97d592b3f1919801578c3a47c8e932071168a96267698f4b669c24c76d"
oci_image(
  name = "image",
  base = "@distroless_java",
)

helm_chart(
  name = "chart_a_image",
  chart_name = "a_image",
  srcs = add_prefix_to_paths("charts/a", chart_a_srcs),
  image = ":image",
)

chart_test(
  name = "chart_a_image_test",
  chart = ":chart_a_image",
  chart_name = "a_image",
  prefix_srcs = "charts/a",
  expected_files = chart_a_srcs,
  expected_values = """
labels:
  somelabel: labelvalue
image:
    tag: %s
    repository: aio@
""" % IMAGE_SHA_256,
)

helm_chart(
  name = "chart_a_image_dep",
  chart_name = "a_image_dep",
  srcs = add_prefix_to_paths("charts/a", chart_a_srcs),
  image = ":image",
)

chart_nomanifest_srcs = [
  "values.yaml",
  "templates/_helpers.tpl",
  "templates/deployment.yaml",
  "templates/svc.yaml",
]

helm_chart(
  name = "chart_nomanifest_dep",
  chart_name = "nomanifest_dep",
  version = "1.6.9",
  srcs = add_prefix_to_paths("charts/nomanifest", chart_nomanifest_srcs),
)

helm_chart(
  name = "chart_b_deps",
  chart_name = "b_deps",
  srcs = add_prefix_to_paths("charts/b", chart_b_srcs),
  force_repository_append = False,
  values = {
    "labels.somelabel": "testvalue",
  },
  deps = [
    ":chart_a_image_dep",
    ":chart_nomanifest_dep",
  ]
)

chart_test(
  name = "chart_b_deps_test",
  chart = ":chart_b_deps",
  chart_name = "b_deps",
  prefix_srcs = "charts/b",
  expected_files = chart_b_srcs,
  expected_values = """
labels:
  somelabel: testvalue
image:
  tag: sha256:41b9e05eac7ac512e2ec02437c7de74c1c6fc579565ced13a0d24cc6b3a1df34
  repository: https://registry.io@
""",
expected_manifest = """
apiVersion: v2
name: b_deps
description: Helm chart with v2 apiVersion
version: 0.5.0
appVersion: 1.1.1
dependencies:
- name: a_image_dep
- name: nomanifest_dep
  version: 1.6.9
""",
expected_deps = [
  {
    "name": "a_image_dep",
    "expected_values": """
labels:
  somelabel: labelvalue
image:
    tag: %s
    repository: aio@
""" % IMAGE_SHA_256,
    "expected_manifest": """
apiVersion: v1
name: a_image_dep
description: Helm chart with v1 apiVersion
version: 1.0.1
appVersion: 1.5.0
""",
    "expected_files": chart_a_srcs,
    "prefix_srcs": "charts/a",
  },
  {
    "name": "nomanifest_dep",
    "expected_values": """
image:
  tag: latest
  repository: gcr
""",
    "expected_manifest": """
apiVersion: v2
name: nomanifest_dep
version: 1.6.9
""",
    "expected_files": chart_nomanifest_srcs,
    "prefix_srcs": "charts/nomanifest",
  },
]
)

helm_chart(
  name = "chart_b_dep_condition",
  chart_name = "b_dep_condition",
  srcs = add_prefix_to_paths("charts/b", chart_b_srcs),
  values = {
    "test.enabled": "true",
  },
  deps = [
    ":chart_nomanifest_dep",
  ],
  deps_conditions = {
    "nomanifest_dep": "test.enabled",
  }
)

chart_test(
  name = "chart_b_dep_condition_test",
  chart = ":chart_b_dep_condition",
  chart_name = "b_dep_condition",
  prefix_srcs = "charts/b",
  expected_files = chart_b_srcs,
expected_manifest = """
apiVersion: v2
name: b_dep_condition
description: Helm chart with v2 apiVersion
version: 0.5.0
appVersion: 1.1.1
dependencies:
- name: nomanifest_dep
  version: 1.6.9
  condition: test.enabled
""",
expected_deps = [
  {
    "name": "nomanifest_dep",
    "expected_values": """
image:
  tag: latest
  repository: gcr
""",
    "expected_manifest": """
apiVersion: v2
name: nomanifest_dep
version: 1.6.9
""",
    "expected_files": chart_nomanifest_srcs,
    "prefix_srcs": "charts/nomanifest",
  },
]
)

helm_chart(
  name = "chart_nomanifest_files",
  chart_name = "nomanifest_files",
  srcs = add_prefix_to_paths("charts/nomanifest", chart_nomanifest_srcs),
  values = {
    "test.value.key": "testvalue"
  }
)

chart_test(
  name = "chart_nomanifest_files_test",
  chart_name = "nomanifest_files",
  chart = ":chart_nomanifest_files",
  prefix_srcs = "charts/nomanifest",
  expected_files = chart_nomanifest_srcs,
  expected_values = """
test:
  value:
    key: testvalue
image:
  tag: latest
  repository: gcr
""",
expected_manifest = """
apiVersion: v2
name: nomanifest_files
version: 1.0.0
""",
)

helm_chart(
  name = "chart_a_stamp",
  chart_name = "a_stamp",
  srcs = add_prefix_to_paths("charts/a", chart_a_srcs),
  version = "1.3.0",
  stamp = 1,
  values = {
    "labels.somelabel": "testvalue",
    "labels.data": "${STABLE_TEST_VAR}",
    "labels.deep.data.dict.key1": "value1",
    "labels.deep.data.dict.key2": "${TEST_VAR}",
  },
)

chart_test(
  name = "chart_a_stamp_test",
  chart_name = "a_stamp",
  chart = ":chart_a_stamp",
  prefix_srcs = "charts/a",
  expected_files = chart_a_srcs,
  expected_values = """
labels:
  somelabel: testvalue
  data: TEST_VALUE
  deep:
    data:
      dict:
        key1: "value1"
        key2: "VOLATILE_TEST_VALUE"
image:
  tag: latest
  repository: aio
""",
)

helm_chart(
  name = "chart_a_templates",
  chart_name = "a_templates",
  srcs = add_prefix_to_paths("charts/a", chart_a_srcs),
  version = "0.4.1",
  templates = glob([
    "charts/c/templates/**"
  ]),
  values = {
    "labels.somelabel": "testvalue",
  },
)

helm_chart(
  name = "declarative_chart_no_values",
  chart_name = "declarative_no_values",
  version = "v1.0.1",
  app_version = "v1.0.0",
  api_version = "v2",
  description = "Description of the declarative chart",
  templates = [
    "files/service.yaml",
    "files/configmap.yaml",
  ]
)

chart_test(
  name = "declarative_chart_no_values_test",
  chart_name = "declarative_no_values",
  chart = ":declarative_chart_no_values",
  expected_manifest = """
apiVersion: v2
name: declarative_no_values
version: v1.0.1
appVersion: v1.0.0
description: Description of the declarative chart
""",
)

helm_chart(
  name = "declarative_chart_values",
  chart_name = "declarative_values",
  version = "3.0.45",
  app_version = "0.1.0",
  api_version = "v2",
  description = "Description of the declarative chart",
  templates = [
    "files/service.yaml",
  ],
  values = {
    "k8s.service.name": "testname",
    "k8s.service.port": "1050",
  }
)

chart_test(
  name = "declarative_chart_values_test",
  chart_name = "declarative_values",
  chart = ":declarative_chart_values",
  expected_manifest = """
apiVersion: v2
name: declarative_values
version: 3.0.45
appVersion: 0.1.0
description: Description of the declarative chart
""",
  expected_values = """
k8s:
  service:
    name: testname
    port: 1050
""",
)

helm_chart(
  name = "chart_a_version_file",
  chart_name = "a_version_file",
  version_manifest = "version.json",
  app_version_manifest = "version.json",
  description = "Description",
  srcs = add_prefix_to_paths("charts/a", chart_a_srcs),
)

chart_test(
  name = "chart_version_file_test",
  chart_name = "a_version_file",
  chart = ":chart_a_version_file",
  expected_manifest = """
apiVersion: v1
name: a_version_file
description: Description
version: 1.1.1
appVersion: 1.1.1
""",
  expected_values = """
labels:
  somelabel: labelvalue
image:
  tag: latest
  repository: aio
""",
)

helm_chart(
  name = "chart_a_version_yaml_file",
  chart_name = "a_version_file_yaml",
  version_manifest = "version.yaml",
  app_version_manifest = "version.json",
  description = "Description",
  srcs = add_prefix_to_paths("charts/a", chart_a_srcs),
)

chart_test(
  name = "chart_version_yaml_file_test",
  chart_name = "a_version_file_yaml",
  chart = ":chart_a_version_yaml_file",
  expected_manifest = """
apiVersion: v1
name: a_version_file_yaml
description: Description
version: 1.7.1
appVersion: 1.1.1
""",
  expected_values = """
labels:
  somelabel: labelvalue
image:
  tag: latest
  repository: aio
""",
)

# Issue #41: Chart.yaml and values.yaml are produced by other rules while the templates are checked-in
# sources (plus one generated template). Generated files live under bazel-out, so the chart root has to
# be resolved from workspace-relative paths for both kinds of files to end up in the same chart layout.
write_file(
  name = "chart_generated_manifest",
  out = "charts/generated/Chart.yaml",
  content = [
    "apiVersion: v2",
    "name: placeholder",
    "version: 0.0.1",
    "description: Chart.yaml generated by write_file",
  ],
)

write_file(
  name = "chart_generated_values",
  out = "charts/generated/values.yaml",
  content = [
    "image:",
    "  tag: latest",
    "  repository: generated",
  ],
)

write_file(
  name = "chart_generated_configmap",
  out = "charts/generated/templates/configmap.yaml",
  content = [
    "apiVersion: v1",
    "kind: ConfigMap",
    "metadata:",
    "  name: generated",
  ],
)

chart_generated_srcs = [
  "Chart.yaml",
  "values.yaml",
  "templates/_helpers.tpl",
  "templates/deployment.yaml",
  "templates/svc.yaml",
  "templates/configmap.yaml",
]

helm_chart(
  name = "chart_generated",
  chart_name = "generated",
  version = "0.2.0",
  srcs = add_prefix_to_paths("charts/generated", chart_generated_srcs),
  values = {
    "labels.somelabel": "testvalue",
  },
)

chart_test(
  name = "chart_generated_test",
  chart = ":chart_generated",
  chart_name = "generated",
  prefix_srcs = "charts/generated",
  expected_files = chart_generated_srcs,
  expected_values = """
labels:
  somelabel: testvalue
image:
  tag: latest
  repository: generated
""",
  expected_manifest = """
apiVersion: v2
name: generated
version: 0.2.0
description: Chart.yaml generated by write_file
""",
)

# A chart consumed as a dependency also goes through the same root resolution (its files are all
# generated outputs of the dependency's chart_srcs).
helm_chart(
  name = "chart_generated_parent",
  chart_name = "generated_parent",
  srcs = add_prefix_to_paths("charts/b", chart_b_srcs),
  version = "0.3.0",
  deps = [":chart_generated"],
)

chart_test(
  name = "chart_generated_parent_test",
  chart = ":chart_generated_parent",
  chart_name = "generated_parent",
  prefix_srcs = "charts/b",
  expected_files = chart_b_srcs,
  expected_manifest = """
apiVersion: v2
name: generated_parent
description: Helm chart with v2 apiVersion
version: 0.3.0
appVersion: 1.1.1
dependencies:
- name: generated
  version: 0.2.0
""",
  expected_deps = [
    {
      "name": "generated",
      "expected_values": """
labels:
  somelabel: testvalue
image:
  tag: latest
  repository: generated
""",
      "expected_manifest": """
apiVersion: v2
name: generated
version: 0.2.0
description: Chart.yaml generated by write_file
""",
      "expected_files": chart_generated_srcs,
      "prefix_srcs": "charts/generated",
    },
  ],
)

# Same scenario with only Chart.yaml generated: values.yaml and the templates are sources. Before the
# fix the values file was looked up next to the generated manifest (under bazel-out), so it was not
# found and the packaged values.yaml silently kept only the `values` overrides (the source values were lost).
write_file(
  name = "chart_genmanifest_manifest",
  out = "charts/genmanifest/Chart.yaml",
  content = [
    "apiVersion: v2",
    "name: placeholder",
    "version: 0.0.1",
  ],
)

chart_genmanifest_srcs = [
  "Chart.yaml",
  "values.yaml",
  "templates/_helpers.tpl",
  "templates/deployment.yaml",
]

helm_chart(
  name = "chart_genmanifest",
  chart_name = "genmanifest",
  version = "0.4.0",
  srcs = add_prefix_to_paths("charts/genmanifest", chart_genmanifest_srcs),
  values = {
    "labels.extra": "override",
  },
)

chart_test(
  name = "chart_genmanifest_test",
  chart = ":chart_genmanifest",
  chart_name = "genmanifest",
  prefix_srcs = "charts/genmanifest",
  expected_files = chart_genmanifest_srcs,
  expected_values = """
labels:
  somelabel: sourcevalue
  extra: override
image:
  tag: latest
  repository: genmanifest
""",
  expected_manifest = """
apiVersion: v2
name: genmanifest
version: 0.4.0
""",
)

# Only a values.yaml placed at the chart root is the chart values file: a nested one (a vendored
# subchart's, an environment file) must not be picked up as the root values when the root has none.
chart_nestedvalues_srcs = [
  "Chart.yaml",
  "templates/deployment.yaml",
  "charts/sub/values.yaml",
]

helm_chart(
  name = "chart_nestedvalues",
  chart_name = "nestedvalues",
  version = "0.5.0",
  srcs = add_prefix_to_paths("charts/nestedvalues", chart_nestedvalues_srcs),
  values = {
    "root.only": "rootvalue",
  },
)

chart_test(
  name = "chart_nestedvalues_test",
  chart = ":chart_nestedvalues",
  chart_name = "nestedvalues",
  prefix_srcs = "charts/nestedvalues",
  expected_files = ["Chart.yaml", "templates/deployment.yaml"],
  expected_values = """
root:
  only: rootvalue
""",
  expected_manifest = """
apiVersion: v2
name: nestedvalues
version: 0.5.0
description: Chart with a nested values.yaml only
""",
)

# A declarative chart (no values.yaml) with an image: the digest is written to .image.tag and the
# repository set through `values` is left untouched (there is no values file to read it from).
helm_chart(
  name = "declarative_chart_image",
  chart_name = "declarative_image",
  version = "0.1.0",
  api_version = "v2",
  image = ":image",
  templates = [
    "files/service.yaml",
  ],
  values = {
    "image.repository": "registry.example/app",
  },
)

chart_test(
  name = "declarative_chart_image_test",
  chart_name = "declarative_image",
  chart = ":declarative_chart_image",
  expected_values = """
image:
  repository: registry.example/app
  tag: %s
""" % IMAGE_SHA_256,
)

