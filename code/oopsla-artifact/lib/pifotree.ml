type t =
  | Leaf of {
      (* TODO: use a true FIFO *)
      q : (Packet.meta * Time.t) Pifo.t; (* time = pushtime *)
    }
  | Node of {
      q : ((int * Packet.meta) * (Rank.t * Time.t)) Pifo.t;
      (* int = which of my children to index to. time = pushtime *)
      kids : t list;
      istransient : bool;
    }

let istransient = function Leaf _ -> false | Node n -> n.istransient

let anchor_of og_target tree =
  let rec helper target tree ans =
    match (target, tree) with
    | [], _ ->
        (* Reached my destination.
           If it's an anchor, just return the original route.
           Else, return the route calculated so far *)
        if istransient tree then List.rev (List.tl ans) else og_target
    | _ :: _, Leaf _ -> failwith "Bad tree"
    | kid_id :: t, Node n ->
        helper t (Util.find_nth n.kids kid_id) (kid_id :: ans)
  in
  helper og_target tree []

let from_bt bt nodepifo leafpifo =
  let rec helper bt =
    match bt with
    | Baretree.Node (_, _, []) -> Leaf { q = leafpifo }
    | Baretree.Node (_, istransient, kids) ->
        Node { q = nodepifo; kids = List.map helper kids; istransient }
  in
  helper bt

let random_target tree =
  let to_bt tree =
    (* this is rather naughty. don't expose.
       a (tree -> baretree -> tree) transformation may not be consistent! *)
    let new_id =
      let n = ref 0 in
      fun () ->
        let id = !n in
        incr n;
        id
    in
    let rec helper tree =
      match tree with
      | Leaf _ -> Baretree.Node (new_id (), istransient tree, [])
      | Node n ->
          Baretree.Node (new_id (), istransient tree, List.map helper n.kids)
    in
    helper tree
  in
  Baretree.path_to_random_node (to_bt tree)

let nodepifo_cmp (_, (r1, t1)) (_, (r2, t2)) =
  (* we want FIFO order in case of rank-based ties *)
  let r = Rank.cmp r1 r2 in
  if r == 0 then (
    let t = Time.cmp t1 t2 in
    if t == 0 then
      Printf.printf "Warning: packets clashed both in rank and time\n";
    t)
  else r

let create baretree =
  let nodepifo = Pifo.create (fun a b -> nodepifo_cmp a b) in
  let leafpifo = Pifo.create (fun (_, a) (_, b) -> Time.cmp a b) in
  from_bt baretree nodepifo leafpifo
