# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

load("@rules_rust//rust:defs.bzl", "rust_binary", "rust_test")
load("@typedb_dependencies//tool/checkstyle:rules.bzl", "checkstyle_test")

rust_binary(
    name = "first",
    srcs = ["first.rs"],
    deps = ["//lib1"],
)

rust_binary(
    name = "second",
    srcs = ["second.rs"],
    deps = ["//lib3"],
)

rust_test(
    name = "first_unit_tests",
    crate = ":first",
)

checkstyle_test(
    name = "checkstyle",
    include = glob(["*"]),
    exclude = ["Cargo.toml"],
    license_type = "mpl-header",
    size = "small",
)
