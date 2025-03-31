#!/usr/bin/env bash
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

set -ex

# Usage: ./deploy-docker.sh amd64 3.1.0 typedb ubuntu

PLATFORM=$1
DOCKER_VERSION=$2
DOCKER_ORG=$3
DOCKER_REPO=$4
TAG="${DOCKER_ORG}/${DOCKER_REPO}:${DOCKER_VERSION}-${PLATFORM}"

echo "Deploying image for ${PLATFORM}: ${TAG}"
docker push "${TAG}"
echo "Successfully pushed"
