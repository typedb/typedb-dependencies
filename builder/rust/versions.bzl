# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

load("@rules_rust//rust:repositories.bzl", "rust_register_toolchains", "rust_analyzer_toolchain_tools_repository")

RUST_VERSION_TYPEDB = "1.84.0"
def rust_toolchain_versioned():
    rust_register_toolchains(
        edition = "2021",
        extra_target_triples = [
            "aarch64-apple-darwin",
            "aarch64-unknown-linux-gnu",
            "x86_64-apple-darwin",
            "x86_64-pc-windows-msvc",
            "x86_64-unknown-linux-gnu",
        ],
        rust_analyzer_version = RUST_VERSION_TYPEDB,
        versions = [RUST_VERSION_TYPEDB],
    )
    rust_analyzer_toolchain_tools_repository(
        name = "rust_analyzer_toolchain_tools",
        version = RUST_VERSION_TYPEDB,
    )
