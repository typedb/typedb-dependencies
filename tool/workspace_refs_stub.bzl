# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

"""
Workspace refs stub for Bzlmod compatibility.

In WORKSPACE mode, workspace_refs extracts commit/tag info from existing_rules().
In Bzlmod, that mechanism doesn't exist, so we provide an empty refs.json stub.
The maven deploy rules will still work, just without dependency version info embedded.
"""

def _workspace_refs_stub_impl(repository_ctx):
    repository_ctx.file("BUILD", content = 'exports_files(["refs.json"])', executable = False)
    refs_json = '{"commits": {}, "tags": {}}'
    repository_ctx.file("refs.json", content = refs_json, executable = False)

workspace_refs_stub = repository_rule(
    implementation = _workspace_refs_stub_impl,
    attrs = {},
    doc = "Creates a stub workspace_refs repository with empty refs.json for Bzlmod compatibility.",
)
