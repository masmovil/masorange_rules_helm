#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail


TAG=${GITHUB_REF_NAME}
FULL_REPO_NAME=${GITHUB_REPOSITORY}
REPO_NAME_SPLIT=(${FULL_REPO_NAME//// })
REPO_NAME=${REPO_NAME_SPLIT[1]}

# The prefix is chosen to match what GitHub generates for source archives
PREFIX="$REPO_NAME-${TAG:1}"
ARCHIVE="$REPO_NAME-$TAG.tar.gz"

git archive --format=tar --prefix="${PREFIX}/" "${TAG}" | gzip >"$ARCHIVE"
SHA=$(shasum -a 256 "$ARCHIVE" | awk '{print $1}')

cat <<EOF
# Using Bzlmod:

Add to your MODULE.bazel file:

\`\`\`py
bazel_dep(name = "$REPO_NAME", version = "${TAG:1}")
\`\`\`

# Using WORKSPACE:

Paste this into your WORKSPACE file:

\`\`\`py
http_archive(
    name = "$REPO_NAME",
    sha256 = "$SHA",
    strip_prefix = "${PREFIX}",
    urls = [
        "https://github.com/$FULL_REPO_NAME/releases/download/$TAG/$ARCHIVE",
    ],
)

load("@$REPO_NAME//:repositories.bzl", "masorange_rules_helm_repositories")

masorange_rules_helm_repositories()

load("@$REPO_NAME//:config.bzl", "masorange_rules_helm_configure")

masorange_rules_helm_configure()
\`\`\`
EOF
