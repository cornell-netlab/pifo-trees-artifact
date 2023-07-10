open Pifotrees_lib

let extension_embed () =
  (* In the paper we have only really written algorithms against
     _regular ternary_ topologies
     and then compiled them to run against regular binary topologies.

     This is a little timid:
     The algorithm presented in Section 6.1 allows us to embed _any_
     topology into any regular d-ary branching topology.

     Let us walk through how we would write an algorithm against a heterogenous
     topology and then compile it to run against a regular ternary topology.
  *)
  let embed_ternary_verbose tree addr_list =
    (* Just a verbose printer so we can see what we're doing. *)
    let compiled_tree, map = Topo.build_ternary tree in
    Printf.printf "\n\nThe tree \n\n";
    Topo.print_tree tree;
    Printf.printf "\nwill embed into the ternary tree \n\n";
    Topo.print_tree compiled_tree;
    Printf.printf "\nwith the map \n\n";
    Topo.print_map map addr_list
  in
  embed_ternary_verbose Topo.irregular2
    (* This is a new topology, an extension of the topology shown in Fig 3b. *)
    [
      [];
      [ 0 ];
      [ 0; 0 ];
      [ 0; 1 ];
      [ 1 ];
      [ 2 ];
      [ 3 ];
      [ 3; 0 ];
      [ 3; 1 ];
      [ 3; 2 ];
    ]

let _ = extension_embed ()
