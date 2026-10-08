# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# Exposes the crate versions pinned in the crate universe manifest (library/crates/Cargo.toml)
# as loadable Starlark values, so BUILD files can reference a pin instead of duplicating it.

_DEPENDENCY_SECTIONS = ["[dependencies]", "[dev-dependencies]", "[build-dependencies]"]

def _parse_pin(spec, line):
    if spec.startswith("\"") and spec.endswith("\""):
        return struct(version = spec[1:-1], default_features = True)
    if not spec.startswith("{") or not spec.endswith("}"):
        fail("unsupported entry in crate universe manifest: {}".format(line))

    parts = spec.split("\"")
    syntax = "".join(parts[0::2]).replace(" ", "")
    if "package=" in syntax:
        fail("renamed dependency in crate universe manifest: {}".format(line))
    for i in range(1, len(parts), 2):
        if parts[i - 1].replace(" ", "").endswith("version="):
            return struct(version = parts[i], default_features = "default-features=false" not in syntax)
    fail("no version in crate universe manifest entry: {}".format(line))

def _crate_versions_repository_impl(repository_ctx):
    versions = {}
    without_default_features = []
    section = None
    for line in repository_ctx.read(repository_ctx.attr.manifest).splitlines():
        line = line.strip()
        if line.startswith("["):
            section = line
            if "dependencies" in section and section not in _DEPENDENCY_SECTIONS:
                fail("unsupported section in crate universe manifest: {}".format(section))
        elif section in _DEPENDENCY_SECTIONS and line and not line.startswith("#"):
            name, _, spec = line.partition("=")
            name = name.strip().strip("\"")
            pin = _parse_pin(spec.strip(), line)
            if versions.get(name, pin.version) != pin.version:
                fail("crate '{}' is pinned at two versions in the crate universe manifest".format(name))
            versions[name] = pin.version
            if not pin.default_features and name not in without_default_features:
                without_default_features.append(name)
    repository_ctx.file("BUILD", "")
    repository_ctx.file("versions.bzl", "CRATE_VERSIONS = {}\nCRATES_WITHOUT_DEFAULT_FEATURES = {}\n".format(
        str(versions),
        str(without_default_features),
    ))

crate_versions_repository = repository_rule(
    implementation = _crate_versions_repository_impl,
    attrs = {
        "manifest": attr.label(allow_single_file = True, mandatory = True),
    },
)

def _crate_versions_extension_impl(_module_ctx):
    crate_versions_repository(
        name = "crate_versions",
        manifest = Label("//library/crates:Cargo.toml"),
    )

crate_versions_extension = module_extension(implementation = _crate_versions_extension_impl)
