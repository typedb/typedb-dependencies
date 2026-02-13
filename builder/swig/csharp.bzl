# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.


load("@rules_dotnet//dotnet:defs.bzl", "csharp_library")
load("@rules_dotnet//dotnet/private:providers.bzl", "DotnetAssemblyCompileInfo", "DotnetAssemblyRuntimeInfo")


def _swig_csharp_wrapper_impl(ctx):
    module_name = getattr(ctx.attr, "class_name", ctx.attr.name)

    wrap_csharp_name = "{}.cs".format(module_name)
    wrap_csharp = ctx.actions.declare_file(wrap_csharp_name)

    args = ctx.attr.extra_args + [
        "-csharp",
        "-namespace", ctx.attr.namespace,
        "-outfile", wrap_csharp_name,
        ctx.file.interface.path,
    ]

    if ctx.attr.enable_cxx:
        wrap_cxx = ctx.actions.declare_file("{}_wrap.cxx".format(module_name))
        directors_header = ctx.actions.declare_file("{}_wrap.h".format(module_name))
        args = ["-c++", "-o", wrap_cxx.path, "-oh", directors_header.path] + args
        swig_headers = [directors_header]
    else:
        wrap_cxx = ctx.actions.declare_file("{}_wrap.c".format(module_name))
        args = ["-o", wrap_cxx.path] + args
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
        outputs = [wrap_cxx, wrap_csharp] + swig_headers,
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
        DefaultInfo(files = depset([wrap_cxx, wrap_csharp])),
        OutputGroupInfo(
            csharp_source = depset([wrap_csharp]),
            cxx_source = depset([wrap_cxx]),
        ),
        CcInfo(
            compilation_context = compilation_context,
            linking_context = ctx.attr.lib[CcInfo].linking_context,
        ),
    ]


swig_csharp_wrapper = rule(
    implementation = _swig_csharp_wrapper_impl,
    attrs = {
        "lib": attr.label(
            doc = "The C library for which to generate the wrapper",
            providers = [CcInfo],
            mandatory = True,
        ),
        "class_name": attr.string(
            doc = "Optional override for the C# class name (default: same as target name)",
        ),
        "interface": attr.label(
            doc = "Optional SWIG interface (.i) file",
            allow_single_file = True,
        ),
        "includes": attr.label_list(
            doc = "Additional SWIG files required for wrapper generation",
            allow_files = True,
        ),
        "namespace": attr.string(
            doc = "C# namespace for the sources",
            mandatory = True,
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


def _csharp_native_library(ctx):
    return [
        DefaultInfo(
            files = depset([ctx.file.native_lib]),
            runfiles = ctx.runfiles(files = [ctx.file.native_lib])
        ),
        DotnetAssemblyCompileInfo(
            name = "{}".format(ctx.file.native_lib.basename),
            internals_visible_to = ctx.attr.name,
            refs = [],
            irefs = [],
            analyzers = [],
            compile_data = [ctx.file.native_lib],
            exports = [],
        ),
        DotnetAssemblyRuntimeInfo(
            name = "{}".format(ctx.file.native_lib.basename),
            version = "",
            deps = depset(),
            nuget_info = [],
            libs = [],
            native = [ctx.file.native_lib],
            direct_deps_depsjson_fragment = [],
        )]


csharp_native_library = rule(
    implementation = _csharp_native_library,
    attrs = {
        "native_lib": attr.label(
            doc = "Native cc library which needs to be wrapped as a C# library",
            providers = [CcInfo],
            mandatory = True,
            allow_single_file = True,
        ),
    },
)


def swig_csharp(name, native_lib_name, lib, namespace, nullable_context, target_frameworks, targeting_packs, tags=[], **kwargs):
    swig_wrapper_name = "{}_swig".format(name)
    swig_csharp_wrapper(
        name = swig_wrapper_name,
        class_name = name,
        lib = lib,
        namespace = namespace,
        **kwargs,
    )

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

    swig_cc_binary("lib" + native_lib_name + ".dylib")
    swig_cc_binary("lib" + native_lib_name + ".so")
    swig_cc_binary(native_lib_name + ".dll")

    native.alias(
        name = native_lib_name,
        actual = select({
            "@typedb_bazel_distribution//platform:is_mac": ("lib" + native_lib_name + ".dylib"),
            "@typedb_bazel_distribution//platform:is_linux": ("lib" + native_lib_name + ".so"),
            "@typedb_bazel_distribution//platform:is_windows": (native_lib_name + ".dll"),
        })
    )

    csharp_native_lib_name = "{}_csharp".format(native_lib_name)

    csharp_native_library(
        name = csharp_native_lib_name,
        native_lib = ":{}".format(native_lib_name),
    )

    csharp_source_name = "{}.cs".format(name)

    native.filegroup(
        name = csharp_source_name,
        srcs = [swig_wrapper_name],
        output_group = "csharp_source",
    )

    csharp_library(
        name = name,
        srcs = [":{}".format(csharp_source_name)],
        deps = [":{}".format(csharp_native_lib_name)],
        out = namespace,
        nullable = nullable_context,
        target_frameworks = target_frameworks,
        targeting_packs = targeting_packs,
        tags = tags,
        allow_unsafe_blocks = True,
    )
