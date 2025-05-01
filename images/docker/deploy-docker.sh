#!/usr/bin/env bash
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

set -ex

# Usage: ./deploy-docker.sh amd64 3.1.0 typedb ubuntu

TAG=$(cat $1)
DOCKER_ORG=$2
DOCKER_REPO=$3
TAG="${DOCKER_ORG}/${DOCKER_REPO}:${TAG}"

echo "Deploying image: ${TAG}"
docker push "${TAG}"
echo "Successfully pushed ${TAG}"
