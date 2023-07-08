open Pifotrees_lib
open Alg

let fcfs_flow = Packet.pkts_from_file "../pcaps/fcfs_generated.pcap"
let strict_flow = Packet.pkts_from_file "../pcaps/strict_generated.pcap"
let rr_flow = Packet.pkts_from_file "../pcaps/rr_generated.pcap"
let wfq_flow = Packet.pkts_from_file "../pcaps/wfq_generated.pcap"
let two_then_three = Packet.pkts_from_file "../pcaps/two_then_three.pcap"
let five_flows = Packet.pkts_from_file "../pcaps/five_flows.pcap"
let seven_flows = Packet.pkts_from_file "../pcaps/seven_flows.pcap"

let run simulate_fn flow name =
  (* Duration of time after which to cut off simulation. *)
  let sim_length = 20.0 in
  let c = simulate_fn sim_length flow in
  (* How do we want to render pushed-but-unpopped items?
   * false: blank lines
   * true: colored lines that go until the far right.
   *)
  let show_unpopped = false in
  let overdue =
    if show_unpopped then Time.of_float sim_length else Time.of_float 0.0
  in
  Packet.write_to_csv c overdue (Printf.sprintf "../../output%s.csv" name)

let embed_verbose tree addr_list =
  let compiled_tree, map = Topo.build_binary tree in
  Printf.printf "\n\nThe tree \n\n";
  Topo.print_tree tree;
  Printf.printf "\nwill embed into the tree \n\n";
  Topo.print_tree compiled_tree;
  Printf.printf "\nwith the map \n\n";
  Topo.print_map map addr_list

let embedding_only () =
  (* A little evidence for the embedding shown in Figure 3.
     Usage: you supply which tree you want to compile, and supply a list
     (can be empty) of which address queries you want to run on the
     resulting tree.
  *)
  (* Fig 3a *)
  embed_verbose Topo.one_level_ternary [ []; [ 0 ]; [ 1 ]; [ 2 ] ];
  (* Fig 3b *)
  embed_verbose Topo.irregular
    [ []; [ 0 ]; [ 1 ]; [ 2 ]; [ 3 ]; [ 3; 0 ]; [ 3; 1 ]; [ 3; 2 ] ];

  (* A few more, just for fun. *)
  embed_verbose Topo.one_level_binary [ []; [ 0 ]; [ 1 ] ];
  embed_verbose Topo.four_wide [ []; [ 0 ]; [ 1 ]; [ 2 ]; [ 3 ] ];
  embed_verbose Topo.two_level_binary [ []; [ 0 ]; [ 1 ]; [ 0; 0 ]; [ 0; 1 ] ];
  embed_verbose Topo.irregular
    [ []; [ 0 ]; [ 1 ]; [ 2 ]; [ 3 ]; [ 3; 0 ]; [ 3; 1 ]; [ 3; 2 ] ]

let simulate_handwritten () =
  run FCFS_Ternary.simulate fcfs_flow "fcfs";
  run Strict_Ternary.simulate strict_flow "strict";
  run RRobin_Ternary.simulate rr_flow "rr";
  run WFQ_Ternary.simulate wfq_flow "wfq";
  run HPFQ_Binary.simulate two_then_three "hpfq";
  run TwoPol_Ternary.simulate five_flows "twopol";
  run ThreePol_Ternary.simulate seven_flows "threepol"

let simulate_binary () =
  run FCFS_Ternary_Bin.simulate fcfs_flow "fcfs_bin";
  run Strict_Ternary_Bin.simulate strict_flow "strict_bin";
  run RRobin_Ternary_Bin.simulate rr_flow "rr_bin";
  run WFQ_Ternary_Bin.simulate wfq_flow "wfq_bin";
  run TwoPol_Ternary_Bin.simulate five_flows "twopol_bin";
  run ThreePol_Ternary_Bin.simulate seven_flows "threepol_bin"

let _ = embedding_only ()
(* let _ = simulate_handwritten () *)
(* let _ = simulate_binary () *)
