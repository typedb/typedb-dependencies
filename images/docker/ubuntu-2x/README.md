# TypeDB Ubuntu 2.x Images

These images are prepared for TypeDB 2.x and contain all the required dependencies like JVM.

Images are tagged based on the current Git commit SHA.

## Usage

### Setup

Images are assembled and deployed from local machines with [Docker](https://www.docker.com/get-started/).

To authenticate before starting the work, use:

```shell
docker login
```

### Execution

On Linux of a suitable architecture, use `bazel run //images/docker/ubuntu-2x:<target>`.

On Mac, run `assemble-docker.sh` and `deploy-docker.sh` manually, providing all the required arguments. See `BUILD` for
passed arguments examples.
