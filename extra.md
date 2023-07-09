
# Copying files out of a running Docker container

1. Run the container with `docker run -it ...` as described in the [README](README.md).
2. Now let's say, after some work, you have `image.png` in the container.
3. Run `pwd` in the container to find the path to the directory you want to copy out. For instance, it may be `/home/opam/pifo-trees-artifact`.
4. Back on the host, run `docker ps` to find the container ID. It will be something whimsical with an underscore, like `furious_cellist`.
5. Run `docker cp furious_cellist:/home/opam/pifo-trees-artifact/image.png .` to copy the file out.
