# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# Exposes the crate pins (version, features, default-features) of the crate universe manifest
# (library/crates/Cargo.toml) as loadable Starlark values, so BUILD files can reference a pin
# instead of duplicating it. An entry this parser does not support is recorded as an error for its crate
# alone, so only BUILD files that request that crate fail.

_DEPENDENCY_TABLES = ["dependencies", "dev-dependencies", "build-dependencies"]

_PIN_KEYS = ["version", "features", "default-features"]

def _parse_pin(spec, line):
    if spec.startswith("\"") and spec.endswith("\""):
        return {"version": spec[1:-1], "features": [], "default_features": True}
    if not spec.startswith("{") or not spec.endswith("}"):
        return _unsupported("expected a version string or a one-line inline table", line)

    parts = spec.split("\"")
    syntax = "".join(parts[0::2]).replace(" ", "")
    for key in [entry.partition("=")[0] for entry in syntax.strip("{}").split(",") if "=" in entry]:
        if key not in _PIN_KEYS:
            return _unsupported("unsupported key '{}'".format(key), line)
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
        return _unsupported("no version", line)
    return {"version": version, "features": features, "default_features": "default-features=false" not in syntax}

def _unsupported(reason, line):
    return {"error": "{} in crate universe manifest entry: {}".format(reason, line)}

def _without_comment(line):
    parts = line.split("\"")
    for i in range(0, len(parts), 2):
        if "#" in parts[i]:
            return "\"".join(parts[:i] + [parts[i].partition("#")[0]]).strip()
    return line

def _merge_pins(pin, other):
    if "error" in pin:
        return pin
    if "error" in other:
        return other
    if pin["version"] != other["version"]:
        return {"error": "pinned at two versions in the crate universe manifest: {} and {}".format(pin["version"], other["version"])}
    return {
        "version": pin["version"],
        "features": pin["features"] + [f for f in other["features"] if f not in pin["features"]],
        "default_features": pin["default_features"] or other["default_features"],
    }

def _add_pin(pins, name, pin):
    pins[name] = _merge_pins(pins[name], pin) if name in pins else pin

def _crate_pins_repository_impl(repository_ctx):
    pins = {}
    section = ""
    continued = False
    for line in repository_ctx.read(repository_ctx.attr.manifest).splitlines():
        line = _without_comment(line.strip())
        if continued:
            continued = not line.endswith("}")
        elif line.startswith("["):
            section = line
            table, dot, crate = section.strip("[]").partition(".")
            if table in _DEPENDENCY_TABLES and dot:
                _add_pin(pins, crate.strip("\""), _unsupported("unsupported table section", section))
        elif line and section.endswith("dependencies]"):
            key, _, spec = line.partition("=")
            name, dot, _ = key.strip().strip("\"").partition(".")
            spec = spec.strip()
            continued = spec.startswith("{") and not spec.endswith("}")
            if section.strip("[]") not in _DEPENDENCY_TABLES:
                pin = _unsupported("unsupported section " + section, line)
            elif dot:
                pin = _unsupported("unsupported dotted key", line)
            else:
                pin = _parse_pin(spec, line)
            _add_pin(pins, name, pin)
    repository_ctx.file("BUILD", "")
    repository_ctx.file("pins.bzl", "CRATE_PINS = {}\n".format(str(pins)))

crate_pins_repository = repository_rule(
    implementation = _crate_pins_repository_impl,
    attrs = {
        "manifest": attr.label(allow_single_file = True, mandatory = True),
    },
)

def fetch_crate_pins():
    crate_pins_repository(
        name = "crate_pins",
        manifest = Label("//library/crates:Cargo.toml"),
    )

def _crate_pins_extension_impl(_module_ctx):
    fetch_crate_pins()

crate_pins_extension = module_extension(implementation = _crate_pins_extension_impl)
