# TypeDB Ubuntu 2.x Images

These images are prepared for TypeDB 2.x and contain all the required dependencies like JVM.

Images are prepared for two base architectures: `arm64` and `amd64`. Images are tagged based on the current `VERSION` and Git commit SHA.

## Usage

### Setup

Images are assembled and deployed from local machines with [Docker](https://www.docker.com/get-started/).

To authenticate before starting the work, use:

```shell
docker login
```

### Execution

Using a suitable OS and architecture, use `bazel run //images/docker/ubuntu-2x:<target>`.

If Bazel rules do not work on your machine, run `assemble-docker.sh` and `deploy-docker.sh` manually, providing all the required arguments. See `BUILD` for
passed arguments examples.
