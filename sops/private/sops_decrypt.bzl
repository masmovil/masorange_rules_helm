
_DOC = """Decrypt secrets using [sops](https://github.com/mozilla/sops)

    To load the rule use:
    ```starlark
    load("//sops:defs.bzl", "sops_decrypt")
    ```

    You can decrypt as many secrets as you want using `sops_decrypt` rule. Use the rule attribute `src` to provide the encrypted secrets that you want to decrypt.
    The rule also needs the sops config file with the keyring id in order to decrypt files (`.sops.yaml`). You can provide it using the `sops_yaml` rule attribute.
    If no sops_yaml config is provided, the rule will try to locate a `.sops.yaml` file by default in the same directory where the target is placed.

    Example of use:
    ```starlark
    # explicit .sops.yaml config
    load("//sops:defs.bzl", "sops_decrypt")

    sops_decrypt(
        name = "decrypt_secret_files",
        srcs = [":secrets.yaml"]
        sops_yaml = ":.sops.yaml"
    )
    ```

    ```starlark
    # implicit .sops.yaml config
    load("//sops:defs.bzl", "sops_decrypt")

    sops_decrypt(
        name = "decrypt_secret_files",
        srcs = [":secrets.yaml"]
    )
    ```

    The outputs of the rule are the decrypted secrets that you can later provide to other rules, as for example to `helm_release`:

    ```starlark
    sops_decrypt(
        name = "decrypt_secret_files",
        srcs = [":secrets.yaml"]
    )

    helm_release(
        name = "chart_install",
        chart = ":chart",
        namespace = "myapp",
        release_name = "release-name",
        values = glob(["charts/myapp/values.yaml"]) + [":decrypt_secret_files"],
    )
    ```

    You can also use [age](https://github.com/FiloSottile/age) key file to decrypt your secrets. To provide the key_file use the rule attribute `age_keys_file` to point
    to the age keys file used to encrypt your secrets.

    ```starlark
    sops_decrypt(
        name = "decrypt_secret_files",
        srcs = [":secrets.yaml"],
        age_keys_file = "sops/age_keys.txt"
    )

    helm_release(
        name = "chart_install",
        chart = ":chart",
        namespace = "myapp",
        release_name = "release-name",
        values = glob(["charts/myapp/values.yaml"]) + [":decrypt_secret_files"],
    )
    ```

"""


def _sops_decrypt_impl(ctx):
    sops = ctx.toolchains["@masorange_rules_helm//sops:sops_toolchain_type"].sopsinfo.bin

    inputs = [ctx.file.sops_yaml, sops]
    outputs = []

    env = dict()

    for src in ctx.files.srcs:

        out_file = ctx.actions.declare_file("dec." + src.basename)

        args = ctx.actions.args()

        args.add("--output", out_file.path)
        args.add("--decrypt", src.path)
        args.add("--config", ctx.file.sops_yaml.path)

        if ctx.file.age_keys_file:
            inputs += [ctx.file.age_keys_file]

            env["SOPS_AGE_KEY_FILE"] = ctx.file.age_keys_file.path

        outputs.append(out_file)

        ctx.actions.run(
            inputs = inputs + [src],
            outputs = [out_file],
            arguments = [args],
            env = env,
            executable = sops,
        )

    return [
        DefaultInfo(
            files = depset(outputs)
        )
    ]

sops_decrypt = rule(
    implementation = _sops_decrypt_impl,
    doc = _DOC,
    attrs = {
      "srcs": attr.label_list(allow_files = True, mandatory = True, doc = "List of encrypted files to be decrypted."),
      "sops_yaml": attr.label(allow_single_file = True, mandatory = True, doc = "The .sops.yaml configuration file. If no provided, the macro will usually try to locate the configuration file in the same dir where the BUILD file is located."),
      "age_keys_file": attr.label(allow_single_file = True, mandatory = False, doc = "Age file with age keys used to encrypt the secret. [Check official docs](https://github.com/getsops/sops?tab=readme-ov-file#encrypting-using-age) about how to use age with sops."),
    },
    toolchains = [
        "@masorange_rules_helm//sops:sops_toolchain_type",
    ],
)
