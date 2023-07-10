open Pifotrees_lib

let embed_binary_verbose tree addr_list =
  let compiled_tree, map = Topo.build_binary tree in
  Printf.printf "\n\nThe tree \n\n";
  Topo.print_tree tree;
  Printf.printf "\nwill embed into the binary tree \n\n";
  Topo.print_tree compiled_tree;
  Printf.printf "\nwith the map \n\n";
  Topo.print_map map addr_list

let embed_binary_only () =
  (* A little evidence for the embedding shown in Figure 3.
     Usage: you supply which tree you want to compile, and supply a list
     (can be empty) of which address queries you want to run on the
     resulting tree.
  *)
  (* Fig 3a *)
  embed_binary_verbose Topo.one_level_ternary [ []; [ 0 ]; [ 1 ]; [ 2 ] ];
  (* Fig 3b *)
  embed_binary_verbose Topo.irregular
    [ []; [ 0 ]; [ 1 ]; [ 2 ]; [ 3 ]; [ 3; 0 ]; [ 3; 1 ]; [ 3; 2 ] ];

  (* A few more, just for fun. *)
  embed_binary_verbose Topo.one_level_binary [ []; [ 0 ]; [ 1 ] ];
  embed_binary_verbose Topo.flat_four [ []; [ 0 ]; [ 1 ]; [ 2 ]; [ 3 ] ];
  embed_binary_verbose Topo.two_level_binary
    [ []; [ 0 ]; [ 1 ]; [ 0; 0 ]; [ 0; 1 ] ];
  embed_binary_verbose Topo.irregular
    [ []; [ 0 ]; [ 1 ]; [ 2 ]; [ 3 ]; [ 3; 0 ]; [ 3; 1 ]; [ 3; 2 ] ]

let _ = embed_binary_only ()

