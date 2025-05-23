def get_charts():
    return [
        struct(name="a"),
        struct(name="b"),
        struct(name="nomanifest", version = "v0.1.0"),
        struct(name="omitfiles", srcs=native.glob(["charts/omitfiles/**"], exclude = ["filetoremove.txt"])),
        struct(name="valuesschema"),
        struct(name="whole"),
        struct(name="wholemanifest"),
        struct(name="empty", version = "v2.3.5", path_to_chart = "charts/empty",),
        struct(name="withdeps", deps = [":chart_a"]),
    ]
