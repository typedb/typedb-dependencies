# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.


load("@typedb_bazel_distribution//artifact:rules.bzl", "artifact_file")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")

public_artifact_sources = struct(
    release  = "https://repo.typedb.com/public/public-release/raw/",
    snapshot = "https://repo.typedb.com/public/public-snapshot/raw/",
)
private_artifact_sources = struct(
    release  = "https://repo.typedb.com/basic/private-release/raw/",
    snapshot = "https://repo.typedb.com/basic/private-snapshot/raw/",
)

platform_extension = {
    "linux-arm64": "tar.gz",
    "linux-x86_64": "tar.gz",
    "mac-arm64": "zip",
    "mac-x86_64": "zip",
    "windows-x86_64": "zip",
}

def artifact_repackage(name, srcs, files_to_keep):
    native.genrule(
        name = name,
        outs = ["{}.tar.gz".format(name)],
        srcs = srcs,
        cmd = "$(location @typedb_dependencies//distribution/artifact:artifact-repackage) $< $@ {}".format(
            "|".join(files_to_keep)
        ),
        tools = ["@typedb_dependencies//distribution/artifact:artifact-repackage"]
    )

def _native_artifact_files_impl(ctx):
    for mod in ctx.modules:
        for artifact in mod.tags.artifact:
              for platform, ext in platform_extension.items():
                    target_name = artifact.name + "_" + platform
                    group_name = artifact.group_name.replace("{platform}", platform).replace("{ext}", ext)
                    # Can't use .format() because the result string will still have the unresolved parameter {version}
                    artifact_name = artifact.artifact_name.replace("{platform}", platform).replace("{ext}", ext)

                    version = artifact.tag if artifact.tag else artifact.commit
                    if artifact.private == True:
                        repository_url = private_artifact_sources.release if artifact.tag else private_artifact_sources.snapshot
                    else:
                        repository_url = public_artifact_sources.release if artifact.tag else public_artifact_sources.snapshot
                    artifact_name = artifact_name.format(version = version)
                    http_file(
                        name = target_name,
                        urls = ["{}/names/{}/versions/{}/{}".format(repository_url.rstrip("/"), group_name, version, artifact_name)],
                        downloaded_file_path = artifact_name,
                    )

_artifact_tag = tag_class(
    attrs = {
        "name": attr.string(
            mandatory = True,
            doc       = "Base name for the generated repos.",
        ),
        "group_name": attr.string(
            mandatory = True,
            doc       = "Group path template, may contain {platform}.",
        ),
        "artifact_name": attr.string(
            mandatory = True,
            doc       = "Filename template, may contain {platform}, {version}, {ext}.",
        ),
        "tag": attr.string(
            default = "",
            doc     = "Version tag to use when resolving release URLs.",
        ),
        "commit": attr.string(
            default = "",
            doc     = "Commit SHA to use when resolving snapshot URLs.",
        ),
        "private": attr.bool(
            default = False,
            doc     = "Load the artifact from a private repository",
        ),
    },
)

native_artifact_files = module_extension(
    implementation = _native_artifact_files_impl,
    tag_classes    = {"artifact": _artifact_tag},
)
