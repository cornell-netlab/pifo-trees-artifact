open Pifotrees_lib
open Alg

let f1 = Flow.create "../pcaps/two_then_three.pcap"
let f2 = Flow.create "../pcaps/two_then_three.pcap"
let f3 = Flow.create "../pcaps/five_flows.pcap"
let f4 = Flow.create "../pcaps/seven_flows.pcap"
let fcfs_flow = Flow.create "../pcaps/fcfs_generated.pcap"
let rr_flow = Flow.create "../pcaps/rr_generated.pcap"
let strict_flow = Flow.create "../pcaps/strict_generated.pcap"
let wfq_flow = Flow.create "../pcaps/wfq_generated.pcap"

let run simulate_fn flow name =
  (* time at which to cut off simulation *)
  let end_sim = Time.add_float (Flow.first_pkt_time flow) 100.0 in
  let c = simulate_fn end_sim flow in
  (* how do we want to render pushed-but-unpopped items?
   * false: blank lines
   * true: colored lines that go until end_sim
   *)
  let show_unpopped = false in
  let overdue = if show_unpopped then end_sim else Time.of_float 0.0 in
  Packet.write_to_csv c overdue (Printf.sprintf "../../output%s.csv" name)

(* for the the basic algorithms, we will run all flows through all schedulers *)

(* the flows *)
let flows = [ f1; f2 ]

(* the basic algorithms *)
let algs =
  [
    (FCFS_Ternary.simulate FCFS_Ternary.baretree, "fcfs", fcfs_flow);
    (Strict_Ternary.simulate Strict_Ternary.baretree, "strict", strict_flow);
    (RRobin_Ternary.simulate RRobin_Ternary.baretree, "rr", rr_flow);
    (Fair_Ternary.simulate Fair_Ternary.baretree, "wfq", wfq_flow);
    (HPFQ_Binary_3.simulate HPFQ_Binary_3.baretree, "hpfq", f2);
  ]

let algs_bin =
  [
    (FCFS_Ternary_Bin.simulate FCFS_Ternary_Bin.baretree, "fcfs_bin");
    (Strict_Ternary_Bin.simulate Strict_Ternary_Bin.baretree, "strict_bin");
    (RRobin_Ternary_Bin.simulate RRobin_Ternary_Bin.baretree, "rr_bin");
    (Fair_Ternary_Bin.simulate Fair_Ternary_Bin.baretree, "fair_bin");
    (MRG_Ternary_Bin.simulate MRG_Ternary_Bin.baretree, "mrg_bin");
  ]

let algs_hier =
  [
    (* ternary versions *)
    ( Fair2_Two_Tier_Ternary.simulate Fair2_Two_Tier_Ternary.baretree,
      "fair2tier",
      f3 );
    ( Fair3_Two_Tier_Ternary'.simulate Fair3_Two_Tier_Ternary'.baretree,
      "fair2tier'",
      f4 );
    ( Fair3_Three_Tier_Ternary.simulate Fair3_Three_Tier_Ternary.baretree,
      "fair3tier",
      f4 );
    ( Fair_Strict_Two_Tier_Ternary.simulate Fair_Strict_Two_Tier_Ternary.baretree,
      "fairstrict2tier",
      f3 );
    (* binary versions *)
    ( Fair2_Two_Tier_Ternary_Bin.simulate Fair2_Two_Tier_Ternary_Bin.baretree,
      "fair2tier_bin",
      f3 );
    ( Fair3_Two_Tier_Ternary'_Bin.simulate Fair3_Two_Tier_Ternary'_Bin.baretree,
      "fair2tier'_bin",
      f4 );
    ( Fair3_Three_Tier_Ternary_Bin.simulate Fair3_Three_Tier_Ternary_Bin.baretree,
      "fair3tier_bin",
      f4 );
    ( Fair_Strict_Two_Tier_Ternary_Bin.simulate
        Fair_Strict_Two_Tier_Ternary_Bin.baretree,
      "fairstrict2tier_bin",
      f3 );
  ]

let _ = List.map (fun (alg, name, flow) -> run alg flow name) (algs @ algs_hier)

(* @ algs_hier) *)
