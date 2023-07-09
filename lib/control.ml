type sched_t = State.t -> Packet.t -> Path.t * State.t
type t = { s : State.t; q : Pifotree.t; z : sched_t }

let simulate sim_length sleep pop_tick flow t =
  (* The user gives us:
     - sim_length: after how many seconds to stop simulating.
     - sleep: how long to sleep when there's no work to do.
     - pop_tick: a threshold for when next to try a pop.
     - flow: the packet flow to simulate, essentially a list of packets.
     - t: the control to simulate over.

     We assume that flow is ordered by packet time.
     We start the simulation at the time of the first packet in flow.
     We simulate for sim_length seconds.

     We need to become sensitive to _time_.
     We cannot just push packets as fast as possible,
     and we cannot pop the tree as fast as possible.

     A packet can be pushed only once its time has arrived.
     For instance, if packet n is registered in flow as arriving 5 seconds
     after the first packet, it will only be pushed into the tree 5 (or more)
     seconds after the simulation starts.
     The tree can be popped only if the time since the last pop is greater than pop_tick.
     This allows us to play with pop_tick and therfore saturate the tree.
  *)
  let start_time = Packet.time (List.hd flow) in
  let end_time = Time.add_float start_time sim_length in

  let rec helper flow time tsp state tree ans =
    (* tsp is "time since pop". The other fields are self-explanatory. *)
    if time >= end_time then (
      if flow <> [] then
        Printf.printf
          "Warning: not every packet was pushed at the time simulation ended. \
           The flow has %d packet(s).\n"
          (List.length flow);
      if Pifotree.size tree > 0 then
        Printf.printf
          "Warning: not every packet was popped at the time simulation ended. \
           The tree has %d packet(s).\n"
          (Pifotree.size tree);
      List.rev ans)
    else if tsp >= pop_tick then
      if Pifotree.size tree = 0 then
        (* The simulator was ready to pop, but there were no packets in the tree.
           Recurse with tsp = 0.0.
        *)
        helper flow time 0.0 state tree ans
      else
        match Pifotree.pop tree with
        | None -> failwith "The tree was nonempty, but pop returned None."
        | Some (pkt, tree') ->
            (* Made progress by popping. Add to answer and recurse. *)
            helper flow time 0.0 state tree' (Packet.punch_out pkt time :: ans)
    else
      (* If no pop-work is due, try to push. *)
      match flow with
      (* No more packets to push. Sleep and recurse. *)
      | [] ->
          helper flow (Time.add_float time sleep) (tsp +. sleep) state tree ans
      (* We have a packet to push. *)
      | pkt :: flow' ->
          (* But is it ready to be scheduled? *)
          if time >= Packet.time pkt then
            (* Yes. Push it. *)
            let path, state' = t.z state pkt in
            let tree' = Pifotree.push tree (Packet.punch_in pkt time) path in
            (* Recurse with tsp = 0.0. *)
            helper flow' time tsp state' tree' ans
          else
            (* Packet wasn't ready to push.
               Sleep and recurse, restoring flow to its previous state. *)
            helper flow
              (Time.add_float time sleep)
              (tsp +. sleep) state tree ans
  in
  helper flow start_time 0.0 t.s t.q []
(* It proves useful to extract and pass copies of the state (t.s) and tree (t.q).
   The scheduling transaction (t.z) does not tend to change during a simulation,
   so we don't pass it in.
*)
