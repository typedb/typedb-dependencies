# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.


def _copy_to_bin(ctx, src, dst):
    ctx.actions.run_shell(
        inputs = [src],
        outputs = [dst],
        command = "cp -f '{}' '{}'".format(src.path, dst.path),
    )

def _swig_java_wrapper_impl(ctx):
    module_name = getattr(ctx.attr, "class_name", ctx.attr.name)

    wrap_java_dir = ctx.actions.declare_directory("{}".format(module_name))

    args = ctx.attr.extra_args + [
        "-java",
        "-package", ctx.attr.package,
        "-outdir", wrap_java_dir.path,
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

    # Find the SWIG library path for setting SWIG_LIB environment variable
    # This overrides the compiled-in SWIG_LIB path which doesn't work in Bzlmod
    swig_lib_path = None
    swig_lib_files = ctx.attr._swig_templates.files.to_list()
    for f in swig_lib_files:
        if "/Lib/" in f.path:
            # Extract path up to and including /Lib
            swig_lib_path = f.path.split("/Lib/")[0] + "/Lib"
            break

    env = {}
    if swig_lib_path:
        env["SWIG_LIB"] = swig_lib_path

    ctx.actions.run(
        inputs = depset([ctx.file.interface] + ctx.files.includes, transitive = [
            ctx.attr.lib[CcInfo].compilation_context.headers,
            ctx.attr._swig.data_runfiles.files,
            ctx.attr._swig_templates.files,
        ]),
        outputs = [wrap_src, wrap_java_dir] + swig_headers,
        executable = ctx.file._swig,
        arguments = args,
        env = env,
    )

    wrap_zip = ctx.actions.declare_file(module_name + ".zip")

    args = ctx.actions.args()
    args.add("c")
    args.add(wrap_zip.path)
    args.add_all([wrap_java_dir])

    ctx.actions.run(
        inputs = [wrap_java_dir],
        outputs = [wrap_zip],
        executable = ctx.executable._zipper,
        arguments = [args],
    )

    wrap_srcjar = ctx.actions.declare_file(module_name + ".srcjar")
    _copy_to_bin(ctx, wrap_zip, wrap_srcjar)

    jni_h = ctx.actions.declare_file("jni.h")
    _copy_to_bin(ctx, ctx.file._jni_header, jni_h)

    jni_md_h = ctx.actions.declare_file("jni_md.h")
    _copy_to_bin(ctx, ctx.file.jni_md_header, jni_md_h)

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
            [jni_h.dirname, jni_md_h.dirname],
            transitive = [lib_compilation_context.system_includes],
        )
    )

    return [
        DefaultInfo(files = depset([jni_h, jni_md_h, wrap_src, wrap_srcjar])),
        CcInfo(
            compilation_context = compilation_context,
            linking_context = ctx.attr.lib[CcInfo].linking_context,
        ),
    ]


_swig_java_wrapper = rule(
    implementation = _swig_java_wrapper_impl,
    attrs = {
        "lib": attr.label(
            doc = "The C library for which to generate the wrapper",
            providers = [CcInfo],
            mandatory = True,
        ),
        "class_name": attr.string(
            doc = "Optional override for the java class name (default: same as target name)",
        ),
        "interface": attr.label(
            doc = "Optional SWIG interface (.i) file",
            allow_single_file = True,
        ),
        "includes": attr.label_list(
            doc = "Additional SWIG files required for wrapper generation",
            allow_files = True,
        ),
        "package": attr.string(
            doc = "Java package for which to generate the sources",
            mandatory = True,
        ),
        "enable_cxx": attr.bool(
            doc = "Enable SWIG C++ processing (default: False)",
            default = False,
        ),
        "extra_args": attr.string_list(
            doc = "Extra arguments to be passed to SWIG",
        ),
        "_jni_header": attr.label(
            default = Label("@bazel_tools//tools/jdk:jni_header"),
            allow_single_file = True,
        ),
        "jni_md_header": attr.label(
            allow_single_file = True,
        ),
        "_swig": attr.label(
            default = Label("@swig//:swig"),
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
        "_swig_templates": attr.label(
            default = Label("@swig//:templates"),
            doc = "SWIG library files (.i, .swg)",
        ),
        "_zipper": attr.label(
            default = Label("@bazel_tools//tools/zip:zipper"),
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
    },
)


def swig_java_wrapper(**kwargs):
    # workaround for select() not being allowed as a default argument
    # cf. https://github.com/bazelbuild/bazel/issues/287
    _swig_java_wrapper(
        jni_md_header = select({
            "@typedb_bazel_distribution//platform:is_mac": Label("@bazel_tools//tools/jdk:jni_md_header-darwin"),
            "@typedb_bazel_distribution//platform:is_linux": Label("@bazel_tools//tools/jdk:jni_md_header-linux"),
            "@typedb_bazel_distribution//platform:is_windows": Label("@bazel_tools//tools/jdk:jni_md_header-windows"),
        }),
        **kwargs,
    )


def swig_java(name, lib, shared_lib_name=None, tags=[], **kwargs):
    swig_wrapper_name = name + "__swig"
    swig_java_wrapper(
        name = swig_wrapper_name,
        class_name = name,
        lib = lib,
        **kwargs,
    )

    if not shared_lib_name:
        shared_lib_name = name

    def swig_cc_binary(shared_lib_filename):
        # name doesn't accept select() either
        native.cc_binary(
            name = shared_lib_filename,
            deps = [lib, swig_wrapper_name],
            srcs = [swig_wrapper_name],
            linkshared = True,
            linkopts = select({
                # TODO: move http certificate/encryption libraries into arguments
                "@typedb_bazel_distribution//platform:is_windows": ["ntdll.lib", "secur32.lib", "crypt32.lib", "ncrypt.lib"],
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

    native.java_library(
        name = name,
        srcs = [swig_wrapper_name],
        resources = ["lib" + shared_lib_name],
        tags = tags,
    )
