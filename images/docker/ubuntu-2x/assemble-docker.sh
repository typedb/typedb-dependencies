#!/usr/bin/env bash
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.


set -ex

DOCKER_VERSION_LIB=$2
DOCKER_VERSION=`$DOCKER_VERSION_LIB`
DOCKER_ORG=$3
DOCKER_REPO=$4

docker build -f $1 -t $DOCKER_ORG/$DOCKER_REPO:$DOCKER_VERSION .


docker buildx build --platform linux/amd64 --load -f Dockerfile.amd64 -t typedb/ubuntu:3.1.0b-amd64 .
