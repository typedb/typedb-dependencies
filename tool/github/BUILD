# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

load("@io_bazel_rules_kotlin//kotlin:kotlin.bzl", "kt_jvm_library")
load("@typedb_dependencies//tool/checkstyle:rules.bzl", "checkstyle_test")

kt_jvm_library(
    name = "open-pr-jar",
    srcs = glob(["*.kt"]),
    data = glob(["template/**/*"], allow_empty = True),
    deps = [
        "@typedb_bazel_distribution//common",
        "@typedb_bazel_distribution//common/shell",
        "@maven//:org_zeroturnaround_zt_exec",
        "@maven//:commons_io_commons_io",
        "@maven//:info_picocli_picocli",
        "@maven//:org_kohsuke_github_api",
    ],
    visibility = ["//visibility:private"],
)

java_binary(
    name = "open-pr",
    runtime_deps = ["open-pr-jar"],
    main_class = "com.typedb.dependencies.tool.github.OpenPR",
    visibility = ["//visibility:public"],
)

checkstyle_test(
    name = "checkstyle",
    include = glob(["*"]),
    license_type = "mpl-header",
)
