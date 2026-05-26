# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

package(default_visibility = ["//visibility:public"])
load("//tool/checkstyle:rules.bzl", "checkstyle_test")
load("@io_bazel_rules_kotlin//kotlin:jvm.bzl", "kt_jvm_library")

kt_jvm_library(
    name = "grammar-adapter-lib",
    srcs = ["GrammarAdapter.kt"],
    deps = [
        "@typedb_maven//:info_picocli_picocli",
    ],
    visibility = ["//visibility:public"],
)

java_binary(
    name = "grammar-adapter",
    runtime_deps = [":grammar-adapter-lib"],
    main_class = "com.typedb.dependencies.builder.antlr.GrammarAdapterKt"
)

checkstyle_test(
    name = "checkstyle",
    include = glob(["*"]),
    license_type = "mpl-header",
    size = "small",
)
