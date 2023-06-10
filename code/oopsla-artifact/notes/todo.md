
* print linerate, weights, etc on the plot to reduce accounting burden
* computation pass that converts a local-minded tree into a global-minded tree
* compile one global-minded tree into another
    * is there a clean way to describe the big brain's partition decision, such that the decision is tree-specific and automatically carries over to the new tree? 
    for example in the ternary-to-binary case we have it easy: the partition is simply 
        if leaf: init_scheduler
        else: meat
    