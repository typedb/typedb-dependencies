# TypeDB Ubuntu 3.x Images

These images are prepared for TypeDB 3.x and contain a default SSL configuration.

Images are prepared for two base architectures: `arm64` and `amd64`. For easier maintenance, the images are tagged based on the incremental version specified manually in the `VERSION` file.

## Usage

### Setup

Images are assembled and deployed from local machines with [Docker](https://www.docker.com/get-started/).

To authenticate before starting the work, use:

```shell
docker login
```

If platform-specific images use `buildx`, run:
```shell 
docker buildx create --use --name multiarch-builder
docker buildx inspect --bootstrap

# If the previous command fails, run this cleanup and try again:
# docker buildx rm multiarch-builder
```

### Execution

It's possible to build images of any architecture on a local machine.

Update `VERSION`. Follow one of the branches below based on your goals.

#### Assembly and publish all architectures

To update all images via a single line, run:
```shell 
./assemble-deploy-all.sh
```

This script automatically assembles and publishes all platform-specific images with a multi-arch image (both `$VERSION` and `latest` tags). 

#### Separate steps

Use `assemble-docker.sh` and `deploy-docker.sh` separately if needed. See comments and `assemble-deploy-all.sh` for usage examples.
