# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.


load("@io_bazel_rules_kotlin//kotlin:jvm.bzl", "kt_jvm_binary", "kt_jvm_test")

def _release_validate_deps_script_impl(ctx):
    test_script = ctx.actions.declare_file("{}.kt".format(ctx.attr.name))

    ctx.actions.expand_template(
        output = test_script,
        template = ctx.file._release_validate_deps_template,
        substitutions = {
            "{workspace_refs_json_path}": ctx.file.refs.path,
            "{version_file_path}": ctx.file.version_file.path,
            "{tagged_deps}": ",".join(ctx.attr.tagged_deps),
        }
    )

    return [
        DefaultInfo(
            runfiles = ctx.runfiles(files = [ctx.file.refs, ctx.file.version_file]),
            executable = test_script
        )
    ]


_release_validate_deps_script_test = rule(
    attrs = {
        "refs": attr.label(
            allow_single_file = True,
            mandatory = True
        ),
        "version_file": attr.label(
            allow_single_file = True,
            mandatory = True
        ),
        "tagged_deps": attr.string_list(
            mandatory = True
        ),
        "_release_validate_deps_template": attr.label(
            allow_single_file=True,
            default = "@typedb_dependencies//tool/release/deps:ValidateDeps.kt"
        )
    },
    implementation = _release_validate_deps_script_impl,
    test = True
)

# macro to create the templating rule and binary executable rule
def release_validate_deps(name, **kwargs):
    standard_name = name.capitalize().replace("-","_")
    target_name = standard_name + "_gen"

    # create rule that generates the templated script with the correct inputs
    _release_validate_deps_script_test(
        name = target_name,
        **kwargs
    )

    # assign this rule instance as the name that is passed in, so it is called with `bazel run `
    kt_jvm_test(
        name = name,
        main_class = "com.typedb.dependencies.tool.release.deps." + standard_name + "_genKt",
        srcs = [target_name],
        deps = [
            "@typedb_maven//:com_eclipsesource_minimal_json_minimal_json"
        ],
    )


def release_validate_nodejs_deps(
        name,
        package_json,
        version_file,
        tagged_deps,
    ):
        kt_jvm_test(
            name = name,
            main_class = "com.typedb.dependencies.tool.release.deps.ValidateNodeJsDepsKt",
            srcs = [
                "@typedb_dependencies//tool/release/deps:ValidateNodeJsDeps.kt"
            ],
            data = [
                package_json,
            ],
            deps = [
                "@typedb_maven//:com_eclipsesource_minimal_json_minimal_json",
                "@typedb_maven//:com_google_http_client_google_http_client",
            ],
            args = ["$(location {})".format(package_json), "$(location {})".format(version_file)] + tagged_deps,
            tags = ["manual"],
        )


def release_validate_python_deps(
        name,
        requirements,
        version_file,
        tagged_deps,
    ):
        kt_jvm_test(
            name = name,
            main_class = "com.typedb.dependencies.tool.release.deps.ValidatePythonDepsKt",
            srcs = [
                "@typedb_dependencies//tool/release/deps:ValidatePythonDeps.kt"
            ],
            data = [
                requirements,
            ],
            deps = [
                "@typedb_maven//:com_eclipsesource_minimal_json_minimal_json",
                "@typedb_maven//:com_google_http_client_google_http_client",
            ],
            args = ["$(location {})".format(requirements), "$(location {})".format(version_file)] + tagged_deps,
            tags = ["manual"],
        )
