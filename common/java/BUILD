# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.


exports_files(["VERSION"], visibility = ["//visibility:public"])
load("@typedb_bazel_distribution//maven:rules.bzl", "assemble_maven", "deploy_maven")
load("//distribution/maven:version.bzl", "version")
load("//library/maven:artifacts.bzl", "artifacts")
load("//tool/checkstyle:rules.bzl", "checkstyle_test")
load("//distribution:deployment.bzl", "deployment")

java_library(
    name = "typedb-common",
    srcs = glob([
        "collection/*.java",
        "concurrent/*.java",
        "concurrent/actor/*.java",
        "concurrent/actor/eventloop/*.java",
        "exception/*.java",
        "util/*.java",
        "yaml/*.java",
    ]),
    deps = [
        "@maven//:org_yaml_snakeyaml",
    ],
    visibility = ["//visibility:public"],
    tags = [
        "maven_coordinates=com.typedb:typedb-common:{pom_version}",
    ],
)

assemble_maven(
    name = "assemble-maven",
    target = ":typedb-common",
    workspace_refs = "@typedb_dependencies_workspace_refs//:refs.json",
    version_overrides = version(artifacts_org = artifacts, artifacts_repo={}),
    project_name = "TypeDB Common",
    project_description = "TypeDB Common classes and tools",
    project_url = "https://github.com/typedb/typedb-dependencies",
    scm_url = "https://github.com/typedb/typedb-dependencies",
)

deploy_maven(
    name = "deploy-maven",
    target = ":assemble-maven",
    snapshot = deployment['maven']['snapshot']['upload'],
    release = deployment['maven']['release']['upload']
)

checkstyle_test(
    name = "checkstyle",
    include = glob([
        "BUILD",
        "collection/*",
        "concurrent/*",
        "concurrent/actor/*.java",
        "concurrent/actor/eventloop/*.java",
        "exception/*",
        "util/*",
        "yaml/*.java"
    ]),
    license_type = "mpl-header",
)
