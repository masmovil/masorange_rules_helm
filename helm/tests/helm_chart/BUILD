package(default_visibility = ["//visibility:public"])

load("//helm:defs.bzl", "helm_chart")
load("@bazel_skylib//rules:build_test.bzl", "build_test")
load(":charts.bzl", "get_charts")
load("@rules_oci//oci:defs.bzl", "oci_image")
load("//helm/tests/helm_chart:chart_test.bzl", "chart_test", "add_prefix_to_paths")
load("@bazel_skylib//lib:paths.bzl", "paths")

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
apiVersion: v2
description: Description of the declarative chart
""",
  expected_values = """
k8s:
  service:
    name: testname
    port: 1050
""",
)
