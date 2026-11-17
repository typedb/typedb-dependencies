# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

"""Export the one canonical crate universe without generating consumer copies."""

_SHARED_BUILD = Label("@crates//:BUILD.bazel")

_MACROS = ["aliases", "all_crate_deps", "crate_deps", "crate_edition", "crate_repositories"]

def _export_registry_impl(ctx):
    shared = ctx.attr.registry_build

    # crate_universe exports static aliases in its public root BUILD. Forward
    # those labels instead of copying crate implementations or type identities.
    names = []
    for line in ctx.read(shared).splitlines():
        line = line.strip()
        if line.startswith("name = "):
            name = line.removeprefix("name = ").removesuffix(",").strip()
            if not (name.startswith('"') and name.endswith('"')):
                fail("Expected a static crate_universe export: " + line)
            names.append(json.decode(name))
    if not names:
        fail("The canonical crate registry has no exports")
    root = "@@" + shared.repo_name + "//:"
    ctx.file("BUILD.bazel", 'package(default_visibility = ["//visibility:public"])\n' + "\n".join([
        "alias(name = {}, actual = {})".format(json.encode(name), json.encode(root + name))
        for name in names
    ]))

    # Keep the existing macro API as well as the direct dependency labels.
    for filename in ["defs.bzl", "crates.bzl"]:
        ctx.file(filename, "load({}, {})\n{}\n".format(
            json.encode(root + filename),
            ", ".join(["_{} = {}".format(name, json.encode(name)) for name in _MACROS]),
            "\n".join(["{} = _{}".format(name, name) for name in _MACROS]),
        ))

_export_registry = repository_rule(
    implementation = _export_registry_impl,
    attrs = {"registry_build": attr.label(default = _SHARED_BUILD)},
)

def _typedb_crates_impl(module_ctx):
    _export_registry(name = "crates")

typedb_crates = module_extension(implementation = _typedb_crates_impl)
