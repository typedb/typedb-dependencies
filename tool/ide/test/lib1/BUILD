# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.


load("@rules_rust//rust:defs.bzl", "rust_library", "rust_test")
load("@typedb_dependencies//tool/checkstyle:rules.bzl", "checkstyle_test")

rust_library(
    name = "lib1",
    srcs = ["lib.rs"],
)

rust_test(
    name = "lib1_unit_tests",
    crate = ":lib1",
)

checkstyle_test(
    name = "checkstyle",
    include = glob(["*"]),
    license_type = "mpl-header",
    size = "small",
)
