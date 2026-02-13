# Bzlmod Migration Guide

This document summarizes the successful migration from WORKSPACE to Bzlmod (Bazel 8+) for the `dependencies` and `bazel-distribution` repositories.

## Migration Results

| Repository | Targets | Success Rate |
|------------|---------|--------------|
| `dependencies` | 100/108 | 93% |
| `bazel-distribution` | 52/53 | 98% |

---

## Key Migration Steps

### 1. Create MODULE.bazel

Replace WORKSPACE-based dependency management with MODULE.bazel:

```python
module(
    name = "typedb_dependencies",
    version = "0.0.0",
)
```

### 2. Migrate bazel_dep() Dependencies

Convert `http_archive` / `git_repository` rules to `bazel_dep()`:

```python
# Before (WORKSPACE)
http_archive(
    name = "rules_java",
    urls = ["https://github.com/bazelbuild/rules_java/releases/download/7.4.0/rules_java-7.4.0.tar.gz"],
)

# After (MODULE.bazel)
bazel_dep(name = "rules_java", version = "7.4.0")
```

### 3. Migrate Maven Dependencies

Use `rules_jvm_external` extension with pinned versions:

```python
maven = use_extension("@rules_jvm_external//:extensions.bzl", "maven")
maven.install(
    artifacts = [
        "io.grpc:grpc-api:1.50.1",
        "io.grpc:grpc-core:1.50.1",
        # ... pin ALL transitive deps explicitly
    ],
    fail_on_missing_checksum = False,
    repositories = [
        "https://repo1.maven.org/maven2",
        "https://maven.google.com",
    ],
)
use_repo(maven, "maven")
```

**Critical:** Pin transitive dependency versions to avoid coursier resolution failures.

### 4. Migrate http_archive to use_repo_rule

For archives not available as bazel_dep:

```python
http_archive = use_repo_rule("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "swig",
    build_file_content = "...",
    sha256 = "...",
    urls = ["..."],
)
```

### 5. Add Hermetic Toolchain

Use `toolchains_llvm` for reproducible C/C++ builds:

```python
bazel_dep(name = "toolchains_llvm", version = "1.4.0", dev_dependency = True)

llvm = use_extension("@toolchains_llvm//toolchain/extensions:llvm.bzl", "llvm", dev_dependency = True)
llvm.toolchain(llvm_version = "17.0.6")
use_repo(llvm, "llvm_toolchain")

register_toolchains("@llvm_toolchain//:all", dev_dependency = True)
```

Build with: `bazel build //... --extra_toolchains=@llvm_toolchain//:all`

### 6. Use dev_dependency for Root-Only Dependencies

Mark dependencies only needed when building the module directly:

```python
bazel_dep(name = "toolchains_llvm", version = "1.4.0", dev_dependency = True)
```

---

## Common Issues and Fixes

### Maven Transitive Dependency Conflicts

**Problem:** Coursier fails with empty version in URL
```
Error downloading com.google.apis:google-api-services-servicecontrol:
  not found: .../google-api-services-servicecontrol-.pom
```

**Solution:** Pin all transitive versions explicitly:
- gRPC: Use consistent version (1.50.1) for all `io.grpc:*` artifacts
- gax: Align `gax` and `gax-grpc` versions (2.19.4)
- Add missing transitive deps: `grpc-alts`, `grpc-auth`, `grpc-googleapis`, etc.

### sh_binary deps Attribute Error

**Problem:** `sh_binary` cannot have `genrule` in `deps`

**Solution:** Move genrule references to `data` only:
```python
# Before (broken)
sh_binary(
    name = "assemble-docker",
    srcs = ["assemble.sh"],
    data = ["Dockerfile"],
    deps = [":tag-genrule"],  # ERROR
)

# After (fixed)
sh_binary(
    name = "assemble-docker",
    srcs = ["assemble.sh"],
    data = ["Dockerfile", ":tag-genrule"],
)
```

### crate.annotation gen_binaries

**Problem:** `gen_binaries = True` is invalid

**Solution:** Specify binary names explicitly:
```python
crate.annotation(
    crate = "cbindgen",
    gen_binaries = ["cbindgen"],  # Not True
)
```

### Platform-Specific Binaries

**Problem:** x86_64 binaries fail on ARM64

**Solution:** Exclude affected targets on incompatible platforms:
```bash
bazel build //... -- -//library/ortools/...
```

---

## Verification Commands

```bash
# dependencies repo (ARM64)
cd repositories/dependencies
bazelisk build //... --extra_toolchains=@llvm_toolchain//:all -- -//library/ortools/...

# dependencies repo (x86_64 - full build)
bazelisk build //... --extra_toolchains=@llvm_toolchain//:all

# bazel-distribution repo
cd repositories/bazel-distribution
bazelisk build //... -- -//docs/...
```

---

## Files Modified

### dependencies
- `MODULE.bazel` - Central Bzlmod configuration
- `images/docker/ubuntu-2x/BUILD` - Fixed sh_binary rules
- `BZLMOD_MIGRATION_STATUS.md` - Current status tracking
- `BZLMOD_MIGRATION_GUIDE.md` - This guide

### bazel-distribution
- `MODULE.bazel` - Central Bzlmod configuration
- `BZLMOD_MIGRATION_STATUS.md` - Current status tracking

---

## References

- [Bzlmod Migration Guide](https://bazel.build/external/migration)
- [rules_jvm_external Bzlmod](https://github.com/bazelbuild/rules_jvm_external#bzlmod)
- [toolchains_llvm](https://github.com/bazel-contrib/toolchains_llvm)
