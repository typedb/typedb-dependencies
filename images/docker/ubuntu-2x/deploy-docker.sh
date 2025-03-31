#!/usr/bin/env bash
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.


set -ex

DOCKER_VERSION_LIB=$1
DOCKER_VERSION=`$DOCKER_VERSION_LIB`
DOCKER_ORG=$2
DOCKER_REPO=$3

docker push $DOCKER_ORG/$DOCKER_REPO:$DOCKER_VERSION
