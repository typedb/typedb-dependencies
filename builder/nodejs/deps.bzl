# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//builder/aspect:deps.bzl", "aspect_bazel_lib")

def deps(patch = []):
    aspect_bazel_lib()

    http_archive(
        name = "aspect_rules_ts",
        sha256 = "d23ba2b800493a83c3ec9e300e01c74a7b0a58c08893e681417e2c2f48f8c4bb",
        strip_prefix = "rules_ts-3.2.0",
        url = "https://github.com/aspect-build/rules_ts/releases/download/v3.2.0/rules_ts-v3.2.0.tar.gz",
    )
