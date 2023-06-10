
# TODO: rewrite completely.

# Overview


A simulator implementating "Lazy Sivaraman with Shaping":
* the algorithms presented in Sivaraman et. al.'s PIFO Trees paper,
* run through a PIFO tree as they describe,
* with thoughtful treatment of shaped algorithms,
* but with laziness when it comes to "housekeeping" the tree.

# Lazy Housekeeping

In the absence of shaping, pushing an element into a leaf node immediately
triggers the _propagation_ of that element upwards.
That is to say, a pointer to that packet is pushed into its parent node.
The routine runs recursively until the root node receives a pointer.

However, in the presence of shaping, an element may not be ready for propagation
at the time of enqueing.
A _shaping transaction_ is run at the time of enqueing;
this yields the packet's _earliest requested release time_.
If the simulated time passes an element's earliest requested release time,
we say the element is "ripe".
Only ripe elements should be propagated.
For uniformity, we say that unshaped elements are immediately ripe.

The existing literature loosely assumes that ripe elements are detected and
propagated immediately.
We take a different approach:
* We design a routine `housekeeping_minimal_any`, which chooses a random node,
  and, if the node's head element is ripe, propagates that element
  by one level.
  It is minimal (or lazy, if you will) in several ways:
    * It does not recurse: the parent will itself have to be housekept.
    * It does not check beyond the head: the present node itself could use
      more housekeeping.
* At a user-defined frequency, we pause other `push`/`pop` activity and
  run `housekeeping_minimal_any` on the tree.
  At a sufficiently high housekeeping frequency, this approaches the assumption
  that the existing literature makes.
  However, there does remain the possibility that a ripe element is not known
  to the root because of tardy housekeeping.
We argue that our method is easier to reason about in a single-threaded setting.

# Generating PCAPs

We provide a short Python script that generates toy PCAP files: `pcaps/pcap_gen.py`.

# Running Algorithms

Our reference algorithms, written in the style of Sivaraman et. al.'s
PIFO Trees paper, are in `lib/alg.ml`.
An algorithm can be run against a PCAP as shown in `test/run.ml`.
Running an algorithm causes an output to be written in CSV format.
These CSVs are then visualized by `pcaps.plot.py`.

# Installing and Running

Starting at `pifotrees/LazySiv/`, run `opam install . --deps-only` to install dependencies.

Then the following script will build, run, and visualize our most interesting results:
`python pcaps/pcap_gen.py; dune clean; dune build; dune test; python pcaps/plot.py`

This can be thinned out in the obvious way; for example, there is no
need to generate the PCAPs anew each time or to clean/build each time.
