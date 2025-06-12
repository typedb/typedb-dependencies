# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.


load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def deps():
    zlib()
    rules_proto_grpc()
    com_github_grpc_grpc()

def zlib():
    # Apple Clang 17 (recent MacOS versions) is not compatible with the old zlib
    # used in the grpc libraries below. Since we are not able to update the grpc
    # libs (it requires Bazel modules), we have to use a newer zlib manually.
    http_archive(
        name = "zlib",
        urls = ["https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.gz"],
        strip_prefix = "zlib-1.3.1",
        sha256 = "9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23",
        build_file_content = """
cc_library(
    name = "zlib",
    srcs = glob(["*.c"]),
    hdrs = glob(["*.h"]),
    includes = ["."],
    copts = ["-include", "unistd.h"],
    visibility = ["//visibility:public"],
)
""",
    )

def rules_proto_grpc():
    git_repository(
       name = "rules_proto_grpc",
       remote = "https://github.com/rules-proto-grpc/rules_proto_grpc",
       commit = "7064b28a75b3feb014b20d3276e17498987a68e2"
    )

def com_github_grpc_grpc():
    http_archive(
        name = "com_github_grpc_grpc",
        sha256 = "79e3ff93f7fa3c8433e2165f2550fa14889fce147c15d9828531cbfc7ad11e01",
        strip_prefix = "grpc-1.54.1",
        urls = ["https://github.com/grpc/grpc/archive/v1.54.1.tar.gz"],
    )
