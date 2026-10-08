# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

load("@crate_versions//:versions.bzl", "CRATE_PINS")

# Returns a "cargo-build-dep=<name>@<version>[+feature...]" tag for the cargo sync tool, with the version
# and features pinned in this repo's crate universe (library/crates/Cargo.toml), which the Bazel side builds with.
#
# Bzlmod consumers get @crate_versions automatically; WORKSPACE-mode consumers must
# instantiate it themselves (see this repo's WORKSPACE).
def cargo_build_dep_tag(crate):
    if crate not in CRATE_PINS:
        fail("crate '{}' is not pinned in the typedb-dependencies crate universe (library/crates/Cargo.toml)".format(crate))
    pin = CRATE_PINS[crate]
    if not pin["default_features"]:
        fail("crate '{}' disables default features in the crate universe, but cargo-build-dep tags keep them".format(crate))
    return "cargo-build-dep={}@{}".format(crate, "+".join([pin["version"]] + pin["features"]))
