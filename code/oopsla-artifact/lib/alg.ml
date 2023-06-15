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

module type Alg_t = sig
  val topology : Topo.t
  val control : Control.t
  val simulate : float -> Packet.t list -> Packet.t list
end

module FCFS_Ternary : Alg_t = struct
  let scheduling_transaction (s : State.t) pkt =
    let time = Packet.time pkt in
    match find_flow pkt with
    | "A" -> ([ (0, Rank.create 0.0 time); (0, Rank.create 0.0 time) ], s)
    | "B" -> ([ (1, Rank.create 0.0 time); (0, Rank.create 0.0 time) ], s)
    | "C" -> ([ (2, Rank.create 0.0 time); (0, Rank.create 0.0 time) ], s)
    (* Put flow A into leaf 0, flow B into leaf 1, and flow C into leaf 2.
       The ranks at the root are straightforward: nothing fancy to do with
       the float portion proper, but we do register the time of the packet's
       scheduling. This means that FCFS prevails overall.
       Doing the same thing at the leaves means that FCFS prevails there too.
       Going forward, we will frequently give the the leaves FCFS scheduling in this way.

       Recall that the fist element of the foot of a path is ignored.
       | "A" -> ([ (0, Rank.create 0.0 time); (0, Rank.create 0.0 time) ], s)
                                              ^^^
                                            ignored
    *)
    | n -> failwith Printf.(sprintf "Don't know how to route flow %s." n)

  let topology = Topo.one_level_ternary

  let control : Control.t =
    {
      s = State.create 1;
      q = Pifotree.create topology;
      z = scheduling_transaction;
    }

  let simulate end_time pkts =
    Control.simulate end_time 0.001 poprate pkts control
end

module Strict_Ternary : Alg_t = struct
  let scheduling_transaction (s : State.t) pkt =
    let time = Packet.time pkt in
    let int_for_root, rank_for_root =
      (* Put flow A into leaf 0, flow B into leaf 1, and flow C into leaf 2.
         The ranks at the root are set up to prefer C to B, and B to A.
      *)
      match find_flow pkt with
      | "A" -> (0, Rank.create 2.0 time)
      | "B" -> (1, Rank.create 1.0 time)
      | "C" -> (2, Rank.create 0.0 time)
      | n -> failwith Printf.(sprintf "Don't know how to route flow %s." n)
    in
    ([ (int_for_root, rank_for_root); (0, Rank.create 0.0 time) ], s)

  let topology = Topo.one_level_ternary

  let control : Control.t =
    {
      s = State.create 1;
      q = Pifotree.create topology;
      z = scheduling_transaction;
    }

  let simulate end_time pkts =
    Control.simulate end_time 0.001 poprate pkts control
end

module RRobin_Ternary : Alg_t = struct
  let scheduling_transaction s pkt =
    let time = Packet.time pkt in
    let flow = find_flow pkt in
    let var_last_finish = Printf.sprintf "%s_last_finish" flow in
    (* We will use this variable to read/write to state. *)
    let rank_for_root =
      if State.isdefined var_last_finish s then
        max (Time.to_float time) (State.lookup var_last_finish s)
      else Time.to_float time
    in
    let s' =
      State.rebind var_last_finish (rank_for_root +. (100.0 /. 0.33)) s
    in
    let rank_for_root = Rank.create rank_for_root time in
    let int_for_root =
      (* Put flow A into leaf 0, flow B into leaf 1, and flow C into leaf 2. *)
      match flow with
      | "A" -> 0
      | "B" -> 1
      | "C" -> 2
      | n -> failwith Printf.(sprintf "Don't know how to route flow %s." n)
    in
    ([ (int_for_root, rank_for_root); (0, Rank.create 0.0 time) ], s')

  let topology = Topo.one_level_ternary

  let control : Control.t =
    {
      s = State.create 3;
      q = Pifotree.create topology;
      z = scheduling_transaction;
    }

  let simulate end_time pkts =
    Control.simulate end_time 0.001 poprate pkts control
end

let wfq_helper s weight var_last_finish pkt_len time : Rank.t * State.t =
  (* The WFQ-style algorithms have a common pattern,
      so we lift it into this helper.
  *)
  let rank =
    if State.isdefined var_last_finish s then
      max (Time.to_float time) (State.lookup var_last_finish s)
    else Time.to_float time
  in
  let s' = State.rebind var_last_finish (rank +. (pkt_len /. weight)) s in
  (Rank.create rank time, s')

module WFQ_Ternary : Alg_t = struct
  let scheduling_transaction s pkt =
    let time = Packet.time pkt in
    let flow = find_flow pkt in
    let var_last_finish = Printf.sprintf "%s_last_finish" flow in
    let var_weight = Printf.sprintf "%s_weight" flow in
    let weight = State.lookup var_weight s in
    let rank_for_root, s' =
      wfq_helper s weight var_last_finish (Packet.len pkt) time
    in
    let int_for_root =
      (* Put flow A into leaf 0, flow B into leaf 1, and flow C into leaf 2. *)
      match flow with
      | "A" -> 0
      | "B" -> 1
      | "C" -> 2
      | n -> failwith Printf.(sprintf "Don't know how to route flow %s." n)
    in
    ([ (int_for_root, rank_for_root); (0, Rank.create 0.0 time) ], s')

  let topology = Topo.one_level_ternary

  let control : Control.t =
    {
      s =
        State.create 6
        |> State.rebind "A_weight" 0.1
        |> State.rebind "B_weight" 0.2
        |> State.rebind "C_weight" 0.3;
      q = Pifotree.create topology;
      z = scheduling_transaction;
    }

  let simulate end_time pkts =
    Control.simulate end_time 0.001 poprate pkts control
end

module HPFQ_Binary : Alg_t = struct
  let scheduling_transaction s pkt =
    let time = Packet.time pkt in
    let flow = find_flow pkt in
    (* This is either A, B, or C.
       When computing ranks for the root, we arbitrate between AB or C.
       When computing ranks for the left node, we arbitrate between A or B.
    *)
    match flow with
    | "A" ->
        let rank_for_root, s' =
          wfq_helper s
            (State.lookup "AB_weight" s)
            "AB_last_finish" (Packet.len pkt) time
        in
        let rank_for_left_node, s'' =
          wfq_helper s'
            (State.lookup "A_weight" s')
            "A_last_finish" (Packet.len pkt) time
        in
        ( [
            (0, rank_for_root);
            (0, rank_for_left_node);
            (0, Rank.create 0.0 time);
          ],
          s'' )
    | "B" ->
        let rank_for_root, s' =
          wfq_helper s
            (State.lookup "AB_weight" s)
            "AB_last_finish" (Packet.len pkt) time
        in
        let rank_for_left_node, s'' =
          wfq_helper s'
            (State.lookup "B_weight" s')
            "B_last_finish" (Packet.len pkt) time
        in
        ( [
            (0, rank_for_root);
            (1, rank_for_left_node);
            (0, Rank.create 0.0 time);
          ],
          s'' )
    | "C" ->
        let rank_for_root, s' =
          wfq_helper s
            (State.lookup "C_weight" s)
            "C_last_finish" (Packet.len pkt) time
        in
        ([ (1, rank_for_root); (0, Rank.create 0.0 time) ], s')
    | n -> failwith Printf.(sprintf "Don't know how to route flow %s." n)

  let topology = Topo.two_level_binary

  let control : Control.t =
    {
      s =
        State.create 8
        |> State.rebind "AB_weight" 0.8
        |> State.rebind "A_weight" 0.75
        |> State.rebind "B_weight" 0.25
        |> State.rebind "C_weight" 0.2;
      q = Pifotree.create topology;
      z = scheduling_transaction;
    }

  let simulate end_time pkts =
    Control.simulate end_time 0.001 poprate pkts control
end

module TwoPol_Ternary : Alg_t = struct
  let scheduling_transaction s pkt =
    let time = Packet.time pkt in
    let flow = find_flow pkt in
    (* This is either A, B, C, D, or E.
       When computing ranks for the root, we arbitrate between A, B, or CDE.
       When computing ranks for the right node, we arbitrate between C, D, or E.
    *)
    match flow with
    | "A" ->
        let rank_for_root, s' =
          wfq_helper s
            (State.lookup "A_weight" s)
            "A_last_finish" (Packet.len pkt) time
        in
        ([ (0, rank_for_root); (0, Rank.create 0.0 time) ], s')
    | "B" ->
        let rank_for_root, s' =
          wfq_helper s
            (State.lookup "B_weight" s)
            "B_last_finish" (Packet.len pkt) time
        in
        ([ (1, rank_for_root); (0, Rank.create 0.0 time) ], s')
    | "C" | "D" | "E" ->
        let rank_for_root, s' =
          wfq_helper s
            (State.lookup "CDE_weight" s)
            "CDE_last_finish" (Packet.len pkt) time
        in
        let int_for_right, rank_for_right =
          match flow with
          (* We want C to go to the right node's 0th child,
             D to the 1st child, and E to the 2nd child.
             Futher, we want to prioritize E over D and D over C.
          *)
          | "C" -> (0, 2.0)
          | "D" -> (1, 1.0)
          | "E" -> (2, 0.0)
          | _ -> failwith "Impossible."
        in
        ( [
            (2, rank_for_root);
            (int_for_right, Rank.create rank_for_right time);
            (0, Rank.create 0.0 time);
          ],
          s' )
    | n -> failwith Printf.(sprintf "Don't know how to route flow %s." n)

  let topology = Topo.two_level_ternary

  let control : Control.t =
    {
      s =
        State.create 6
        |> State.rebind "A_weight" 0.1
        |> State.rebind "B_weight" 0.1
        |> State.rebind "CDE_weight" 0.8;
      q = Pifotree.create topology;
      z = scheduling_transaction;
    }

  let simulate end_time pkts =
    Control.simulate end_time 0.001 poprate pkts control
end

module ThreePol_Ternary : Alg_t = struct
  let scheduling_transaction s pkt =
    let time = Packet.time pkt in
    let flow = find_flow pkt in
    (* This is either A, B, C, D, E, F, or G.
       When computing ranks for the root, we arbitrate between A, B, or CDEFG.
       When computing ranks for the right node, we arbitrate between C, D, or EFG.
       When computing ranks for the right node's right node, we arbitrate between E, F, or G.
    *)
    match flow with
    | "A" ->
        let rank_for_root, s' =
          wfq_helper s
            (State.lookup "A_weight" s)
            "A_last_finish" (Packet.len pkt) time
        in
        ([ (0, rank_for_root); (0, Rank.create 0.0 time) ], s')
    | "B" ->
        let rank_for_root, s' =
          wfq_helper s
            (State.lookup "B_weight" s)
            "B_last_finish" (Packet.len pkt) time
        in
        ([ (1, rank_for_root); (0, Rank.create 0.0 time) ], s')
    (* In addition to WFQ at the root,
       we must, at the right node, do round-robin between C, D, and EFG. *)
    | "C" ->
        let rank_for_root, s' =
          wfq_helper s
            (State.lookup "CDEFG_weight" s)
            "CDEFG_last_finish" (Packet.len pkt) time
        in
        let rank_for_right, s'' =
          let r =
            if State.isdefined "C_last_finish" s' then
              max (Time.to_float time) (State.lookup "C_last_finish" s)
            else Time.to_float time
          in
          let new_state =
            State.rebind "C_last_finish" (r +. (100.0 /. 0.33)) s'
          in
          (Rank.create r time, new_state)
        in
        ( [ (2, rank_for_root); (0, rank_for_right); (0, Rank.create 0.0 time) ],
          s'' )
    | "D" ->
        let rank_for_root, s' =
          wfq_helper s
            (State.lookup "CDEFG_weight" s)
            "CDEFG_last_finish" (Packet.len pkt) time
        in
        let rank_for_right, s'' =
          let r =
            if State.isdefined "D_last_finish" s' then
              max (Time.to_float time) (State.lookup "D_last_finish" s)
            else Time.to_float time
          in
          let new_state =
            State.rebind "D_last_finish" (r +. (100.0 /. 0.33)) s'
          in
          (Rank.create r time, new_state)
        in
        ( [ (2, rank_for_root); (1, rank_for_right); (0, Rank.create 0.0 time) ],
          s'' )
    | "E" | "F" | "G" ->
        (* In addition to WFQ at the root and round-robin at the right node,
           we must do WFQ between E, F, and G at the right node's right node. *)
        let rank_for_root, s' =
          wfq_helper s
            (State.lookup "CDEFG_weight" s)
            "CDEFG_last_finish" (Packet.len pkt) time
        in
        let rank_for_right, s'' =
          let r =
            if State.isdefined "EFG_last_finish" s' then
              max (Time.to_float time) (State.lookup "EFG_last_finish" s)
            else Time.to_float time
          in
          let new_state =
            State.rebind "EFG_last_finish" (r +. (100.0 /. 0.33)) s'
          in
          (Rank.create r time, new_state)
        in
        let rank_for_right_right, s''' =
          wfq_helper s''
            (State.lookup (Printf.sprintf "%s_weight" flow) s'')
            (Printf.sprintf "%s_last_finish" flow)
            (Packet.len pkt) time
        in
        let int_for_right_right =
          match flow with
          | "E" -> 0
          | "F" -> 1
          | "G" -> 2
          | _ -> failwith "Impossible."
        in
        ( [
            (2, rank_for_root);
            (2, rank_for_right);
            (int_for_right_right, rank_for_right_right);
            (0, Rank.create 0.0 time);
          ],
          s''' )
    | n -> failwith Printf.(sprintf "Don't know how to route flow %s." n)

  let topology = Topo.three_level_ternary

  let control : Control.t =
    {
      s =
        State.create 6
        |> State.rebind "A_weight" 0.4
        |> State.rebind "B_weight" 0.4
        |> State.rebind "CDEFG_weight" 0.2
        |> State.rebind "E_weight" 0.1
        |> State.rebind "F_weight" 0.4
        |> State.rebind "G_weight" 0.5;
      q = Pifotree.create topology;
      z = scheduling_transaction;
    }

  let simulate end_time pkts =
    Control.simulate end_time 0.001 poprate pkts control
end

module T2B (TernaryAlg : Alg_t) : Alg_t = struct
  (* We are given an algorithm of type Alg_t that is runs on a ternary tree.
     We will compile it to run on a binary tree.

     The following things about the original Alg_t are exposed:
     - topology, the bare tree that it builds a PIFO tree on
     - control, consisting of:
       + the initial state s
       + the PIFO tree q that is built from the topology
       + the scheduling transaction z.
         Given some state s and some packet pkt, z returns a pair of
         * a path pt
         * a new state s'
       - simulate, which we will not use.

     We proceed as follows:
     - We build a new binary topology that can accommodate the original ternary topology.
     - We build the embedding map f that maps addresses over the ternary topology those over the binary topology.
     - We lift f to get a map f-tilde, which maps paths over the ternary tree to paths over the binary tree.
     - From the scheduling transaction z we get a new scheduling transaction z':
       Given some state s and a packet pkt,
       z' returns pair of
       + a path: f-tilde pt
       + a new state: s'
       where pt and s' are gotten by running z s pkt.
  *)
  let topology, f = Topo.build_binary TernaryAlg.topology
  let f_tilde = Topo.lift_tilde f

  let z' s pkt =
    let pt, s' = TernaryAlg.control.z s pkt in
    (f_tilde TernaryAlg.topology pt, s')

  let control : Control.t =
    { s = TernaryAlg.control.s; q = Pifotree.create topology; z = z' }

  let simulate end_time pkts =
    Control.simulate end_time 0.001 poprate pkts control
end

module FCFS_Ternary_Bin = T2B (FCFS_Ternary)
module Strict_Ternary_Bin = T2B (Strict_Ternary)
module RRobin_Ternary_Bin = T2B (RRobin_Ternary)
module WFQ_Ternary_Bin = T2B (WFQ_Ternary)
module TwoPol_Ternary_Bin = T2B (TwoPol_Ternary)
module ThreePol_Ternary_Bin = T2B (ThreePol_Ternary)
