# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.


load("@bazel_skylib//rules:run_binary.bzl", "run_binary")
load("@rules_cc//cc:defs.bzl", "cc_library")
load("@typedb_dependencies//builder/rust/cargo:project_aspect.bzl", "CargoProjectInfo", "rust_cargo_project_aspect")
load("@rules_rust//rust/private:providers.bzl", "DepInfo")

def rust_cxx_bridge(name, src, deps = []):
    run_binary(
        name = "%s_generator" % name,
        srcs = [src],
        outs = [
            src + ".h",
            src + ".cc",
        ],
        args = [
            "$(location %s)" % src,
            "-o",
            "$(location %s.h)" % src,
            "-o",
            "$(location %s.cc)" % src,
        ],
        tool = select({
            "@typedb_bazel_distribution//platform:is_mac": "@cxxbridge_mac//file",
            "@typedb_bazel_distribution//platform:is_linux": "@cxxbridge_linux//file",
            "@typedb_bazel_distribution//platform:is_windows": "@cxxbridge_windows//file",
#            "//conditions:default": [name + "-mac"],
        }),
    )

    cc_library(
        name = "%s_include" % name,
        hdrs = [src + ".h"],
    )

    cc_library(
        name = name,
        srcs = [src + ".cc"],
        deps = deps + [":%s_include" % name],
    )

def _rust_cbindgen_impl(ctx):
    rust_lib = ctx.attr.lib

    output_header = ctx.actions.declare_file(
        ctx.attr.header_name if ctx.attr.header_name else "{}.h".format(ctx.label.name),
    )

    inputs = rust_lib[OutputGroupInfo].rust_cargo_project

    args = ctx.actions.args()
    args.add("--lang")
    args.add("c")
    if ctx.file.config:
        args.add("--config")
        args.add(ctx.file.config)
        inputs = depset([ctx.file.config], transitive = [inputs])
    args.add("--output")
    args.add(output_header)
    args.add(rust_lib[CargoProjectInfo].manifest.path.rsplit("/", 1)[0])

    rust_toolchain = ctx.toolchains["@rules_rust//rust:toolchain"]
    cargo_home = ctx.actions.declare_directory("cargo-home")
    env = {
        "CARGO": rust_toolchain.cargo.path,
        "CARGO_HOME": cargo_home.path,
        "HOST": rust_toolchain.exec_triple.str,
        "RUSTC": rust_toolchain.rustc.path,
        "TARGET": rust_toolchain.target_triple.str,
    }

    tools = depset([
            rust_toolchain.cargo,
            rust_toolchain.rustc,
        ],
        transitive = [
            rust_toolchain.rust_std,
            rust_toolchain.rustc_lib,
        ],
    )

    ctx.actions.run(
        executable = ctx.file._cbindgen,
        inputs = inputs,
        outputs = [output_header, cargo_home],
        arguments = [args],
        env = env,
        tools = tools,
    )

    rust_compilation_context = rust_lib[CcInfo].compilation_context
    compilation_context = cc_common.create_compilation_context(
        headers = depset([output_header], transitive = [rust_compilation_context.headers]),
        defines = rust_compilation_context.defines,
        framework_includes = rust_compilation_context.framework_includes,
        includes = rust_compilation_context.includes,
        local_defines = rust_compilation_context.local_defines,
        quote_includes = rust_compilation_context.quote_includes,
        system_includes = rust_compilation_context.system_includes,
    )

    return [
        rust_lib[DepInfo],
        CcInfo(
            compilation_context = compilation_context,
            linking_context = rust_lib[CcInfo].linking_context,
        ),
        DefaultInfo(
            files = depset([output_header], transitive = [rust_lib.files]),
            runfiles = ctx.runfiles([output_header], transitive_files = rust_lib.files),
        ),
        OutputGroupInfo(header = depset([output_header])),
     ]

rust_cbindgen = rule(
    implementation = _rust_cbindgen_impl,
    attrs = {
        "lib": attr.label(
            doc = "The `rust_static_library` or `rust_shared_library` target which to run cbindgen on.",
            providers = [CcInfo, CargoProjectInfo],
            aspects = [rust_cargo_project_aspect],
            mandatory = True,
        ),
        "cbindgen_flags": attr.string_list(
            doc = "Optional flags to pass directly to the Cbindgen executable. See https://docs.rs/cbindgen/latest/cbindgen/ for details.",
        ),
        "header_name": attr.string(
            doc = "Optional override for the name of the generated header. The default is the name of the target created by this rule.",
        ),
        "config": attr.label(
            doc = "Optional Cbindgen configuration file",
            allow_single_file = True,
        ),
        "_cbindgen": attr.label(
            default = Label("@crates//:cbindgen__cbindgen"),
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        )
    },
    toolchains = [
        "@rules_rust//rust:toolchain",
    ],
)
