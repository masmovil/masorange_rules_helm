"""Maintained as public export api for retro-compatibility"""

load("//helm:defs.bzl",
    _helm_chart = "helm_chart",
    _helm_pull = "helm_pull",
    _helm_push = "helm_push",
    _helm_release = "helm_release",
    _helm_lint = "helm_lint_test",
    _helm_uninstall = "helm_uninstall",
    _chart_info = "ChartInfo"
)

def helm_chart(name, **kwargs):
    image = kwargs.get("image")

    if image:
        _helm_chart(
            name = name,
            image_digest = image + ".digest",
            **kwargs,
        )
    else:
        _helm_chart(
            name = name,
            **kwargs,
        )

# Explicitly re-export the functions
helm_push = _helm_push
helm_pull = _helm_pull
helm_release = _helm_release
helm_uninstall = _helm_uninstall
helm_lint_test = _helm_lint
ChartInfo = _chart_info
