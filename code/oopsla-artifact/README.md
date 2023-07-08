
# Formal Abstractions for Packet Scheduling


## Overview

This is an artifact in support of our [paper](https://arxiv.org/abs/2211.11659) _Formal Abstractions for Packet Scheduling_.
1. It implements several key definitions from the paper.
2. It implements the embedding algorithm shown in Fig 3 and described in Section 6.1.
3. It can be used to generate the visualizations that we show in Section 7.

## Key Definitions

Topo, PIFOTree, and Control, along with straightforward supporting methods such as `flush`, `snap`, `size`, etc. are defined in the files [`topo.ml`](lib/topo.ml#L9), `pifotree.ml`, and `control.ml`.
Topologies are written by hand (in `topo.ml`) and converted into empty PIFOTrees using a `create` method (in `pifotree.ml`).
Scheduling transactions are written by hand (in `alg.ml`).
To see how scheduling transactions may be created and how controls may be generated atop of these, study a simple example such as FCFS under `alg.ml`.


## Embedding Algorithm

One of the contributions of the paper is an embedding algorithm that takes one from one topology to another.
That is implemented as `build_d_ary` under lib/topo.ml, and we primarily instantiate it with `d=2` to get `build_binary`.

This method takes a source topology, which may be heterogenous, and returns two things:
1. The target topology, which is regular d-ary branching for a given `d`.
2. The embedding map `f` from the source topology to the target topology.

The same file also has `lift_tilde`, which lifts an embedding map `f : Topo.t -> Topo.t` to instead operate over paths, i.e. `f-tilde: Path.t -> Path.t`.

To see how these can be orchestrated to convert _schedulers_ written against heterogenous topologies into _schedulers_ running against binary topologies, study the functor `Alg2B` under `alg.ml`.


## Generating PCAPs

We provide a short Python script that generates toy PCAP files: `pcaps/pcap_gen.py`.


## Testing (for the "functional" badge)

`test/run.ml` contains a few scripts that may be of interest.
1. `embed_binary_only` runs the embedding algorithm over a few sample topologies and pretty-prints the answer.
2. `simulate_handwritten` runs sample PCAPS through the schedulers that we have written by hand.
3. `simulate_binary` runs sample PCAPS through the binary schedulers that we have generated via compilation.

To run these tests,
1. Run `opam install . --deps-only` in the directory `oopsla-artifact` to install our dependencies.
2. Go into `test/run.ml` and make sure that `let _ = ...` is pointing at `embed_binary_only`.
3. Run `dune test`. This will pretty-print some sample topologies along with embeddings of these topologies into binary topologies. This is what we visualize in Fig 3 and sketch in Section 6.1.
4. Go into `test/run.ml` and toggle `let _ = ...` to point to `simulate_handwritten ()`. This will run PCAPS through a number of handwritten schedulers against ternary topologies. It will save the outputs in temporary files.
5. Go into `test/run.ml` and toggle `let _ = ...` to point to `simulate_binary ()`. This will run the same PCAPS through automatically generated versions of the above schedulers, now running against automatically generated binary topologies. Again, it will save these outputs in temporary files.
6. Now run `python3 pcaps/plot.py; open *.png`. This will access our temporary files and run our visualizer on them. The PNG files generated are exactly as shown in tables 1, 2, and 3 of the paper. Note that `alg_name` and `alg_name_bin` look the same; this is exactly the point of our compilation algorithm: we have moved to an entirely new topology, automatically, but have observed to appreciable loss in performance.


## Extension (for the "reusable" badge)

In the paper we have only really written schedulers against _regular ternary_ topologies and then compiled them to run against regular binary topologies.
This is a little timid: the algorithm presented in Section 6.1 allows us to embed _any_ topology into any regular d-ary branching topology.
Let us walk through how we would write a scheduler against a heterogenous topology and then compile it to run against a regular-branching ternary topology.

1. The file `alg.ml` has been written with a pedagogical intent: it is heavily commented, and the earlier schedulers spell out their work with few, if any, fancy tricks. Before working on the extension, we recommend a look through this file until the comment marked EXTENSION.
2. We will use the topology `irregular2` in `topo.ml`. To see this topology pretty-printed, and to see how this topology would be embedded into a ternary tree, go to `test/run.ml` and toggle `let _ =` to point to `extension_embed`. Run `dune test`.
3. Now let's write a new scheduler against this heterogenous topology. Visit `alg.ml` and find `module ThreePol_Irregular`. We have already provided a sketch of a scheduler, essentially doing WFQ sharing at three different levels. Feel free to modify the weights if you wish.
4. Run a PCAP through this scheduler by visiting `test/run.ml`, toggling `let _ =` to point to `extension_run`, and then running `dune test`.
5. Now run the same PCAP through a new, automatically generated scheduler that runs against a ternary topology. Visit `test/run.ml`, toggle `let _ =` to point to `extension_embed_run`, and run `dune test`.
6. To visualize the results, run `python3 pcaps/plot.py; open extension*.png`. The results should be identical.
