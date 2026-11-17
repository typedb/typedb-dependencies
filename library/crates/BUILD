#!/usr/bin/env bash
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

load("//tool/checkstyle:rules.bzl", "checkstyle_test")

exports_files(["Cargo.toml", "Cargo.lock", "cargo-bazel-lock.json"])

checkstyle_test(
    name = "checkstyle",
    include = glob(["*"]),
    exclude = ["cargo", "Cargo.lock", "cargo-bazel-lock.json"],
    license_type = "mpl-header",
    size = "small",
)
