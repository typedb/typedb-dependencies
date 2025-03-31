# TypeDB Docker Images

TypeDB uses custom Docker images for different applications.

These images can be created using image layers through Bazel rules (e.g., `docker_container_run_and_commit`), but we’ve
encountered OS-specific issues — presumably due to missing hidden parameters in the generated images. Additionally, we
don’t expect the base images to change frequently. Therefore, it’s more reliable to prepare them once and store them in
a separate repository.

Currently, there are multiple Ubuntu-based images with the required dependencies for both Java-based and
Rust-based [TypeDB servers](https://github.com/typedb/typedb).
