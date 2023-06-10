If you were to write the introduction of a paper, what would that look like?

* What's the problem we're solving? (Explain it in general terms.)
Despite advances in other parts of networking, packet scheduling continues to be 
``baked into the silicon''. Previous work [Siv16] has shown that _programmable_ 
packet scheduling is possible, but this approach has not caught on. Rather, 
follow-on work (e.g. [Alc20]) has skirted around the issue, showing how 
programmable scheduling can be approximated.
We argue that this is because PIFO trees, the data structures central to 
[Siv16], are complicated and poorly understood.

* What's our technical approach? (Really draw out our "secret sauce")
 Our response is rooted in theory
and PL. We show how to simplify and (de)compose PIFO trees while still achieving
expected behavior. We give an algorithm that compiles a PIFO tree into a normal 
form that is more amenable to hardware embedding. 

* What are the key challenges? (What are 2-4 hurdles we had to overcome in our 
solution? That is, why was this research and not just engineering.)
TK

* What are our results? (Summary of what becomes possible after this work, and 
how we demonstrate it.)

first model (semantics)
transformation
compilation

1. As proposed in [Siv16], the elements of a PIFO tree are allowed to exist in a
state of limbo where they have entered the scheduler but are not available for 
release. This is too hard to reason about. We explain how the same behavior can 
be achieved via a composition of two PIFO trees, each of which behaves 
straightforwardly.
2. We give an algorithm that compiles a PIFO tree into a normal form that is 
more amenable to hardware embedding. We outline, with greater precision than
previous results have offered, the conditions under which such a compilation is
possible.




1. A formal model of PIFO trees
a. description
b. some curiosities
    - high pop-rate: end up with FIFO scheduling
    - low pop-rate: shaping is less effective
    - the need for shaper/scheduler agreement at the node level

2. Sivaraman's version
a. review: how this refines the model
b. issues
    - packets in limbo between (schedule, shape, propagate)*
    - seems to assume multithreading in order to support the assumption that all nodes are always housekept

3. Our version
a. review: how this refines the model
b. points of divergence from Sivaraman, and associated winnings
    (i) one "brain"
        - big cleanup in state
        - lets us compile one tree into another
            - TODO: how to compile a "brain" program?
            - TODO: proofs
            - TODO: does there exist one shape of tree that is better for hardware, and can we target that for compilation?
    (ii) lazy housekeeping
        - lets us be single-threaded
c. trade-offs
    - potentially unable to support some algorithms. TODO: find a precise statement of what we cannot support
    - poor housekeeping can lead to certain pop-portunities being missed
d. show that our version has teeth, and that it approximates Sivaraman's
    - introduce simulator, visualization tool
    - instantiate the OCaml model twice: once in Sivaraman's style and once in ours
    - show that the two agree on the algorithms presented in Sivaraman's paper (so far this is just a visual check)
    - TODO: realistic packet samples
    - TODO: use better metrics to quantify this approximation. stop relying on just a visual check.

4. Future Work
a. composing trees
    e.g. one tree does shaping and cannot do scheduling; it drains to another that can do scheduling but not shaping