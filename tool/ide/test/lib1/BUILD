# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.


load("@rules_rust//rust:defs.bzl", "rust_binary", "rust_library", "rust_test")
load("@typedb_dependencies//tool/checkstyle:rules.bzl", "checkstyle_test")

rust_library(
    name = "lib1",
    srcs = ["lib.rs"],
    deps = ["//lib0:lib0_alpha"],
    tags = ["declared-features=extra"],
    visibility = ["//visibility:public"],
)

rust_library(
    name = "lib1_extra",
    crate_name = "lib1",
    srcs = ["lib.rs"],
    crate_features = ["extra"],
    deps = ["//lib0:lib0_alpha"],
    tags = ["crate-name=lib1", "declared-features=extra"],
    visibility = ["//visibility:public"],
)

rust_binary(
    name = "lib1_bin",
    srcs = ["main.rs"],
    deps = ["//lib0:lib0_beta"],
)

rust_test(
    name = "lib1_unit_tests",
    crate = ":lib1",
    deps = ["//lib2"],
)

checkstyle_test(
    name = "checkstyle",
    include = glob(["*"]),
    exclude = ["Cargo.toml"],
    license_type = "mpl-header",
    size = "small",
)
