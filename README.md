
# Formal Abstractions for Packet Scheduling


## Overview

This is an artifact in support of our [paper](https://arxiv.org/abs/2211.11659) _Formal Abstractions for Packet Scheduling_.
1. It implements several key definitions from the paper.
2. It implements the embedding algorithm described in Theorem 6.1, and shows how to lift this embedding to operate on schedulers.
3. It generates the visualizations that we show in Section 7.
4. It can be extended to write a new, possibly heterogenous (i.e., _not_ necessarily regular d-ary branching) topology, write a new scheduler against that topology, and compile that scheduler to instead run against an automatically generated regular-branching d-ary topology.

The first three feautures are in support of the _Functional_ badge, while the last is in support of the _Reusable_ badge.


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

4. `Control` is defined in [`control.ml`](lib/control.ml).

    The same file also contains `sched_t`, which is the type of all scheduling transactions.

### Advanced

Now let us visit the definitions and methods that pertain to the embedding algorithm. These all live in [`topo.ml`](lib/topo.ml). Look out for:
1. `Addr`.
2. The homomorphic embedding of one topology into another, written `f : Topo -> Topo` in the paper. In the code it is called `map`.
3. Given a map `f`, we can lift it to operate over paths, as discussed in Definition 5.8 of the paper. This lifting method is called `lift_tilde` in the code. It creates `f-tilde: Path -> Path`.


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

Scheduling transactions are written by hand (in [`alg.ml`](lib/alg.ml)).
To see how scheduling transactions may be created and how controls may be generated atop of these, study a simple example such as FCFS in [`alg.ml`](lib/alg.ml).

`simulate`, which runs a given list of packets through a given control. Note that this is different from the relation _simulation_ defined in the paper, which is a formal statement about one PIFO tree being able to mimic the behavios or another.


[`run.ml`](test/run.ml) contains a few scripts of interest:
1. `embed_binary_only` runs the embedding algorithm over a few sample topologies and pretty-prints the answers.
2. `simulate_handwritten` runs sample PCAPS through the schedulers that we have written by hand.
3. `simulate_binary` runs sample PCAPS through the binary schedulers that we have generated automatically.

To run these tests,
1. Fromt the home directory, run `opam install . --deps-only` to install our dependencies.
2. Visit [`run.ml`](test/run.ml) and make sure that `let _ = ...` is pointing at `embed_binary_only`.
3. Run `dune test`. This will pretty-print some sample topologies along with embeddings of these topologies into binary topologies. This is exactly the algorithm that we visualize in Figure 3 and sketch in Theorem 6.1.
4. Visit [`run.ml`](test/run.ml) and toggle `let _ = ...` to point to `simulate_handwritten`. This will run PCAPS through a number of handwritten schedulers against ternary topologies. It will save the outputs in temporary files.
5. Visit [`run.ml`](test/run.ml) and toggle `let _ = ...` to point to `simulate_binary`. This will run the same PCAPS through automatically generated versions of the above schedulers, now running against automatically generated binary topologies. Again, it will save these outputs in temporary files.
6. Now run `python3 pcaps/plot.py; open *.png`. This will access our temporary files and run them through our our visualizer. The PNG files generated are exactly as shown in tables 1, 2, and 3 of the paper. Note that, for all `alg_name`, `alg_name.png` and `alg_name_bin.png` look the same; this is exactly the point of our compilation algorithm: we have moved automatically to an entirely new topology, but have observed no appreciable loss in performance or change in behavior.


## Extension (for the "reusable" badge)

In the paper we have only really written schedulers against _regular-branching ternary_ topologies and then compiled them to run against regular-branching binary topologies.
This is a little timid: the algorithm presented in Theorem 6.1 allows us to embed _any_ topology into any regular-branching d-ary branching topology.
Let us walk through how we would write a scheduler against a heterogenous topology and then compile it to run against a regular-branching ternary topology.

1. The file [`alg.ml`](lib/alg.ml) has been written with a pedagogical intent: it is heavily commented, and the earlier schedulers spell out their work with few, if any, fancy tricks. Before working on the extension, we recommend a look through this file until the comment marked EXTENSION.
2. We will use the topology `irregular2` in [`topo.ml`](lib/topo.ml). To see this topology pretty-printed, and to see how this topology would be embedded into a ternary tree, go to [`run.ml`](test/run.ml) and toggle `let _ =` to point to `extension_embed`. Run `dune test`.
3. Now let's write a new scheduler against this heterogenous topology. Visit [`alg.ml`](lib/alg.ml) and find `module ThreePol_Irregular`. We have already provided a sketch of a scheduler, essentially doing WFQ sharing at three different levels. Feel free to modify the weights if you wish.
4. Run a PCAP through this scheduler by visiting [`run.ml`](test/run.ml), toggling `let _ =` to point to `extension_run`, and then running `dune test`.
5. Now run the same PCAP through a new, automatically generated scheduler that runs against a ternary topology. Visit [`run.ml`](test/run.ml), toggle `let _ =` to point to `extension_embed_run`, and run `dune test`.
6. To visualize the results, run `python3 pcaps/plot.py; open extension*.png`. The results should be identical.

We have, so far, used synthetically generated PCAPs to test our schedulers.
The scripts we use to generate these are in [`pcap_gen.py`](pcaps/pcap_gen.py), and users are encouraged to modify this script to generate their own PCAPs.
