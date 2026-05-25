# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

package(default_visibility = ["//visibility:public"])

load("@io_bazel_rules_kotlin//kotlin:core.bzl", "kt_compiler_plugin")
load("//tool/checkstyle:rules.bzl", "checkstyle_test")

kt_compiler_plugin(
    name = "compiler_plugin",
    id = "jetbrains.compose.compiler",
    target_embedded_compiler = True,
    deps = [
        "@typedb_maven//:org_jetbrains_compose_compiler_compiler",
    ],
     visibility = ["//visibility:public"],
)

checkstyle_test(
    name = "checkstyle",
    include = glob(["*"]),
    license_type = "mpl-header",
    size = "small",
)
