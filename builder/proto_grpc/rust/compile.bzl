# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.


def _rust_tonic_compile_impl(ctx):
    protos = [src[ProtoInfo].direct_sources[0] for src in ctx.attr.srcs]

    inputs = ctx.attr.protoc.files.to_list() + protos
    outputs = [ctx.actions.declare_file("{}.rs".format(package)) for package in ctx.attr.packages]

    ctx.actions.run(
        inputs = inputs,
        outputs = outputs,
        executable = ctx.executable._compile_script,
        env = {
            "OUT_DIR": outputs[0].dirname,
            "PROTOC": ctx.attr.protoc.files.to_list()[0].path,
            "PROTOS": ";".join([src.path for src in protos]),
            "PROTOS_ROOT": ctx.attr.srcs[0][ProtoInfo].proto_source_root,
        },
        mnemonic = "RustTonicCompileAction"
    )

    return [DefaultInfo(files = depset(outputs))]

rust_tonic_compile = rule(
    implementation = _rust_tonic_compile_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
            mandatory = True,
            doc = "The .proto source files."
        ),
        "packages": attr.string_list(
            mandatory = True,
            allow_empty = False,
            doc = "The Protobuf package names. Each package name corresponds to a single output file."
        ),
        "protoc": attr.label(
            default = "@com_google_protobuf//:protoc",
            doc = "The protoc executable."
        ),
        "_compile_script": attr.label(
            executable = True,
            cfg = "exec",
            default = "@typedb_dependencies//builder/proto_grpc/rust:compile",
        ),
    }
)
