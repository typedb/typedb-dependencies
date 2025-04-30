# TypeDB Ubuntu 3.x Images

These images are prepared for TypeDB 3.x and contain a default SSL configuration.

Images are prepared for two base architectures: `arm64` and `amd64`. Images are tagged based on the current `VERSION` and Git commit SHA.

## Usage

### Setup

Images are assembled and deployed from local machines with [Docker](https://www.docker.com/get-started/).

To authenticate before starting the work, use:

```shell
docker login
```

### Execution

Using a suitable OS and architecture, use `bazel run //images/docker/ubuntu-3x:<target>`.

If Bazel rules do not work on your machine, run `assemble-docker.sh` and `deploy-docker.sh` manually, providing all the required arguments, or `assemble-deploy-all.sh` for a fast update for all versions. See `BUILD` for
passed arguments examples.

#### Separate steps

Use `assemble-docker.sh` and `deploy-docker.sh` separately if needed. See comments and `assemble-deploy-all.sh` for
usage examples.
