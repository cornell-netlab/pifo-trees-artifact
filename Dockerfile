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

# Good to have
RUN sudo apt-get update && sudo apt-get install -y vim && sudo apt-get install -y emacs

# Install Python 3.11
RUN sudo apt-get install -y python3 && sudo apt-get install -y python3-pip && sudo apt-get install -y python3-matplotlib && sudo apt-get install -y python3-pandas
