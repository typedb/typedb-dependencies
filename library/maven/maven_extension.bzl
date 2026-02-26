# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

load("@rules_jvm_external//:specs.bzl", "parse", _json = "json")
load("@rules_jvm_external//private/rules:coursier.bzl", "coursier_fetch")
load(":bzlmod_artifacts.bzl", "MAVEN_ARTIFACTS", "MAVEN_EXCLUDED_ARTIFACTS", "MAVEN_REPOSITORIES")

def _maven_impl(module_ctx):
    artifacts = parse.parse_artifact_spec_list(MAVEN_ARTIFACTS)
    artifacts_json = [_json.write_artifact_spec(a) for a in artifacts]

    excluded_artifacts = parse.parse_exclusion_spec_list(MAVEN_EXCLUDED_ARTIFACTS)
    excluded_artifacts_json = [_json.write_exclusion_spec(a) for a in excluded_artifacts]

    repositories = parse.parse_repository_spec_list(MAVEN_REPOSITORIES)
    repositories_json = [_json.write_repository_spec(r) for r in repositories]

    coursier_fetch(
        name = "maven",
        user_provided_name = "maven",
        artifacts = artifacts_json,
        excluded_artifacts = excluded_artifacts_json,
        repositories = repositories_json,
        strict_visibility = True,
        version_conflict_policy = "pinned",
    )

maven = module_extension(implementation = _maven_impl)
