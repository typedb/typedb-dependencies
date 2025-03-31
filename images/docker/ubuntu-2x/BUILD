# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.


load("//images/docker/ubuntu-2x:deployment.bzl", deployment_docker = "deployment")
load("//tool/checkstyle:rules.bzl", "checkstyle_test")

sh_library(
    name = "version-docker",
    srcs = ["version-docker.sh"],
)

sh_binary(
    name = "assemble-docker",
    srcs = ["assemble-docker.sh"],
    data = ["Dockerfile"],
    deps = [":version-docker"],
    args = ["$(location Dockerfile)", "$(location :version-docker)", deployment_docker["docker.organisation"], deployment_docker["docker.repository"]]
)

sh_binary(
    name = "deploy-docker",
    deps = [":version-docker"],
    srcs = ["deploy-docker.sh"],
    args = ["$(location :version-docker)", deployment_docker["docker.organisation"], deployment_docker["docker.repository"]]
)

checkstyle_test(
    name = "checkstyle",
    include = glob(["*"]),
    exclude = glob(["*.md"]),
    license_type = "mpl-header",
    size = "small",
)
