# Bazel 8 Upgrade - Work in Progress

## Overview

Upgrading `bazel-distribution` and `dependencies` repositories from Bazel 6.2.0 to Bazel 8.0.0.

**Branch:** `bazel-8-upgrade`
**Status:** Blocked on Java toolchain compatibility

## Completed Changes

### Core Bazel 8 Compatibility (DONE)

Both repositories have these changes applied:

1. **`.bazelrc`** - Added `common --enable_workspace=true` (required because Bazel 8 disables WORKSPACE by default)
2. **`.bazelversion`** - Updated from `6.2.0` to `8.0.0`
3. **`cfg = "host"` → `cfg = "exec"`** - Updated in all .bzl files (deprecated in Bazel 8)
4. **Removed `output_to_genfiles = True`** - Removed from bazel-distribution (attribute removed in Bazel 8)

### Dependency Updates (DONE)

| Dependency | Old Version | New Version | Notes |
|------------|-------------|-------------|-------|
| rules_python | 0.31.0 / 0.37.2 | 1.0.0 | Required for Bazel 8 (PyInfo moved) |
| rules_rust | 0.26.0 / 0.31.0 | 0.56.0 | Required for Bazel 8 compatibility |
| rules_cc | (not present) | 0.0.17 | New requirement for Bazel 8 |

## Blocking Issue

### Java Toolchain Incompatibility

The build fails due to rules_java compatibility issues:

**Problem 1: rules_java 7.x**
```
Error: no native function or rule 'java_proto_library'
```
- Bazel 8 removed `native.java_proto_library`
- rules_java 7.x expects it to exist

**Problem 2: rules_java 8.x**
```
Cycle in the workspace file detected: @@compatibility_proxy
```
- rules_java 8.x uses a compatibility proxy mechanism
- Creates cycles when loaded in WORKSPACE mode

**Root Cause:** The Java ecosystem rules weren't designed for Bazel 8 + WORKSPACE mode. They expect either:
- Bazel 7 with native Java rules, OR
- Bazel 8 with Bzlmod

## Files Modified

### bazel-distribution
- `.bazelrc` (new file)
- `.bazelversion`
- `WORKSPACE`
- `common/deps.bzl`
- `common/assemble_versioned/rules.bzl`
- `common/tgz2zip/rules.bzl`
- `common/java_deps/rules.bzl`
- `crates/rules.bzl`
- `maven/rules.bzl`
- `platform/jvm/rules.bzl`
- `npm/assemble/rules.bzl`
- `pip/rules.bzl`

### dependencies
- `.bazelrc`
- `.bazelversion`
- `WORKSPACE`
- `builder/rust/deps.bzl`
- `builder/rust/rules.bzl`
- `builder/python/deps.bzl`
- `builder/java/deps.bzl`
- `builder/proto_grpc/rust/compile.bzl`
- `builder/swig/java.bzl`
- `builder/swig/python.bzl`
- `builder/swig/go.bzl`
- `builder/swig/csharp.bzl`

## Next Steps

### Option A: Find Compatible Version Combination
Try to find specific versions of rules_java + rules_jvm_external + rules_kotlin that work together with Bazel 8 in WORKSPACE mode.

Versions to try:
- rules_java 7.12.x with specific flags
- rules_jvm_external 5.x or 6.x
- Check if `--incompatible_java_info_merge_runtime_module_flags` helps

### Option B: Migrate to Bzlmod
Convert from WORKSPACE to MODULE.bazel. This is the recommended path for Bazel 8 but requires significant changes:
- Create MODULE.bazel files
- Convert all http_archive/git_repository to bazel_dep
- Update all load() statements

### Option C: Stay on Bazel 7
If Bazel 8 compatibility is too complex, consider Bazel 7.x which has better WORKSPACE support.

## How to Resume

Start a new Claude Code session and say:
```
Read /opt/project/repositories/dependencies/bazel-8-upgrade-plan.md and continue the Bazel 8 upgrade
```

## Test Commands

Once the blocking issue is resolved, verify with:
```bash
# Test bazel-distribution
cd /opt/project/repositories/bazel-distribution
bazel build //...

# Test dependencies
cd /opt/project/repositories/dependencies
bazel build //...
```

## Reference Links

- Bazel 8 Migration Guide: https://bazel.build/release/migration
- Bzlmod Migration: https://bazel.build/external/migration
- rules_java: https://github.com/bazelbuild/rules_java
- rules_jvm_external: https://github.com/bazelbuild/rules_jvm_external
