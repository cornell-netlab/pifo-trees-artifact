
# Formal Abstractions for Packet Scheduling


## Overview

This is an artifact in support of our [paper](https://arxiv.org/abs/2211.11659) _Formal Abstractions for Packet Scheduling_.
1. It implements several key definitions from the paper.
2. It implements the embedding algorithm described in Theorem 6.1, and shows how to lift this embedding to operate on schedulers.
3. It generates the visualizations that we show in Section 7.
4. It can be extended to write a new, possibly heterogenous (i.e., _not_ necessarily regular d-ary branching) topology, write a new scheduler against that topology, and compile that scheduler to instead run against an automatically generated regular-branching d-ary topology.

The first three feautures are in support of the _Functional_ badge, while the last is in support of the _Reusable_ badge.

Installation is simple:
- Prerequisites: [opam](https://opam.ocaml.org/) 2.1.4 and [OCaml 5.0.0](https://ocaml.org/releases/5.0.0).
- From the home directory, run `opam install . --deps-only` to install our dependencies.
- Then run `dune build` to build the project.


## Key Definitions

### Basic

First, we introduce the basic constructs from Sections 1 through 4:
1. `Topo` is defined in [`topo.ml`](lib/topo.ml). The file also contains a few handwritten topologies.
2. `Path` is defined in [`path.ml`](lib/path.ml).
3. `PIFOTree` is defined in [`pifotree.ml`](lib/pifotree.ml).

   The same file also contains:
    - `pop`
    - `push`
    - `size`
    - `well_formed`
    - `snap`
    - `flush`
    - `create`, which builds a `PIFOTree` from a `Topo`.

4. `Control` is defined in [`control.ml`](lib/control.ml). The file also contains `sched_t`, which is the type of all scheduling transactions.

5. Scheduling transactions are written by hand (in [`alg.ml`](lib/alg.ml)).
To see how scheduling transactions may be created and how controls may be generated atop of these, study a simple example such as FCFS in [`alg.ml`](lib/alg.ml).

6. To guide intuition and aid debugging, we have `simulate`, which runs a given list of packets through a given control. Note that this is different from the relation _simulation_ defined in the paper, which is a formal statement about one PIFO tree being able to mimic the behavios or another. The `simulate` function lives in [`control.ml`](lib/control.ml).

### Advanced

Now let us visit the definitions and methods that pertain to the embedding algorithm. These all live in [`topo.ml`](lib/topo.ml). Look out for:
1. `Addr`, which is how we walk down a topology and identify a particular node.
2. The homomorphic embedding of one topology into another, written `f : Addr -> Addr` in Definition 5.2 of the paper. In the code it is called `map`.
3. Given a map `f`, we can lift it to operate over paths, as discussed in Definition 5.8 of the paper. This lifting function is called `lift_tilde` in the code. It creates `f-tilde: Path -> Path`.


## Embedding Algorithms

### Embedding Topologies

One of the contributions of the paper is an embedding algorithm that safely takes us one from one topology to another.
That is implemented as `build_d_ary` in [`topo.ml`](lib/topo.ml).

This function takes a source topology, which may be heterogenous, and returns two things:
1. The target topology, which is a regular-branching d-ary topology (for the chosen `d`).
2. The embedding map `f` from the source topology to the target topology.

It is implemented as described in Theorem 6.1 of the paper.

### Compiling Schedulers

Next, to see how the above can be orchestrated to convert _schedulers_ written against heterogenous topologies into _schedulers_ running against d-ary topologies, study the functors `Alg2B` (where `d=2`) and `Alg2T` (where `d=3`) in [`alg.ml`](lib/alg.ml). These proceed as described in Theorem 5.10 of the paper.


## Visualizations

We will be visiting the file [`run.ml`](test/run.ml) and toggling the `let _ =` to point to different functions.

### Visualizing Embeddings over Topologies

1. Visit [`run.ml`](test/run.ml) and make sure that `let _ = ...` is pointing at `embed_binary_only`.
2. Run `dune test`. This will pretty-print some sample non-binary topologies along with automatically generated embeddings of these topologies into binary. The pretty-printer requires a list of paths that you are interested in tracking through the embedding; see the existing code for examples.

This is exactly the algorithm that we sketch in Theorem 6.1.
The first topology that we embed is the same as Fig 3a in the paper, and the second is the same as Fig 3b.


### Running Handwritten Schedulers, Compiled Schedulers, and Visualizing the Results

1. Visit [`run.ml`](test/run.ml) and toggle `let _ = ...` to point to `simulate_handwritten`.
2. Run `dune test`. This will run PCAPS through a number of handwritten schedulers against handwritten ternary topologies. It will save the outputs in temporary files; you can ignore this for now.
3. Visit [`run.ml`](test/run.ml) and toggle `let _ = ...` to point to `simulate_binary`.
4. Run `dune test`. This will run the same PCAPS through automatically generated versions of the above schedulers, now running against automatically generated binary topologies. Again, it will save these outputs in temporary files, which you can again ignore.
5. Now run `python3 pcaps/plot.py; open *.png`. This will access our temporary files and run them through our visualizer. The PNG files generated are exactly as shown in tables 1, 2, and 3 of the paper. Note that, for all `alg_name`, `alg_name.png` and `alg_name_bin.png` look the same; this is exactly the point of our compilation algorithm: we have moved automatically to an entirely new (binary) topology, but have observed no appreciable loss in performance or change in behavior.

There is no second version of HPFQ, as it is already a binary scheduler. The point of this visualization is to show a scheduling algorithm that could not have been achieved without a hierarchical PIFO tree. It is impossible to implement this scheduler using a PIFO or using a flat ternary PIFO tree: tall skinny trees are more expressive than short fat trees.

## Extension

So far we have only really written schedulers against _regular-branching ternary_ topologies and then compiled them to run against regular-branching binary topologies.
This is a little timid: the algorithm presented in Theorem 6.1 allows us to embed _any_ topology into any regular-branching d-ary topology.
Let us walk through how we would write a scheduler against a heterogenous topology and then compile it to run against a regular-branching ternary topology.

1. The file [`alg.ml`](lib/alg.ml) has been written with a pedagogical intent: it is heavily commented, and the earlier schedulers spell out their work with few, if any, fancy tricks. Before working on the extension, we recommend a look through this file until the comment marked EXTENSION.
2. We will use the topology `irregular2` in [`topo.ml`](lib/topo.ml). To see this topology pretty-printed, and to see how this topology would be embedded into a ternary tree, go to [`run.ml`](test/run.ml) and toggle `let _ =` to point to `extension_embed`. Run `dune test`.
3. Now let's write a new scheduler against this heterogenous topology. Visit [`alg.ml`](lib/alg.ml) and find `module ThreePol_Irregular`. We have already provided a sketch of a scheduler, essentially doing WFQ sharing at three different nodes. Feel free to modify the weights if you wish; this is done by changing the state variables.
4. To visualize the results of running a PCAP through this scheduler, visit [`run.ml`](test/run.ml), toggle `let _ =` to point to `extension_run`, and then run `dune test`. The results will to to temporary files, which you can ignore.
5. Now we'd like to compile this scheduler to run against a regular-branching ternary topology. To do this, we will use the straightfoward functor `Alg2T` in [`alg.ml`](lib/alg.ml). This functor takes a scheduler against a heterogenous topology and returns a scheduler against a regular-branching ternary topology. To see this in action, visit [`run.ml`](test/run.ml), toggle `let _ =` to point to `extension_embed_run`, and run `dune test`.
6. To visualize the results, run `python3 pcaps/plot.py --ext; open extension*.png`. The two results should be identical although they have been generated against different topologies.
7. We have, so far, used synthetically generated PCAPs to test our schedulers. The scripts we use to generate these are in [`pcap_gen.py`](pcaps/pcap_gen.py), and users can modify this script to generate their own PCAPs.
