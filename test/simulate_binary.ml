open Pifotrees_lib
open Alg
open Run

let simulate_binary () =
  run FCFS_Ternary_Bin.simulate fcfs_flow "fcfs_bin";
  run Strict_Ternary_Bin.simulate strict_flow "strict_bin";
  run RRobin_Ternary_Bin.simulate rr_flow "rr_bin";
  run WFQ_Ternary_Bin.simulate wfq_flow "wfq_bin";
  run TwoPol_Ternary_Bin.simulate five_flows "twopol_bin";
  run ThreePol_Ternary_Bin.simulate seven_flows "threepol_bin"

let _ = simulate_binary ()

