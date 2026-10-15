# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

load("@rules_rust//rust:defs.bzl", "rust_library")
load("@typedb_dependencies//tool/checkstyle:rules.bzl", "checkstyle_test")

rust_library(
    name = "lib0_alpha",
    crate_name = "lib0",
    srcs = ["lib.rs"],
    crate_features = ["alpha"],
    tags = ["crate-name=lib0", "declared-features=alpha,beta"],
    visibility = ["//visibility:public"],
)

rust_library(
    name = "lib0_beta",
    crate_name = "lib0",
    srcs = ["lib.rs"],
    crate_features = ["beta"],
    tags = ["crate-name=lib0", "declared-features=alpha,beta"],
    visibility = ["//visibility:public"],
)

checkstyle_test(
    name = "checkstyle",
    include = glob(["*"]),
    exclude = ["Cargo.toml"],
    license_type = "mpl-header",
    size = "small",
)
