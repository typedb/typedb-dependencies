# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

load("@crate_versions//:versions.bzl", "CRATE_VERSIONS")

# Returns a cargo-build-dep tag for the cargo sync tool, version-pinned to this repo's
# crate universe entry (library/crates/Cargo.toml) so the Bazel-side and cargo-side
# versions of the crate cannot drift apart. This repo's pin is authoritative for
# consumers too: the Bazel-side codegen (e.g. the rust_tonic_compile helper binary)
# is built from this universe, regardless of what the consumer's own universe pins.
#
# WORKSPACE-mode consumers must instantiate the @crate_versions repository themselves
# (see this repo's WORKSPACE for the crate_versions_repository(...) block); Bzlmod
# consumers get it automatically through this module.
def cargo_build_dep_tag(crate):
    if crate not in CRATE_VERSIONS:
        fail("crate '{}' is not pinned in the typedb-dependencies crate universe (library/crates/Cargo.toml)".format(crate))
    return "cargo-build-dep={}@^{}".format(crate, CRATE_VERSIONS[crate])
