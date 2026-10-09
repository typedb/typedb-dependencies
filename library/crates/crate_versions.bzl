# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# Exposes the crate pins (version, features, default-features) of the crate universe manifest
# (library/crates/Cargo.toml) as loadable Starlark values, so BUILD files can reference a pin
# instead of duplicating it.

_DEPENDENCY_SECTIONS = ["[dependencies]", "[dev-dependencies]", "[build-dependencies]"]

def _parse_pin(spec, line):
    if spec.startswith("\"") and spec.endswith("\""):
        return {"version": spec[1:-1], "features": [], "default_features": True}
    if not spec.startswith("{") or not spec.endswith("}"):
        fail("unsupported entry in crate universe manifest, expected a version string or a one-line inline table: {}".format(line))

    parts = spec.split("\"")
    syntax = "".join(parts[0::2]).replace(" ", "")
    if "package=" in syntax:
        fail("renamed dependency in crate universe manifest: {}".format(line))
    version = None
    features = []
    in_features = False
    for i in range(1, len(parts), 2):
        before = parts[i - 1].replace(" ", "")
        if before.endswith("version="):
            version = parts[i]
        in_features = before.endswith("features=[") or (in_features and before == ",")
        if in_features:
            features.append(parts[i])
    if not version:
        fail("no version in crate universe manifest entry: {}".format(line))
    return {"version": version, "features": features, "default_features": "default-features=false" not in syntax}

def _without_comment(line):
    parts = line.split("\"")
    for i in range(0, len(parts), 2):
        if "#" in parts[i]:
            return "\"".join(parts[:i] + [parts[i].partition("#")[0]]).strip()
    return line

def _merge_pins(name, pin, other):
    if pin["version"] != other["version"]:
        fail("crate '{}' is pinned at two versions in the crate universe manifest".format(name))
    return {
        "version": pin["version"],
        "features": pin["features"] + [f for f in other["features"] if f not in pin["features"]],
        "default_features": pin["default_features"] or other["default_features"],
    }

def _crate_versions_repository_impl(repository_ctx):
    pins = {}
    section = None
    for line in repository_ctx.read(repository_ctx.attr.manifest).splitlines():
        line = _without_comment(line.strip())
        if line.startswith("["):
            section = line
            if "dependencies" in section and section not in _DEPENDENCY_SECTIONS:
                fail("unsupported section in crate universe manifest: {}".format(section))
        elif section in _DEPENDENCY_SECTIONS and line:
            name, _, spec = line.partition("=")
            name = name.strip().strip("\"")
            pin = _parse_pin(spec.strip(), line)
            if name in pins:
                pin = _merge_pins(name, pins[name], pin)
            pins[name] = pin
    repository_ctx.file("BUILD", "")
    repository_ctx.file("versions.bzl", "CRATE_PINS = {}\n".format(str(pins)))

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
