let sleeptime = 0.0005
let poprate = 0.25

let find_flow p =
  (* In pcap_gen.py, we create packets with sources based on their MAC addresses.
     After going through our parser, those packets' sources get converted into
     inscrutable integers.
     This little function converts those integers back into human-readable strings.
  *)
  match Packet.src p with
  | 17661175009296 -> "A" (* Used to be address 10:10:10:10:10:10. *)
  | 35322350018592 -> "B" (* 20...*)
  | 52983525027888 -> "C" (* 30...*)
  | 70644700037184 -> "D" (* 40...*)
  | 88305875046480 -> "E" (* 50...*)
  | 105967050055776 -> "F" (* 60...*)
  | 123628225065072 -> "G" (* 70...*)
  | n -> failwith Printf.(sprintf "Unknown source address: %d." n)

let findpath_one_level_ternary pkt =
  (* The eventual goal is to arrive at the Path.t for this packet to be
     inserted into a PIFO tree having the topology one_level_ternary.
     This function get us part of the way there:
     it tells us the route, but not the ranks.
  *)
  match find_flow pkt with
  | "A" -> [ 0 ]
  | "B" -> [ 1 ]
  | "C" -> [ 2 ]
  | n -> failwith Printf.(sprintf "Don't know how to route flow %s." n)

module FCFS_Ternary = struct
  let control : Control.t = Control.create Topo.one_level_ternary

  let simulate end_time pkts =
    Control.simulate end_time 0.001 poprate pkts control
end
