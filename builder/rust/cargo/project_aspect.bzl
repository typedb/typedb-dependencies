# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

load("@rules_rust//rust:defs.bzl", "rust_common")

_TARGET_TYPES = {
    "rust_library": "lib",
    "rust_shared_library": "lib",
    "rust_static_library": "lib",
    "rust_binary": "bin",
    "rust_proc_macro": "lib",
    "rust_test": "test",
    "cargo_build_script": "build",
}

_CRATE_TYPES = {
    "rust_library": "lib",
    "rust_shared_library": "cdylib",
    "rust_static_library": "staticlib",
    "rust_binary": "bin",
    "rust_proc_macro": "proc-macro",
    "rust_test": "test",
}

_BIN_ENTRY_POINT = "main.rs"
_LIB_ENTRY_POINT = "lib.rs"

_SYNC_TAGS = ["crate-name", "declared-features", "cargo-entry-point", "cargo-build-script", "cargo-build-dep"]

_SYNC_TAG_PREFIXES = [tag.partition("-")[0] + "-" for tag in _SYNC_TAGS]

CrateInfo = provider(fields = [
    "target_type",            # str: "lib", "bin", "test" or "build"
    "crate_name",             # str
    "workspace_name",         # str
    "crate_path",             # str
    "version",                # str
    "enabled_features",       # List[str]
    "features",               # List[str]
    "deps",                   # List[target]
    "transitive_deps",        # List[target]
    "cargo_entry_point",      # str | None
    "cargo_build_script",     # str | None
    "cargo_build_deps",       # Dict[str, struct(version, features)]: the build script's crates, from cargo-build-dep tags
])

CargoProjectInfo = provider(fields = [
    "manifest",         # File
    "sources",          # Map[relpath:str, File]
    "workspace_files",  # List[File]
])

def _rust_cargo_project_aspect_impl(target, ctx):
    if ctx.rule.kind not in _TARGET_TYPES.keys():
        # not a crate
        return []

    crate_info = _crate_info(ctx, target)
    if crate_info.target_type == "build":
        return [crate_info]
    sources = [f for src in getattr(ctx.rule.attr, "srcs", []) + getattr(ctx.rule.attr, "compile_data", []) for f in src.files.to_list()]
    properties_file = _build_cargo_properties_file(ctx, _get_properties(target, ctx, sources, crate_info))

    if _should_generate_cargo_project(ctx, target):
        cargo_project_info = _generate_cargo_project(ctx, target, crate_info, properties_file, sources)
        return [
            crate_info,
            cargo_project_info,
            OutputGroupInfo(
                rust_cargo_properties = depset([properties_file]),
                rust_cargo_project = depset(cargo_project_info.workspace_files),
            ),
        ]
    else:
        return [
            crate_info,
            OutputGroupInfo(rust_cargo_properties = depset([properties_file])),
        ]

rust_cargo_project_aspect = aspect(
    attr_aspects = ["deps", "proc_macro_deps", "crate"],
    implementation = _rust_cargo_project_aspect_impl,
    attrs = {
        "_manifest_writer" : attr.label(
            default = Label("@typedb_dependencies//builder/rust/cargo:manifest-writer"),
            executable = True,
            cfg = "exec",
        )
    }
)

# TODO: Consider merging with `rust_cargo_project_aspect`
# (isolate from `if _should_generate_cargo_project(ctx, target)`)
def _rust_cargo_properties_aspect_impl(target, ctx):
    if ctx.rule.kind not in _TARGET_TYPES.keys():
        # not a crate
        return []

    crate_info = _crate_info(ctx, target)
    if crate_info.target_type == "build":
        return [crate_info]
    sources = [f for src in getattr(ctx.rule.attr, "srcs", []) + getattr(ctx.rule.attr, "compile_data", []) for f in src.files.to_list()]
    properties_file = _build_cargo_properties_file(ctx, _get_properties(target, ctx, sources, crate_info))

    return [
        crate_info,
        OutputGroupInfo(rust_cargo_properties = depset([properties_file])),
    ]

rust_cargo_properties_aspect = aspect(
    attr_aspects = ["deps", "proc_macro_deps", "crate"],
    implementation = _rust_cargo_properties_aspect_impl,
    attrs = {
        "_manifest_writer" : attr.label(
            default = Label("@typedb_dependencies//builder/rust/cargo:manifest-writer"),
            executable = True,
            cfg = "exec",
        )
    }
)

def _parse_cargo_build_dep(value, target):
    name, _, spec = value.partition("@")
    version_and_features = spec.split("+")
    if not name or "" in version_and_features:
        fail("malformed cargo-build-dep tag '{}' on target '{}': expected <name>@<version>[+<feature>...]".format(value, target.label))
    return name, struct(version = version_and_features[0], features = version_and_features[1:])

def _crate_info(ctx, target):
    target_type = _target_type(ctx, target)
    features = []
    cargo_entry_point = None
    cargo_build_script = None
    cargo_build_deps = {}
    if _is_universe_crate(target):
        crate_name = target.label.name
        for tag in ctx.rule.attr.tags:
            tag_name, _, tag_value = tag.partition("=")
            if tag_name == "crate-name":
                crate_name = tag_value
    else:
        crate_name_attribute = getattr(ctx.rule.attr, "crate_name", "")
        crate_name = crate_name_attribute or ctx.rule.attr.name
        seen_tag_names = []
        for tag in ctx.rule.attr.tags:
            tag_name, _, tag_value = tag.partition("=")
            if tag_name not in _SYNC_TAGS:
                if any([tag_name.replace("_", "-").startswith(prefix) for prefix in _SYNC_TAG_PREFIXES]):
                    fail("unrecognized cargo sync tag '{}' on target '{}'".format(tag, target.label))
                continue
            if not tag_value:
                fail("malformed tag '{}' on target '{}': expected <name>=<value>".format(tag, target.label))
            if tag_name in seen_tag_names and tag_name != "cargo-build-dep":
                fail("repeated {} tag on target '{}'".format(tag_name, target.label))
            seen_tag_names.append(tag_name)
            if tag_name == "crate-name":
                if crate_name_attribute and tag_value.replace("-", "_") != crate_name_attribute:
                    fail("crate-name tag '{}' disagrees with crate_name '{}' on target '{}'".format(tag_value, crate_name_attribute, target.label))
                crate_name = tag_value
            elif tag_name == "declared-features":
                features = [f.strip() for f in tag_value.split(",") if f.strip()]
            elif tag_name == "cargo-entry-point":
                cargo_entry_point = tag_value
            elif tag_name == "cargo-build-script":
                cargo_build_script = tag_value
            elif tag_name == "cargo-build-dep":
                name, build_dep = _parse_cargo_build_dep(tag_value, target)
                if name in cargo_build_deps:
                    fail("duplicate cargo-build-dep tag for '{}' on target '{}'".format(name, target.label))
                cargo_build_deps[name] = build_dep
        if cargo_entry_point or cargo_build_script or cargo_build_deps:
            if target_type not in ["bin", "lib"]:
                fail("cargo sync tags are only supported on rust libraries and binaries, found on '{}'".format(target.label))
        if cargo_build_deps and not cargo_build_script:
            fail("cargo-build-dep tags declared without a cargo-build-script tag on target '{}'".format(target.label))
        if _rules_rust_build_script_deps(ctx):
            fail("rules_rust cargo_build_script dependencies are not supported on '{}': use the cargo-build-script and cargo-build-dep tags instead".format(target.label))

    workspace_name = target.label.workspace_name
    crate_path = target.label.package
    deps = _crate_deps(ctx, target)
    transitive_deps = _transitive_crate_deps(deps)

    return CrateInfo(
        target_type = target_type,
        crate_name = crate_name,
        workspace_name = workspace_name,
        crate_path = crate_path,
        version = getattr(ctx.rule.attr, "version", "0.0.0"),
        enabled_features = getattr(ctx.rule.attr, "crate_features", []),
        features = features,
        deps = deps,
        transitive_deps = transitive_deps,
        cargo_entry_point = cargo_entry_point,
        cargo_build_script = cargo_build_script,
        cargo_build_deps = cargo_build_deps,
    )

def _generate_cargo_project(ctx, target, crate_info, properties_file, sources):
    workspace_root = target.label.name + "-cargo-workspace"

    manifest_file = ctx.actions.declare_file(workspace_root + "/" + crate_info.crate_name + "/Cargo.toml")
    args = ["--properties", properties_file.path, "--output", manifest_file.path]
    ctx.actions.run(
        inputs = [properties_file],
        outputs = [manifest_file],
        executable = ctx.executable._manifest_writer,
        arguments = args,
    )

    project_sources = {}

    for src in sources:
        src_path = _src_relpath(target, ctx, src)
        dst = ctx.actions.declare_file(workspace_root + "/" + crate_info.crate_name + "/" + src_path)
        _copy_to_bin(ctx, src, dst)
        project_sources[src_path] = dst

    workspace_files = [manifest_file] + list(project_sources.values())

    for dep in crate_info.transitive_deps:
        if CargoProjectInfo in dep:
            dep_info = dep[CrateInfo]
            project_info = dep[CargoProjectInfo]
            dep_manifest = ctx.actions.declare_file(workspace_root + "/" + dep_info.crate_name + "/" + project_info.manifest.basename)
            workspace_files.append(dep_manifest)
            _copy_to_bin(ctx, project_info.manifest, dep_manifest)
            for path, file in project_info.sources.items():
                dst = ctx.actions.declare_file(workspace_root + "/" + dep_info.crate_name + "/" + path)
                _copy_to_bin(ctx, file, dst)
                workspace_files.append(dst)

    return CargoProjectInfo(
        manifest = manifest_file,
        sources = project_sources,
        workspace_files = workspace_files,
    )

def _transitive_crate_deps(deps):
    transitive_deps = deps[:]
    for dep in deps:
        if CrateInfo in dep:
            for tdep in dep[CrateInfo].transitive_deps:
                if tdep not in transitive_deps:
                    transitive_deps.append(tdep)
    return transitive_deps

def _crate_deps(ctx, target):
    return [dep for dep in _all_deps(ctx) if dep[CrateInfo].target_type in ["bin", "lib"]]

def _rules_rust_build_script_deps(ctx):
    return [dep for dep in _deps(ctx) if dep[CrateInfo].target_type == "build"]

def _deps(ctx):
    return [dep for dep in getattr(ctx.rule.attr, "deps", []) if CrateInfo in dep]

def _all_deps(ctx):
    return [
        dep for dep in
        _deps(ctx) + getattr(ctx.rule.attr, "proc_macro_deps", []) + ([ctx.rule.attr.crate] if hasattr(ctx.rule.attr, "crate") and ctx.rule.attr.crate else [])
        if CrateInfo in dep
    ]

def _copy_to_bin(ctx, src, dst):
    ctx.actions.run_shell(
        inputs = [src],
        outputs = [dst],
        command = "cp -f '{}' '{}'".format(src.path, dst.path),
    )

def _should_generate_cargo_project(ctx, target):
    label_str = str(target.label)
    if _is_universe_crate(target):
        return False
    is_local_or_typedb = (label_str.startswith("@typedb") or label_str.startswith("//")
        or label_str.startswith("@//") or label_str.startswith("@@//") or label_str.startswith("@@typedb"))
    return is_local_or_typedb and \
        ctx.rule.kind in _TARGET_TYPES and _TARGET_TYPES[ctx.rule.kind] in ["bin", "lib", "test"]

def _is_universe_crate(target):
    label_str = str(target.label)
    return (label_str.startswith("@crates__") or
            "crate+crates__" in label_str or
            label_str.startswith("@@crates//") or label_str.startswith("@crates//"))

def _build_cargo_properties_file(ctx, properties):
    properties_file = ctx.actions.declare_file("{}.cargo.properties".format(ctx.rule.attr.name))

    content = ""
    for prop in properties.items():
        content = content + ("{}: {}\n".format(prop[0], prop[1]))
    ctx.actions.write(
        output = properties_file,
        content = content
    )
    return properties_file

def _target_type(ctx, target):
    return "build" if ctx.rule.kind == "rust_binary" and _looks_like_rules_rust_build_script(target) else _TARGET_TYPES[ctx.rule.kind]

def _rules_rust_crate_info(target):
    # rules_rust wraps the CrateInfo of static and shared libraries for rust_test only
    if rust_common.crate_info in target:
        return target[rust_common.crate_info]
    return target[rust_common.test_crate_info].crate

def _get_properties(target, ctx, source_files, crate_info):
    target_type = crate_info.target_type

    properties = {}
    properties["name"] = crate_info.crate_name
    properties["path"] = crate_info.crate_path
    properties["enabled.features"] = ",".join(crate_info.enabled_features)
    properties["features"] = ",".join(crate_info.features)
    properties["target.name"] = target.label.name
    properties["crate_type"] = _CRATE_TYPES[ctx.rule.kind]
    properties["type"] = target_type
    properties["version"] = crate_info.version
    if target_type in ["bin", "lib"]:
        properties["edition"] = _rules_rust_crate_info(target).edition
        entry_point_file = _entry_point_file(target, ctx, source_files)
        properties["entry.point.path"] = _src_relpath(target, ctx, entry_point_file)
    if target_type == "test" and ctx.rule.attr.crate == None:
       entry_point_file = _entry_point_file(target, ctx, source_files)
       properties["entry.point.path"] = _src_relpath(target, ctx, entry_point_file)
    for dep in _crate_deps_info(target, crate_info).items():
        properties["deps." + dep[0]] = dep[1]
    if crate_info.cargo_entry_point != None:
        properties["cargo.entry.point.path"] = crate_info.cargo_entry_point
    if crate_info.cargo_build_script != None:
        properties["build.script"] = crate_info.cargo_build_script
    for name, build_dep in crate_info.cargo_build_deps.items():
        location = "version={}".format(build_dep.version)
        if build_dep.features:
            location += ";enabled.features={}".format(",".join(build_dep.features))
        properties["build.dep." + name] = location
    return properties

def _crate_deps_info(target, crate_info):
    deps_info = {}
    dep_labels = {}

    for dependency in crate_info.deps:
        dependency_info = dependency[CrateInfo]
        if dep_labels.setdefault(dependency_info.crate_name, dependency.label) != dependency.label:
            fail("target '{}' depends on two crates named '{}': '{}' and '{}'".format(
                target.label, dependency_info.crate_name, dep_labels[dependency_info.crate_name], dependency.label))
        if _is_universe_crate(dependency):
            location = "version={}".format(dependency_info.version)
        elif not _is_external_target(target) and _is_external_target(dependency):
            location = "path=../{};workspace_name={}".format(dependency_info.crate_name, dependency_info.workspace_name)
        else:
            root_to_dep = _package_path_from_root(dependency.label)
            location = "path=../{};repopath={}".format(dependency_info.crate_name, root_to_dep)

        enabled_features = ",".join(dependency_info.enabled_features)
        info = location + (";enabled.features={}".format(enabled_features) if enabled_features else "")
        deps_info[dependency_info.crate_name] = info
    return deps_info

def _is_external_target(target):
    return target.label.workspace_root.startswith("external/")

def _package_path_from_root(label):
    return label.package

def _looks_like_rules_rust_build_script(target):
    return str(target.label).endswith("_")

def _entry_point_file(target, ctx, source_files):
    if getattr(ctx.rule.attr, "crate_root", None):
        return ctx.rule.file.crate_root
    else:
        return _find_entry_point_in_sources(target, ctx, source_files)

def _find_entry_point_in_sources(target, ctx, source_files):
    if len(source_files) == 1:
        return source_files[0]

    standard_entry_point_name = _BIN_ENTRY_POINT if ctx.rule.kind == "rust_binary" else _LIB_ENTRY_POINT
    alternative_entry_point_name = "{}.rs".format(ctx.rule.attr.name)

    standard_entry_points = [f for f in source_files if f.basename == standard_entry_point_name]
    if len(standard_entry_points) == 1:
        return standard_entry_points[0]
    elif len(standard_entry_points) > 1:
        fail("cannot determine entry point for {} target '{}': multiple files named '{}' found in srcs, and no explicit crate_root".format(
            ctx.rule.kind, target.label.name, standard_entry_point_name
        ))

    alternative_entry_points = [f for f in source_files if f.basename == alternative_entry_point_name]
    if len(alternative_entry_points) == 1:
        return alternative_entry_points[0]
    elif len(alternative_entry_points) > 1:
        fail("cannot determine entry point for {} target '{}': multiple files named '{}' found in srcs, and no explicit crate_root".format(
            ctx.rule.kind, target.label.name, alternative_entry_point_name
        ))

    fail("cannot determine entry point for {} target '{}': no files named '{}' or '{}' found in srcs, and no explicit crate_root".format(
        ctx.rule.kind, target.label.name, standard_entry_point_name, alternative_entry_point_name
    ))

def _src_relpath(target, ctx, src):
    path = src.path

    if "external" in path:
        path = path[path.find("external"):].split("/", 2)[2]

    if "bazel-out" in path:
        path = path[path.find("bazel-out"):].split("/", 3)[3]

    if "/" in ctx.build_file_path:
        build_file_directory = ctx.build_file_path.rsplit("/", 1)[0] + "/"
        if not path.startswith(build_file_directory):
            fail("source file {} of the target '{}' is not located under the target path ({})".format(
                src.path, target.label.name, build_file_directory
            ))

        return path[len(build_file_directory):]
    else: # BUILD in root
        return path
