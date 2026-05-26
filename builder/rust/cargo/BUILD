# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.


load("@io_bazel_rules_kotlin//kotlin:jvm.bzl", "kt_jvm_library")
load("//tool/checkstyle:rules.bzl", "checkstyle_test")

java_binary(
    name = "manifest-writer",
    runtime_deps = [
        ":manifest-writer-lib",
    ],
    main_class = "com.typedb.dependencies.builder.rust.cargo.ManifestWriterKt",
    visibility = ["//visibility:public"],
)

kt_jvm_library(
    name = "manifest-writer-lib",
    srcs = [
        "ManifestWriter.kt",
    ],
    deps = [
        "@typedb_bazel_distribution//common",
        "@typedb_bazel_distribution//common/shell",
        "@typedb_bazel_distribution//common/util",

        "@typedb_maven//:com_electronwill_night_config_core",
        "@typedb_maven//:com_electronwill_night_config_toml",
        "@typedb_maven//:info_picocli_picocli",
        "@typedb_maven//:org_zeroturnaround_zt_exec",
    ]
)

checkstyle_test(
    name = "checkstyle",
    include = glob(["*"]),
    license_type = "mpl-header",
    size = "small",
)
