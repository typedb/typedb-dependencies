# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

load("//tool/checkstyle:rules.bzl", "checkstyle_test")

checkstyle_test(
    name = "checkstyle",
    include = glob(["*", ".factory/*"]),
    exclude = glob([
        "*.md",
        ".factory/validate_all_maven_includes.patch"
    ]) + [
        ".bazelversion",
        ".bazel-remote-cache.rc",
        ".bazel-cache-credential.json",
        ".git",
        "LICENSE",
        "MODULE.bazel.lock",
    ],
    license_type = "mpl-header",
    size = "small",
)
