# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.


load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

def vaticle_bazel_distribution():
#    git_repository(
#        name = "vaticle_bazel_distribution",
#        remote = "https://github.com/vaticle/bazel-distribution",
#        commit = "c473d17530dff5a4398d2de9c9fe966df9aca4ce" # sync-marker: do not remove this comment, this is used for sync-dependencies by @vaticle_bazel_distribution
#    ) # TODO: Reference /vaticle after the PR is merged.
    git_repository(
        name = "vaticle_bazel_distribution",
        remote = "https://github.com/farost/bazel-distribution",
        commit = "542a6f04950f0292f6d1d81641ae50425f1de9cf" # sync-marker: do not remove this comment, this is used for sync-dependencies by @vaticle_bazel_distribution
    )
