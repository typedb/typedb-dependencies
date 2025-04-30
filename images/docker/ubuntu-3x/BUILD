# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
load("//tool/checkstyle:rules.bzl", "checkstyle_test")

# Same repository as 2.x images.
load("//images/docker/ubuntu-2x:deployment.bzl", deployment_docker = "deployment")

# Gen-rules to generate <VERSION>-<PLATFORM> as tag
genrule(
    name = "tag-amd64",
    srcs = [":VERSION"],
    outs = ["tag-amd64.txt"],
    cmd = "cat $(location :VERSION) | tr -d '\n' > $(location tag-amd64.txt) && echo \"-amd64\" >> $(location tag-amd64.txt)",
)
genrule(
    name = "tag-arm64",
    srcs = [":VERSION"],
    outs = ["tag-arm64.txt"],
    cmd = "cat $(location :VERSION) | tr -d '\n' > $(location tag-arm64.txt) && echo \"-arm64\" >> $(location tag-arm64.txt)",
)


sh_binary(
    name = "assemble-docker-amd64",
    srcs = ["//images/docker:assemble-docker.sh"],
    data = ["Dockerfile.amd64", "VERSION", "tag-amd64"],
    deps = [],
    args = ["$(location Dockerfile.amd64)", "amd64", "$(location :tag-amd64)", deployment_docker["docker.organisation"], deployment_docker["docker.repository"]]
)

sh_binary(
    name = "assemble-docker-arm64",
    srcs = ["//images/docker:assemble-docker.sh"],
    data = ["Dockerfile.arm64", "VERSION", "tag-arm64"],
    deps = [],
    args = ["$(location Dockerfile.arm64)", "arm64", "$(location :tag-arm64)", deployment_docker["docker.organisation"], deployment_docker["docker.repository"]]
)

sh_binary(
    name = "deploy-docker-amd64",
    deps = [],
    srcs = ["//images/docker:deploy-docker.sh"],
    data = ["VERSION", "tag-amd64"],
    args = ["$(location :tag-amd64)", deployment_docker["docker.organisation"], deployment_docker["docker.repository"]]
)

sh_binary(
    name = "deploy-docker-arm64",
    deps = [],
    srcs = ["//images/docker:deploy-docker.sh"],
    data = ["VERSION", "tag-arm64"],
    args = ["$(location :tag-arm64)", deployment_docker["docker.organisation"], deployment_docker["docker.repository"]]
)

checkstyle_test(
    name = "checkstyle",
    include = glob(["*"]),
    exclude = glob(["*.md", "VERSION"]),
    license_type = "mpl-header",
    size = "small",
)
