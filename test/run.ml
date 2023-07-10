open Pifotrees_lib

let fcfs_flow = Packet.pkts_from_file "../pcaps/fcfs_generated.pcap"
let strict_flow = Packet.pkts_from_file "../pcaps/strict_generated.pcap"
let rr_flow = Packet.pkts_from_file "../pcaps/rr_generated.pcap"
let wfq_flow = Packet.pkts_from_file "../pcaps/wfq_generated.pcap"
let two_then_three = Packet.pkts_from_file "../pcaps/two_then_three.pcap"
let four_flows = Packet.pkts_from_file "../pcaps/four_flows.pcap"
let five_flows = Packet.pkts_from_file "../pcaps/five_flows.pcap"
let seven_flows = Packet.pkts_from_file "../pcaps/seven_flows.pcap"

let run simulate_fn flow name =
  let sim_length = 20.0 in
  (* Duration of time after which to cut off simulation. *)
  let popped_pkts = simulate_fn sim_length flow in
  (* Run the simulation; store the results. *)
  let show_unpopped = false in
  (* How do we want to render pushed-but-unpopped items?
   * false: blank lines
   * true: colored lines that go until the far right.
   *)
   let overdue =
    if show_unpopped then Time.of_float sim_length else Time.of_float 0.0
  in
  (* Write the result to a CSV file. *)
  Packet.write_to_csv popped_pkts overdue (Printf.sprintf "../../output%s.csv" name)

