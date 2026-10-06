#!/usr/bin/env bash
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.


# Script for regenerating BUILD files after Cargo.toml update

set -ex -o pipefail

# A dirty hack to declare CARGO_VERSION in a single place
CARGO_VERSION=$(sed -n 's/^RUST_VERSION = "\(.*\)"$/\1/p' "$(dirname "${BASH_SOURCE[0]}")/../../MODULE.bazel")
[ -n "$CARGO_VERSION" ] || { echo "RUST_VERSION is not declared in MODULE.bazel"; exit 1; }

# A cached cargo of another version is replaced: update.sh needs this one.
if [ -x cargo ] && [[ $(./cargo --version) == "cargo $CARGO_VERSION "* ]]; then
    exit 0
fi

arch=$(bash --version | head -n1 | grep -o '\S\+$')  # (arch-vendor-os)
arch=${arch#(} && arch=${arch%)} # strip parentheses
if [[ $arch == x86_64-apple-darwin* ]]; then
    target=x86_64-apple-darwin
elif [[ $arch == arm64-apple-darwin* ]]; then
    target=aarch64-apple-darwin
elif [[ $arch == x86_64-*-linux* ]]; then
    target=x86_64-unknown-linux-gnu
else
    echo "Unsupported architecture: $arch"
    exit 1
fi

curl -fsSL "https://static.rust-lang.org/dist/cargo-$CARGO_VERSION-$target.tar.xz" \
    | tar -xJ --strip-components=3 "cargo-$CARGO_VERSION-$target/cargo/bin/cargo"
chmod +x cargo
