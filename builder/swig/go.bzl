# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

load("@io_bazel_rules_go//go:def.bzl", "go_library")

def _swig_go_wrapper_impl(ctx):
    module_name = ctx.attr.name

    # Swig outputs to a directory when using Go.
    wrap_go_dir = ctx.actions.declare_directory("{}".format(module_name))

    args = ctx.attr.extra_args + [
        "-go",
        "-outdir", wrap_go_dir.path,
        "-intgosize", "32",
        "-package", ctx.attr.package_name,
        ctx.file.interface.path,
    ]

    if ctx.attr.enable_cxx:
        wrap_src = ctx.actions.declare_file("{}_wrap.cxx".format(module_name))
        directors_header = ctx.actions.declare_file("{}_wrap.h".format(module_name))
        args = ["-c++", "-o", wrap_src.path, "-oh", directors_header.path] + args
        swig_headers = [directors_header]
    else:
        wrap_src = ctx.actions.declare_file("{}_wrap.c".format(module_name))
        args = ["-o", wrap_src.path] + args
        swig_headers = []

    for h in ctx.attr.lib[CcInfo].compilation_context.headers.to_list():
        args = ["-I" + h.dirname] + args

    ctx.actions.run(
        inputs = depset(
            [ctx.file.interface] + ctx.files.includes,
            transitive = [
                ctx.attr.lib[CcInfo].compilation_context.headers,
                ctx.attr._swig.data_runfiles.files,
            ]),
        outputs = [wrap_src, wrap_go_dir] + swig_headers,
        executable = ctx.file._swig,
        arguments = args,
    )

    lib_compilation_context = ctx.attr.lib[CcInfo].compilation_context
    compilation_context = cc_common.create_compilation_context(
        headers = depset(swig_headers, transitive = [lib_compilation_context.headers]),
        defines = lib_compilation_context.defines,
        framework_includes = lib_compilation_context.framework_includes,
        includes = depset(
            [h.dirname for h in ctx.attr.lib[CcInfo].compilation_context.headers.to_list()],
            transitive = [lib_compilation_context.includes],
        ),
        local_defines = lib_compilation_context.local_defines,
        quote_includes = lib_compilation_context.quote_includes,
        system_includes = depset(
            [],
            transitive = [lib_compilation_context.system_includes],
        )
    )

    return [
        DefaultInfo(files = depset([wrap_src])),
        OutputGroupInfo(
            go_source = depset([wrap_go_dir]),
            cxx_source = depset([wrap_src]),
        ),
        CcInfo(
            compilation_context = compilation_context,
            linking_context = ctx.attr.lib[CcInfo].linking_context,
        ),
    ]

_swig_go_wrapper = rule(
    implementation = _swig_go_wrapper_impl,
    attrs = {
        "lib": attr.label(
            doc = "The C library for which to generate the wrapper",
            providers = [CcInfo],
            mandatory = True,
        ),
        "interface": attr.label(
            doc = "Optional SWIG interface (.i) file",
            allow_single_file = True,
        ),
        "includes": attr.label_list(
            doc = "Additional SWIG files required for wrapper generation",
            allow_files = True,
        ),
        "package_name": attr.string(
            doc = "Package name override for generated Go package",
        ),
        "enable_cxx": attr.bool(
            doc = "Enable SWIG C++ processing (default: False)",
            default = False,
        ),
        "extra_args": attr.string_list(
            doc = "Extra arguments to be passed to SWIG",
        ),
        "_swig": attr.label(
            default = Label("@swig//:swig"),
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
    },
)

def swig_go(name, lib, package_name, shared_lib_name=None, tags=[], **kwargs):
    swig_wrapper_name = name + "_swig"

    _swig_go_wrapper(
        name = swig_wrapper_name,
        lib = lib,
        package_name = package_name,
        **kwargs,
    )

    if not shared_lib_name:
        shared_lib_name = name

    native.filegroup(
        name = "source_file",
        srcs = [swig_wrapper_name],
        output_group = "go_source",
    )

    cmd_suffix = "$(SRCS)/{pkg_name}.go $@".format(pkg_name=package_name)

    # Copy the generated go file into an output file with the same name.
    native.genrule(
        name = "go_wrapper_copier",
        outs = [package_name + ".go"],
        srcs = [":source_file"],
        cmd_bash = "cp " + cmd_suffix,
        cmd_bat = "copy " + cmd_suffix,
        visibility = ["//visibility:public"],
    )

    def swig_cc_binary(shared_lib_filename):
        native.cc_binary(
            name = shared_lib_filename,
            deps = [lib, swig_wrapper_name],
            srcs = [swig_wrapper_name],
            linkshared = True,
            linkopts = select({
                    "@typedb_bazel_distribution//platform:is_windows": ["ntdll.lib", "secur32.lib", "crypt32.lib", "ncrypt.lib"],
                    "@typedb_bazel_distribution//platform:is_mac": ["-framework CoreFoundation", "-install_name go/{filename}".format(filename=shared_lib_filename)],
                    "//conditions:default": [],
                }),
        )

    swig_cc_binary("lib" + shared_lib_name + ".dylib")
    swig_cc_binary("lib" + shared_lib_name + ".so")
    swig_cc_binary(shared_lib_name + ".dll")

    native.alias(
        name = "lib" + shared_lib_name,
        actual = select({
            "@typedb_bazel_distribution//platform:is_mac": ("lib" + shared_lib_name + ".dylib"),
            "@typedb_bazel_distribution//platform:is_linux": ("lib" + shared_lib_name + ".so"),
            "@typedb_bazel_distribution//platform:is_windows": (shared_lib_name + ".dll"),
        })
    )

    go_library(
        name = name,
        srcs = [package_name + ".go"],
        data = ["lib" + shared_lib_name],
        importpath = package_name + "/go_wrapper",
        visibility = ["//visibility:public"],
        cgo = True,
    )
