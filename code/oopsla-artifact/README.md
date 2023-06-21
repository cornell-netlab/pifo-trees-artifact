
# Formal Abstractions for Packet Scheduling


## Overview

This is an artifact in support of our [paper](https://arxiv.org/abs/2211.11659) _Formal Abstractions for Packet Scheduling_.
It implements several key definitions from the paper, and can be used to generate the visualizations that we show towards the end of the paper.


## Key Definitions

Topo, PIFOTree, and Control, along with straightforward supporting methods such as `flush`, `snap`, `size`, etc are defined in the relevant files.
Topologies are written by hand and then converted into empty PIFOTrees using a `create` method.
Scheduling transactions are written by hand.
To see how scheduling transactions may be created and how Controls may be generated atop of these, study a simple example such as FCFS under `lib/alg.ml`.


## Embedding Algorithm

One of the contributions of the paper is an embedding algorithm that takes one from one topology to another.
That is implemented as `build_binary` under lib/topo.ml; it returns both the binary topology and the embedding map from the source topology to the destination (binary) topology.

The same file also has `lift_tilde`, which lifts an embedding map `f : Topo.t -> Topo.t` to instead operate over paths, i.e. `f-tilde: Path.t -> Path.t`.

To see how these can be orchestrated to convert ternary _algorithms_ into binary algorithms, study the functor `T2B` under `lib/alg.ml`.


## Generating PCAPs

We provide a short Python script that generates toy PCAP files: `pcaps/pcap_gen.py`.


## Testing

`test/run.ml` contains a few scripts that may be of interest.
1. `embedding_only` runs the embedding algorithm over a few sample topologies and pretty-prints the answer.
2. `simulate_handwritten` runs sample PCAPS through the algorithms that we have written by hand.
3. `simulate_binary` runs sample PCAPS through the binary algorithms that we have generated via compilation.

To run these tests,
1. Run `opam install . --deps-only` in the directory `oopsla-artifact` to install our dependencies.
2. Go into `test/run.ml` and toggle what the target of `let _ = ...` is.
3. Run `dune test`.
4. To visualize the results, run `python3 pcaps/plot.py; open *.png`.
