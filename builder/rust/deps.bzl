# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.


load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file", "http_archive")

def deps():
    http_archive(
        name = "rules_cc",
        urls = ["https://github.com/bazelbuild/rules_cc/releases/download/0.0.17/rules_cc-0.0.17.tar.gz"],
        sha256 = "abc605dd850f813bb37004b77db20106a19311a96b2da1c92b789da529d28fe1",
        strip_prefix = "rules_cc-0.0.17",
    )
    http_archive(
        name = "rules_rust",
        integrity = "sha256-8TBqrAsli3kN8BrZq8arsN8LZUFsdLTvJ/Sqsph4CmQ=",
        urls = ["https://github.com/bazelbuild/rules_rust/releases/download/0.56.0/rules_rust-0.56.0.tar.gz"],
    )
    http_file(
        name = "cxxbridge_linux",
        urls = [
            "https://repo.typedb.com/public/public-tools/raw/versions/1.0.55/cxxbridge-v1.0.55-linux"
        ],
        executable = True,
    )
    http_file(
        name = "cxxbridge_mac",
        urls = [
            "https://repo.typedb.com/public/public-tools/raw/versions/1.0.55/cxxbridge-v1.0.55-mac"
        ],
        executable = True,
    )
    http_file(
        name = "cxxbridge_windows",
        urls = [
            "https://repo.typedb.com/public/public-tools/raw/versions/1.0.55/cxxbridge-v1.0.55-windows.exe",
        ],
        executable = True,
    )
