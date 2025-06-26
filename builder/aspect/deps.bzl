# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# This macro ensures a consistent version of the aspect_bazel_lib dependency across multiple deps (csharp, nodejs) used in this repo.
#
# To prevent conflicts arising from different versions of aspect_bazel_lib expected by these rules,
# always call this macro before loading any of the mentioned rules' dependencies. This guarantees that the version
# specified here is used universally.
#
# Ideally, the version of aspect_bazel_lib should be the maximum among the versions required by its dependents.
# This approach assumes that aspect_bazel_lib maintains backward compatibility.
def aspect_bazel_lib():
    http_archive(
        name = "aspect_bazel_lib",
        sha256 = "04feedcd06f71d0497a81fdd3220140a373ff9d2bff94620fbd50b774f96d8e0",
        strip_prefix = "bazel-lib-1.40.2",
        url = "https://github.com/aspect-build/bazel-lib/releases/download/v1.40.2/bazel-lib-v1.40.2.tar.gz",
    )
