open Util
open Pifotree

type schedule =
  Time.t -> int list -> bool -> Packet.meta -> State.t -> Rank.t * State.t

type control = { s : State.t; schedule : schedule }
type t = Pifotree.t * control

let init_scheduler _ _ _ (m : Packet.meta) s =
  (Rank.of_float (Time.to_float m.time), s)

let create baretree : t =
  let treecontrol = { s = State.create 1; schedule = init_scheduler } in
  let tree = Pifotree.create baretree in
  (tree, treecontrol)

let add_to_state k v (_, control) = State.rebind control.s k v
let modify_scheduler schedule (tree, control) = (tree, { control with schedule })

let push time pkt og_target ((og_tree, control) : t) : t =
  let rec helper target path2me (tree, control) =
    match (target, tree) with
    | [], Node _ | _ :: _, Leaf _ ->
        failwith "Push: tree structure disagrees with target path"
    | [], Leaf l ->
        let m = { (Packet.to_meta pkt) with pushed = Some time } in
        let q' = Pifo.push l.q (m, time) in
        (* a leaf is always the previous known anchor *)
        (path2me, (Leaf { q = q' }, control))
    | h :: t, Node n ->
        let path2kid = path2me @ [ h ] in
        (* recurse on my h'th child *)
        let kid = find_nth n.kids h in
        let pka, (kid', control') = helper t path2kid (kid, control) in
        let kids' = replace_nth n.kids h kid' in
        let m = { (Packet.to_meta pkt) with pka } in
        (* TODO just pass the pka to the scheduler. don't mess with meta. *)
        let rank, s' =
          control'.schedule time
            (anchor_of path2me og_tree)
            n.istransient m control'.s
        in
        let q' = Pifo.push n.q ((h, m), (rank, time)) in
        (* enqueue a reference to the kid into my own pifo *)
        let pka' = if istransient tree then pka else path2me in
        (* if I am transient, I can't improve pka. otherwise, improve it. *)
        (pka', (Node { n with kids = kids'; q = q' }, { control' with s = s' }))
  in
  snd (helper og_target [] (og_tree, control))

let pop time ((tree, control) : t) : (Packet.meta * t) option =
  let rec helper tree =
    match tree with
    | Leaf l ->
        let* (m, _), q' = Pifo.pop l.q in
        let m' = { m with popped = Some time } in
        let tree' = Leaf { q = q' } in
        Some (m', tree')
    | Node n ->
        let* ((kid_id, _), _), q' = Pifo.pop n.q in
        let kid = find_nth n.kids kid_id in
        let* ans, kid' = helper kid in
        Some (ans, Node { n with q = q'; kids = replace_nth n.kids kid_id kid' })
  in
  let* meta, tree' = helper tree in
  Some (meta, (tree', control))

let simulate end_sim node_fn st p_tick f t =
  let rec helper f time tsp t ans =
    if time >= end_sim then List.rev ans
    else if tsp >= p_tick then
      match pop time t with
      (* No more ripe packets in tree. Recurse. *)
      | None -> helper f time 0.0 t ans
      (* Made progress by popping. Recurse. *)
      | Some (meta, t') -> helper f time 0.0 t' (meta :: ans)
    else
      (* If no time-sensitive work is due, try to push *)
      match Flow.hd_tl f with
      (* No more packets to push. Sleep and recurse. *)
      | None -> helper f (Time.add_float time st) (tsp +. st) t ans
      (* We have a packet to push *)
      | Some (pkt, f') ->
          (* Is it ready to be scheduled? *)
          if time >= (Packet.to_meta pkt).time then
            (* Yes. Try pushing it. *)
            let t' = push time pkt (node_fn pkt) t in
            helper f' time tsp t' ans
          else
            (* Packet wasn't ready to push. Sleep and recurse with same flow. *)
            helper f (Time.add_float time st) (tsp +. st) t ans
  in
  let time = Flow.first_pkt_time f in
  Random.init 42;
  helper f time 0.0 t []
