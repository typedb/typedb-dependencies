# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.


load("@io_bazel_rules_kotlin//kotlin:kotlin.bzl", "kt_jvm_library")
load("//tool/checkstyle:rules.bzl", "checkstyle_test")

java_binary(
    name = "rust_sync",
    runtime_deps = [
        ":rust_manifest_syncer",
    ],
    main_class = "com.typedb.dependencies.tool.ide.RustManifestSyncerKt",
    visibility = ["//visibility:public"],
)

kt_jvm_library(
    name = "rust_manifest_syncer",
    srcs = [
        "RustManifestSyncer.kt",
    ],
    deps = [
        "@typedb_bazel_distribution//common",
        "@typedb_bazel_distribution//common/shell",
        "@typedb_bazel_distribution//common/util",

        "@typedb_maven//:com_eclipsesource_minimal_json_minimal_json",
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
