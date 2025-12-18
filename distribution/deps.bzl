# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.


load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

def typedb_bazel_distribution():
    git_repository(
        name = "typedb_bazel_distribution",
        remote = "https://github.com/krishnangovindraj/bazel-distribution",
        commit = "e7fddda4d85398a61990fbe0a77f074453a503c4", # sync-marker: do not remove this comment, this is used for sync-dependencies by @typedb_bazel_distribution
    )
