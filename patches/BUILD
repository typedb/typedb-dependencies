# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

load("//tool/checkstyle:rules.bzl", "checkstyle_test")

exports_files(["rules_rust.patch", "protobuf-build-bazel-include.patch"])

checkstyle_test(
    name = "checkstyle",
    include = [":BUILD"],
    exclude = glob(["*.patch"]),
    license_type = "mpl-header",
    size = "small",
)

