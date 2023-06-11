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

module FCFS_Ternary = struct
  let scheduling_transaction (s : State.t) pkt time =
    match find_flow pkt with
    | "A" -> ([ (0, Rank.create 0.0 time); (0, Rank.create 0.0 time) ], s)
    | "B" -> ([ (1, Rank.create 0.0 time); (0, Rank.create 0.0 time) ], s)
    | "C" -> ([ (2, Rank.create 0.0 time); (0, Rank.create 0.0 time) ], s)
    (* Put flow A into leaf 0, flow B into leaf 1, and flow C into leaf 2.
       The ranks at the root are straightforward: nothing fancy to do with
       the float portion proper, but we do register the time of the packet's
       scheduling. This means that FCFS prevails overall.
       Doing the same thing at the leaves means that FCFS prevails there too.

       Recall that the fist element of the foot of a path is ignored.
       | "A" -> ([ (0, Rank.create 0.0 time); (0, Rank.create 0.0 time) ], s)
                                              ^^^
                                            ignored
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

module Strict_Ternary = struct
  let scheduling_transaction (s : State.t) pkt time =
    match find_flow pkt with
    | "A" -> ([ (0, Rank.create 2.0 time); (0, Rank.create 0.0 time) ], s)
    | "B" -> ([ (1, Rank.create 1.0 time); (0, Rank.create 0.0 time) ], s)
    | "C" -> ([ (2, Rank.create 0.0 time); (0, Rank.create 0.0 time) ], s)
    (* Put flow A into leaf 0, flow B into leaf 1, and flow C into leaf 2.
       The ranks at the root are set up to prefer C to B, and B to A.
       At the leaves, we let FCFS prevail.
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
