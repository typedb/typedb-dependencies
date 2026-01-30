# Bzlmod Migration Status

## Summary

**Status: Partially Working - Maven resolution issues block most targets**

## Environment Requirements

After installing system packages, the build no longer needs special LD_LIBRARY_PATH:

```bash
# Required system packages
sudo apt-get install -y openjdk-21-jdk-headless gcc make

# Build command
bazelisk build <targets> --extra_toolchains=@llvm_toolchain//:all
```

---

## Working Targets

The following targets build successfully:

```bash
# Checkstyle tools (5 targets)
bazelisk build //tool/checkstyle/... --extra_toolchains=@llvm_toolchain//:all

# Utility tools (7 targets)
bazelisk build //tool/util/... --extra_toolchains=@llvm_toolchain//:all
```

---

## Blocked: Maven Resolution

Most targets fail due to Maven/coursier transitive dependency resolution issues:

**Error:**
```
Resolution error: Error downloading com.google.apis:google-api-services-servicecontrol:
  not found: .../google-api-services-servicecontrol//google-api-services-servicecontrol-.pom
```

**Root Cause:** Firebase-admin and Google Cloud libraries have complex transitive dependencies that coursier fails to resolve. The empty version in the URL indicates a transitive dependency with no pinned version.

**Affected Artifacts:**
- `com.google.firebase:firebase-admin:9.1.1` - pulls in problematic transitives
- `com.google.cloud:*` libraries - version conflicts with gRPC and gax

---

## Target Status Summary

| Category | Targets | Status |
|----------|---------|--------|
| `//tool/checkstyle/...` | 5 | ✅ Working |
| `//tool/util/...` | 7 | ✅ Working |
| `//builder/antlr/...` | - | ❌ Maven resolution |
| `//builder/compose/...` | - | ❌ Maven resolution |
| `//builder/java/...` | - | ❌ Maven resolution |
| `//builder/kotlin/...` | - | ❌ Maven resolution |
| `//tool/release/...` | - | ❌ Maven resolution |
| `//library/ortools/...` | - | ❌ cxxbridge x86_64 binary on aarch64 |
| `//images/docker/...` | - | ❌ BUILD file errors |
| `//tool/sonarcloud/...` | - | ✅ Repos migrated |
| `//tool/swig/...` | - | ✅ Repos migrated |

---

## Migrated Repositories

The following WORKSPACE repositories have been added to MODULE.bazel:

| Repository | Source | Status |
|------------|--------|--------|
| `@swig` | `tool/swig/deps.bzl` | ✅ Migrated |
| `@sonarscanner_*` | `tool/sonarcloud/deps.bzl` | ✅ Migrated |
| `@or_tools_*` | `library/ortools/cc/deps.bzl` | ✅ Migrated (but cxxbridge fails on aarch64) |
| `@cxxbridge_*` | MODULE.bazel | ⚠️ x86_64 binaries, fail on aarch64 |
| `@buildozer_*` | MODULE.bazel | ✅ Migrated |
| `@unused_deps_*` | MODULE.bazel | ✅ Migrated |

---

## Remaining Issues to Fix

### 1. Maven Resolution (Critical)
The `firebase-admin` and Google Cloud libraries have transitive dependency issues with coursier. Options:
- Remove firebase-admin and related Google Cloud artifacts
- Use `fail_on_missing_checksum = False`
- Pin all transitive versions explicitly
- Use maven BOM imports

### 2. cxxbridge ARM64
The `cxxbridge_linux` binary is x86_64 only. Need ARM64 version or build from source.

### 3. Docker BUILD Files
`//images/docker/...` has BUILD file errors (genrule used where sh_library expected).

---

## Files Modified

- `MODULE.bazel` - Added repos, fixed crate.annotation, commented out servicecontrol
- `BZLMOD_MIGRATION_STATUS.md` - This file
