# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

load("@rules_jvm_external//:specs.bzl", "parse", _json = "json")
load("@rules_jvm_external//private/rules:coursier.bzl", "coursier_fetch")
load(":bzlmod_artifacts.bzl", "MAVEN_ARTIFACTS", "MAVEN_EXCLUDED_ARTIFACTS", "MAVEN_REPOSITORIES")

_maven_namespace_tag = tag_class(attrs = {
    "name": attr.string(default = "typedb_maven"),
    "artifacts": attr.string_list(),
})

def _build_artifacts_dict():
    d = {}
    for artifact in MAVEN_ARTIFACTS:
        if type(artifact) == type(""):
            parts = artifact.split(":")
            key = parts[0] + ":" + parts[1]
        else:
            key = artifact["group"] + ":" + artifact["artifact"]
        d[key] = artifact
    return d

def _maven_impl(module_ctx):
    artifacts_dict = _build_artifacts_dict()
    resolved_by_name = {}
    for mod in module_ctx.modules:
        for tag in mod.tags.namespace:
            name = tag.name
            for a in tag.artifacts:
                if name not in resolved_by_name:
                    resolved_by_name[name] = []
                if a not in artifacts_dict:
                    fail("'{}' has not been declared in @typedb_dependencies//library/maven:bzlmod_artifacts.bzl".format(a))
                resolved_by_name[name].append(artifacts_dict[a])

    if not resolved_by_name:
        resolved_by_name["typedb_maven"] = MAVEN_ARTIFACTS

    excluded_artifacts = parse.parse_exclusion_spec_list(MAVEN_EXCLUDED_ARTIFACTS)
    excluded_artifacts_json = [_json.write_exclusion_spec(a) for a in excluded_artifacts]

    repositories = parse.parse_repository_spec_list(MAVEN_REPOSITORIES)
    repositories_json = [_json.write_repository_spec(r) for r in repositories]

    for name, resolved in resolved_by_name.items():
        artifacts = parse.parse_artifact_spec_list(resolved)
        artifacts_json = [_json.write_artifact_spec(a) for a in artifacts]

        coursier_fetch(
            name = name,
            user_provided_name = name,
            artifacts = artifacts_json,
            excluded_artifacts = excluded_artifacts_json,
            repositories = repositories_json,
            strict_visibility = True,
            version_conflict_policy = "pinned",
        )

# Usage in MODULE.bazel:
#
#   maven = use_extension("@typedb_dependencies//library/maven:maven_extension.bzl", "maven")
#   maven.namespace(name = "typedb_maven", artifacts = ["io.grpc:grpc-api", "com.google.guava:guava"])
#   use_repo(maven, "maven")
#
# Multiple maven.artifacts(...) calls are merged. Omitting all tags includes everything
# from bzlmod_artifacts.bzl.
maven = module_extension(
    implementation = _maven_impl,
    tag_classes = {"namespace": _maven_namespace_tag},
)
