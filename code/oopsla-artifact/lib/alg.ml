let poprate = 0.25 (* Four packets per second. *)

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
  let scheduling_transaction (s : State.t) pkt =
    match find_flow pkt with
    | "A" -> ([ (0, Rank.of_float 0.0); (0, Rank.of_float 0.0) ], s)
    | "B" -> ([ (1, Rank.of_float 0.0); (0, Rank.of_float 0.0) ], s)
    | "C" -> ([ (2, Rank.of_float 0.0); (0, Rank.of_float 0.0) ], s)
    (* Put flow A into leaf 0, flow B into leaf 1, and flow C into leaf 2.
       The ranks at the root are kept the same (0), so FCFS prevails overall.
       The ranks at the leaves are also kept the same (0), so FCFS prevails at the leaves.
       Recall that the fist element of the foot of a path is ignored.
    *)
    | n -> failwith Printf.(sprintf "Don't know how to route flow %s." n)

  let control : Control.t =
    {
      s = State.create 1;
      q = Pifotree.create Topo.one_level_ternary;
      z = scheduling_transaction;
    }

  let simulate end_time pkts =
    Control.simulate end_time 0.001 poprate pkts control
end
