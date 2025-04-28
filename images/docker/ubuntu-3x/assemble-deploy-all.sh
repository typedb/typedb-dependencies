#!/usr/bin/env bash
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

set -ex

# Usage: ./assemble-deploy-all.sh

VERSION_FILE="./VERSION"

if [[ ! -f "${VERSION_FILE}" ]]; then
  echo "VERSION file not found"
  exit 1
fi

VERSION=$(<"$VERSION_FILE")
VERSION=$(echo "$VERSION" | tr -d '[:space:]')

if [[ -z "$VERSION" ]]; then
  echo "VERSION file is invalid"
  exit 1
fi

echo "Preparing images for version ${VERSION}"

DOCKER_ORG=typedb
DOCKER_REPO=ubuntu
PLATFORMS=("amd64" "arm64") # Update `docker manifest` commands below if it's changed

for ARCH in "${PLATFORMS[@]}"; do
  # Should we just invoke the bazel targets here instead?
  ASSEMBLE_TARGET="//images/docker/ubuntu-3x:assemble-docker-${ARCH}"
  DEPLOY_TARGET="//images/docker/ubuntu-3x:deploy-docker-${ARCH}"
  bazel run $ASSEMBLE_TARGET
  bazel run $DEPLOY_TARGET
done

TAG="${DOCKER_ORG}/${DOCKER_REPO}:${VERSION}"
echo "Creating ${TAG} multi-arch manifest"
docker manifest create "${TAG}" \
  --amend "${TAG}-amd64" \
  --amend "${TAG}-arm64"
docker manifest push "${TAG}"

echo "Success"
