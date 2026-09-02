#!/usr/bin/env bash
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# End-to-end check of the cargo sync tool against this test workspace:
#   1. flagless sync is idempotent and produces legacy-shaped output
#   2. build-script tags produce [package] build + [build-dependencies],
#      with the version sourced from the crate universe manifest
#   3. metadata flags produce [workspace.package], prefixed package names,
#      [lib] name pinning, and workspace-dependency package renames
#   4. both the flagless and the flagged workspace resolve (cargo metadata, which
#      resolves the full graph and writes Cargo.lock), and the flagged (renamed)
#      workspace compiles

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/../../.."

if ! command -v cargo >/dev/null && [ -z "${VERIFY_ALLOW_MISSING_CARGO:-}" ]; then
    echo "VERIFY FAILED: cargo is required (set VERIFY_ALLOW_MISSING_CARGO=1 to skip cargo validation)" >&2
    exit 1
fi
rm -f Cargo.lock

SYNC=(bazel run @typedb_dependencies//tool/ide:rust_sync -- @test_workspace_refs//:refs.json)
MANIFESTS=(Cargo.toml lib1/Cargo.toml lib2/Cargo.toml build-script-lib/Cargo.toml)

fail() { echo "VERIFY FAILED: $1" >&2; exit 1; }
assert_contains() { grep -qF -- "$2" "$1" || fail "$1 does not contain: $2"; }
assert_not_contains() { ! grep -qF -- "$2" "$1" || fail "$1 must not contain: $2"; }

echo "--- flagless sync (run 1) ---"
"${SYNC[@]}"
snapshot=$(mktemp -d)
for m in "${MANIFESTS[@]}"; do mkdir -p "$snapshot/$(dirname "$m")"; cp "$m" "$snapshot/$m"; done

echo "--- flagless sync (run 2): idempotence ---"
"${SYNC[@]}"
for m in "${MANIFESTS[@]}"; do diff -u "$snapshot/$m" "$m" || fail "sync is not idempotent: $m"; done
rm -r "$snapshot"

echo "--- flagless output invariants ---"
assert_contains Cargo.toml 'members = ["build-script-lib", "lib1", "lib2"]'
assert_not_contains Cargo.toml '[workspace.package]'
assert_contains lib1/Cargo.toml 'name = "lib1"'
[ "$(grep -oE '^\s+(edition|name|version) =' lib1/Cargo.toml | awk '{print $1}' | paste -sd,)" = "edition,name,version" ] \
    || fail "lib1 [package] keys are not emitted in sorted order"
assert_contains lib2/Cargo.toml '[dependencies.lib1]'
assert_contains build-script-lib/Cargo.toml 'build = "build.rs"'
assert_contains build-script-lib/Cargo.toml '[build-dependencies.tonic-build]'
# the version comes from the crate universe manifest (of the enclosing repo) via cargo_build_dep_tag()
UNIVERSE_VERSION=$(sed -n 's/^tonic-build = "\(.*\)"$/\1/p' ../../../library/crates/Cargo.toml)
[ -n "$UNIVERSE_VERSION" ] || fail "could not read tonic-build pin from library/crates/Cargo.toml"
assert_contains build-script-lib/Cargo.toml "version = \"^$UNIVERSE_VERSION\""
assert_contains build-script-lib/Cargo.toml 'path = "lib.rs"'
assert_not_contains build-script-lib/Cargo.toml 'build_script_lib_gen.rs'

if command -v cargo >/dev/null; then
    echo "--- cargo resolution of the flagless workspace ---"
    cargo metadata --format-version 1 >/dev/null
fi

echo "--- flagged sync ---"
VERSION_FILE=$(mktemp)
echo "1.2.3" > "$VERSION_FILE"
"${SYNC[@]}" --package-prefix typedb- --version-file "$VERSION_FILE" \
    --workspace-package-entry license=MPL-2.0 \
    --workspace-package-entry repository=https://github.com/typedb/typedb \
    --workspace-package-entry homepage=https://typedb.com
rm "$VERSION_FILE"
assert_contains Cargo.toml '[workspace.package]'
assert_contains Cargo.toml 'version = "1.2.3"'
assert_contains Cargo.toml 'license = "MPL-2.0"'
assert_contains Cargo.toml 'repository = "https://github.com/typedb/typedb"'
assert_contains Cargo.toml 'homepage = "https://typedb.com"'
assert_contains lib1/Cargo.toml 'name = "typedb-lib1"'
assert_contains build-script-lib/Cargo.toml 'name = "typedb-build-script-lib"'
grep -A3 '^\[lib\]' lib1/Cargo.toml | grep -qF 'name = "lib1"' || fail "lib1 [lib] name not pinned"
grep -A4 '\[workspace.dependencies.lib1\]' Cargo.toml | grep -qF 'package = "typedb-lib1"' || fail "workspace dep rename missing for lib1"
grep -A2 '\[package.version\]' lib1/Cargo.toml | grep -qF 'workspace = true' || fail "lib1 version not workspace-inherited"
grep -A2 '\[package.homepage\]' lib1/Cargo.toml | grep -qF 'workspace = true' || fail "lib1 homepage not workspace-inherited"

if command -v cargo >/dev/null; then
    echo "--- cargo resolution + compile of the flagged workspace ---"
    cargo metadata --format-version 1 >/dev/null
    cargo check -p typedb-lib1 -p typedb-lib2
else
    echo "--- VERIFY_ALLOW_MISSING_CARGO set; cargo validation skipped ---"
fi

echo "--- restore flagless output ---"
"${SYNC[@]}"
rm -f Cargo.lock

echo "VERIFY PASSED"
