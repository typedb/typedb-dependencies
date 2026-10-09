#!/usr/bin/env bash
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

set -euo pipefail
cd "$(dirname "$0")/../../.."

bazel run @typedb_dependencies//tool/ide:rust_sync -- "$@" @test_workspace_refs//:refs.json
