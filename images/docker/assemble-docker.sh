#!/usr/bin/env bash
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

set -ex

# Usage: ./assemble-docker.sh Dockerfile.amd64 amd64 3.1.0 typedb ubuntu

DOCKERFILE=$(realpath $1)
PLATFORM=$2
TAG=$(cat $3)
DOCKER_ORG=$4
DOCKER_REPO=$5
FULL_TAG="${DOCKER_ORG}/${DOCKER_REPO}:${TAG}"
echo "Assembling image for ${PLATFORM}: ${FULL_TAG}"
docker buildx build --platform "linux/${PLATFORM}" --load -f $DOCKERFILE -t "${FULL_TAG}" .
echo "Successfully assembled ${FULL_TAG}"
