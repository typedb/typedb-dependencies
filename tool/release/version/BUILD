# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.


load("@io_bazel_rules_kotlin//kotlin:jvm.bzl", "kt_jvm_binary")
load("//tool/checkstyle:rules.bzl", "checkstyle_test")

package(default_visibility = ["//visibility:public"])

kt_jvm_binary(
    name = "bump",
    srcs = ["Bump.kt"],
    main_class = "com.typedb.dependencies.tool.release.version.Bump",
    deps = [
        "@typedb_bazel_distribution//common",
        "@typedb_maven//:commons_io_commons_io",
        "@typedb_maven//:info_picocli_picocli",
        "@typedb_maven//:org_zeroturnaround_zt_exec",
        "@typedb_maven//:com_fasterxml_jackson_core_jackson_core",
        "@typedb_maven//:com_fasterxml_jackson_core_jackson_databind",
        "@typedb_maven//:com_vdurmont_semver4j"
    ],
)

checkstyle_test(
    name = "checkstyle",
    include = glob(["*"]),
    license_type = "mpl-header",
    size = "small",
)
