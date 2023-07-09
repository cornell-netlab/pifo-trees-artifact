# USAGE
# With this Dockerfile in working directory,
# docker build -t username/imagename .
# (note the period at the end)
# docker run -it username/imagename

# Start with latest OCaml image
FROM ocaml/opam

# Clone the repo
RUN git clone https://github.com/cornell-netlab/pifo-trees-artifact.git

# Change to the root directory
WORKDIR pifo-trees-artifact

# Install dependencies
RUN opam install . --deps-only

# Build the project
RUN opam install dune
