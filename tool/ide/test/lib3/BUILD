# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.


load("@rules_rust//rust:defs.bzl", "rust_library")
load("@typedb_dependencies//tool/checkstyle:rules.bzl", "checkstyle_test")

rust_library(
    name = "lib3",
    srcs = ["lib.rs"],
    deps = ["//lib1:lib1_extra"],
    visibility = ["//visibility:public"],
)

checkstyle_test(
    name = "checkstyle",
    include = glob(["*"]),
    exclude = ["Cargo.toml"],
    license_type = "mpl-header",
    size = "small",
)
