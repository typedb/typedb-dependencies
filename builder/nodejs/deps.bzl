# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//builder/aspect:deps.bzl", "aspect_bazel_lib")

def deps(patch = []):
    aspect_bazel_lib()

    http_archive(
        name = "aspect_rules_js",
        sha256 = "e3e6c3d42491e2938f4239a3d04259a58adc83e21e352346ad4ef62f87e76125",
        strip_prefix = "rules_js-1.30.0",
        url = "https://github.com/aspect-build/rules_js/releases/download/v1.30.0/rules_js-v1.30.0.tar.gz",
    )

    http_archive(
        name = "aspect_rules_ts",
        sha256 = "97a8246bf6d1c7077b296e90a6e307bf8eabed02c5bca84d46db81efbf6ead41",
        strip_prefix = "rules_ts-2.4.0",
        url = "https://github.com/aspect-build/rules_ts/releases/download/v2.4.0/rules_ts-v2.4.0.tar.gz",
    )
