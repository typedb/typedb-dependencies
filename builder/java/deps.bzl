# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# DEPRECATED: This file is for WORKSPACE mode only.
# New projects should use MODULE.bazel (Bzlmod) instead.
# These functions will be removed in a future release.

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_jar")

def rules_java():
    http_archive(
        name = "rules_java",
        urls = ["https://github.com/bazelbuild/rules_java/releases/download/7.11.1/rules_java-7.11.1.tar.gz"],
        sha256 = "6f3ce0e9fba979a844faba2d60467843fbf5191d8ca61fa3d2ea17655b56bb8c",
    )

def rules_jvm_external():
    RULES_JVM_EXTERNAL_TAG = "5.3"
    RULES_JVM_EXTERNAL_SHA = "d31e369b854322ca5098ea12c69d7175ded971435e55c18dd9dd5f29cc5249ac"

    http_archive(
        name = "rules_jvm_external",
        strip_prefix = "rules_jvm_external-%s" % RULES_JVM_EXTERNAL_TAG,
        sha256 = RULES_JVM_EXTERNAL_SHA,
        url = "https://github.com/bazelbuild/rules_jvm_external/releases/download/%s/rules_jvm_external-%s.tar.gz" % (RULES_JVM_EXTERNAL_TAG, RULES_JVM_EXTERNAL_TAG)
    )
