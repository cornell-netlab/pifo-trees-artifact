
# Formal Abstractions for Packet Scheduling

## Installation

### In the Docker Container

Installation is straightforward if you use our [package](https://github.com/cornell-netlab/pifo-trees-artifact/pkgs/container/pifo-trees):
1. `docker pull ghcr.io/cornell-netlab/pifo-trees:latest`
2. `docker run -it --rm ghcr.io/cornell-netlab/pifo-trees:latest`
3. Then, in the container, run `dune build` to build the project.

### To Build Locally

1. Install our prerequisites:
    - opam, version 2.1.4 or higher
    - OCaml, version 5.0.0 or higher
    - Dune, version 3.8.2 or higher
    - Python, version 3.11.3 or higher
    - Python libraries matplotlib, pandas, and scapy.
2. Clone this repository and `cd` into it.
3. Run `opam install . --deps-only` to install further OCaml dependencies.
4. Run `dune build` to build the project.


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


### Visualizing Embeddings over Topologies

Run `dune test`. This will pretty-print some sample non-binary topologies along with automatically generated embeddings of these topologies into binary form.

This is exactly the algorithm that we sketch in Theorem 6.1.
The first topology that we pretty-print is the same as Fig 3a in the paper, and the second is the same as Fig 3b.


### Running Handwritten Schedulers, Compiled Schedulers, and Visualizing the Results

Running `dune test` above has already run a few simulations for us.
In particular:
1. It has run a number of PCAPS through a number of handwritten schedulers against handwritten ternary topologies. It has saved the results as CSV files, which we can ignore for now.
2. It has also run the same PCAPS through automatically generated versions of the above schedulers, now running against automatically generated _binary_ topologies. Again, it has saved the results as CSV files, which we can ignore for now.

To visualize the results, run `python3 pcaps/plot.py`.

This will access our temporary files and run them through our visualizer, generating a number of PNG files. We supply a [mini-guide](extra.md) showing you how to copy these PNG files out of the Docker container. The PNG files generated are exactly as shown in tables 1, 2, and 3 of the paper, and are named `alg_name.png` or `alg_name_bin.png` depending on whether they were generated against a handwritten topology or a binary topology.

Note that, for all `alg_name`, the files `alg_name.png` and `alg_name_bin.png` look the same; this is exactly the point of our compilation algorithm: we have moved automatically to an entirely new (binary) topology, but have observed no appreciable loss in performance or change in behavior.

Note also that there is no second version of HPFQ, as it is already a binary scheduler. The point of this visualization is to show a scheduling algorithm that could not have been achieved without a hierarchical PIFO tree. It is impossible to implement this scheduler using a PIFO or using a flat ternary PIFO tree: tall skinny trees are more expressive than short fat trees.


## Extension

How would you go about writing your own scheduler?
Let us walk through a simple example.
You will:
1. Examine a flat 4-ary topology and see how it would be compiled into ternary form.
2. Study a simple scheduler that runs against this flat 4-ary topology.
3. Study a functor that compiles schedulers written against arbitrary topologies into schedulers against ternary topologies.
4. Run a PCAP through the handwritten scheduler and the compiled scheduler, and visualize the results.
5. Write your own scheduler against this flat 4-ary topology.

Before starting, we recommend a look through the file [`alg.ml`](lib/alg.ml).
It has been written with a pedagogical intent: it is heavily commented, and the earlier schedulers spell out their work with few, if any, fancy tricks.
Consider modifying a few things (e.g., in `Strict_Ternary`, change the order of strict priority; in `WFQ_Ternary`, change the weights) and re-running `dune test; python3 pcaps/plot.py` to see how the results change.


1. You will use the topology `flat_four` in [`topo.ml`](lib/topo.ml). To see this topology pretty-printed, and to see how this topology would be embedded into ternary form, run `dune test` and search for "EXTENSION" in the output.
Note that you are now embedding into ternary form, while all the examples so far have embedded into binary form.
This was accomplished using the method `build_ternary`, which we have already defined for you in [`topo.ml`](lib/topo.ml).
There should be no need to modify this code; we just want you to see the pattern.
2. Now, study a simple scheduler written against this flat 4-ary topology. Visit [`alg.ml`](lib/alg.ml) and find `Extension_Flat`. We have already provided a basic scheduler that performs FCFS scheduling.
This is just a simple modification of the scheduler `FCFS_Ternary` from earlier in the file, and we have marked the two changes with comments.
3. Now say you'd like to compile this scheduler to run against a regular-branching ternary topology. To do this, you will use the straightfoward functor `Alg2T` that we have already defined for you in [`alg.ml`](lib/alg.ml). This functor closely resembles `Alg2B` from earlier in the file.
There should be no need to modify this code; we just want you to see the pattern.
4. To run a PCAP through these two schedulers, run `dune test`. To visualize the results, run `python3 pcaps/plot.py --ext`.
The generated files will be called `extension.png` and `extension_ternary.png`.
Copy these files out using the instructions in the [mini-guide](extra.md), and compare the results.
They should be identical although they have been generated against different topologies.
5. Following this lead, can you now go back to [`alg.ml`](lib/alg.ml)'s `Extension_Flat` and modify it to perform WFQ scheduling? It should be similar to the module `WFQ_Ternary` from earlier in the file. Copy the code from that module over, and make some small changes:
    - You must send flow D to leaf 3.
    - You must register some weight for flow D in the state.
    - You must change the topology to `Topo.flat_four`.
    - Remember to retain the module name: `Extension_Flat`.
6. Repeat step 4 to view your results!

Feel free to iterate on this example by modifying the scheduler, or the arity of the target topology. You can even create new synthetic PCAPS using [`pcap_gen.py`](pcaps/pcap_gen.py). The visualizations are a handy guide for making sure that the behaviour of the basic scheduler is as you expect, and that the compiled scheduler is identical to the basic scheduler.