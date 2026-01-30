# Bzlmod Migration Status

## Summary

**Status: 100/108 targets building (93%) - Only ortools excluded due to ARM64 limitation**

## Environment Requirements

After installing system packages, the build no longer needs special LD_LIBRARY_PATH:

```bash
# Required system packages
sudo apt-get install -y openjdk-21-jdk-headless gcc make

# Build command (excludes ortools due to ARM64 limitation)
bazelisk build //... --extra_toolchains=@llvm_toolchain//:all -- -//library/ortools/...

# Full build (x86_64 only - ortools uses x86_64 cxxbridge binary)
bazelisk build //... --extra_toolchains=@llvm_toolchain//:all
```

---

## Working Targets

All targets build successfully except `//library/ortools/...`:

```bash
# Full build excluding ortools (100 targets)
bazelisk build //... --extra_toolchains=@llvm_toolchain//:all -- -//library/ortools/...
```

---

## Target Status Summary

| Category | Targets | Status |
|----------|---------|--------|
| `//tool/checkstyle/...` | 5 | Working |
| `//tool/util/...` | 7 | Working |
| `//builder/antlr/...` | 3 | Working |
| `//builder/compose/...` | 3 | Working |
| `//builder/java/...` | 3 | Working |
| `//builder/kotlin/...` | 3 | Working |
| `//tool/release/...` | 7 | Working |
| `//images/docker/...` | 7 | Working |
| `//tool/sonarcloud/...` | 3 | Working |
| `//tool/swig/...` | 2 | Working |
| `//library/ortools/...` | 8 | Excluded (cxxbridge x86_64 binary on aarch64) |

---

## Fixed Issues

### 1. Maven Resolution (Fixed)
Transitive dependency issues with gRPC and gax versions have been resolved:
- Updated gRPC from 1.49.0 to 1.50.1 with all transitive deps pinned
- Updated gax/gax-grpc from 1.64.0 to 2.19.4
- Commented out `google-api-services-servicecontrol` (transitive dep pulls version-less reference)

### 2. Docker BUILD Files (Fixed)
Fixed `sh_binary` rules in `images/docker/ubuntu-2x/BUILD`:
- Removed invalid `deps` attribute (genrules cannot be in deps)
- Added colon prefix to genrule references in data (`:tag-amd64`, `:tag-arm64`)

---

## Remaining Issues

### cxxbridge ARM64
The `cxxbridge_linux` binary is x86_64 only. The `//library/ortools/...` targets (8 targets) are excluded on ARM64 systems.

Options to resolve:
- Build cxxbridge from source for ARM64
- Find ARM64 pre-built binary
- Cross-compile on x86_64 systems

---

## Migrated Repositories

The following WORKSPACE repositories have been added to MODULE.bazel:

| Repository | Source | Status |
|------------|--------|--------|
| `@swig` | `tool/swig/deps.bzl` | Migrated |
| `@sonarscanner_*` | `tool/sonarcloud/deps.bzl` | Migrated |
| `@or_tools_*` | `library/ortools/cc/deps.bzl` | Migrated (but cxxbridge fails on aarch64) |
| `@cxxbridge_*` | MODULE.bazel | x86_64 binaries, fail on aarch64 |
| `@buildozer_*` | MODULE.bazel | Migrated |
| `@unused_deps_*` | MODULE.bazel | Migrated |

---

## Files Modified

- `MODULE.bazel` - Added repos, fixed crate.annotation, pinned gRPC/gax versions
- `images/docker/ubuntu-2x/BUILD` - Fixed sh_binary rules
- `BZLMOD_MIGRATION_STATUS.md` - This file
