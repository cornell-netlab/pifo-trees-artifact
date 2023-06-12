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

let embedding =
  (* Embedding: Figure 3 *)
  assert (Topo.to_binary Topo.one_level_ternary = Topo.two_level_binary);
  assert (Topo.to_binary Topo.irregular = Topo.complex_binary)

let _ =
  run FCFS_Ternary.simulate fcfs_flow "fcfs";
  run Strict_Ternary.simulate strict_flow "strict";
  run RRobin_Ternary.simulate rr_flow "rr";
  run WFQ_Ternary.simulate wfq_flow "wfq";
  run HPFQ_Binary.simulate two_then_three "hpfq";
  run TwoPol_Ternary.simulate five_flows "twopol";
  run ThreePol_Ternary.simulate seven_flows "threepol"
