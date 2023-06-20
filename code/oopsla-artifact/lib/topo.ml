type t = Star | Node of t list
type addr_t = int list
type hint_t = int -> addr_t Option.t (* A partial map from int to addr. *)
type map_t = addr_t -> addr_t Option.t (* A partial map from addr to addr. *)

let ( let* ) = Option.bind

let rec height = function
  | Star -> 1
  | Node trees -> 1 + List.fold_left max 0 (List.map height trees)

let print_tree t =
  (* Just for fun, to see trees change as they are embedded.
     We convert the topology into a PrintBox tree and
     then use PrintBox_text to pretty-print to screen.
  *)
  let rec to_printbox t : PrintBox.t =
    match t with
    | Star -> PrintBox.tree (PrintBox.text "*") []
    | Node ts -> PrintBox.tree (PrintBox.text "Node") (List.map to_printbox ts)
  in
  PrintBox_text.output stdout (to_printbox t);
  print_newline ()

let print_map (map : map_t) defined_on =
  (* Pretty-prints the embedding map.
     Takes a list of addresses that you think the map should be defined on.
  *)
  let sprint_int_list l =
    let rec helper = function
      | [] -> ""
      | [ x ] -> string_of_int x
      | x :: xs -> string_of_int x ^ ", " ^ helper xs
    in
    "[" ^ helper l ^ "]"
  in
  let map_str targets =
    List.map
      (fun target ->
        Printf.sprintf "%s -> %s" (sprint_int_list target)
          (match map target with
          | None -> Printf.sprintf "_" (* Not defined. *)
          | Some x -> sprint_int_list x))
      targets
  in
  Printf.printf "{  %s  }\n" (String.concat "; " (map_str defined_on))

let pop_d_topos pq d =
  (* pq is a priority queue of (decorated) topologies, prioritized by height.
     pq has at least two elements.
     We will pop up to d of them _so long as they have the same height m_.
     We will return the popped topologies as a list, the remaining priority queue, and m.
  *)
  let rec helper pq height acc d =
    if d = 0 then (List.rev acc, pq) (* We popped d items. Success. *)
    else
      match Pifo.length pq with
      | 0 ->
          (List.rev acc, pq)
          (* Before we could pop d items, we ran the PQ empty. Success. *)
      | _ -> (
          (* We have budget for more topologies, plus the PQ has topologies.
             We'll only take them if their height is correct, though. *)
          match Pifo.pop_if pq (fun (_, _, _, height') -> height = height') with
          | None ->
              (* The next shortest topologies has height <> the target height.
                 What we have in the accumulator is the best we can do.
                 Success. *)
              (List.rev acc, pq)
          | Some (topo, pq') ->
              (* We have another topology with the right height.
                 Add it to the accumulator and recurse. *)
              helper pq' height (topo :: acc) (d - 1))
  in
  (* Pop the top topology to prime the algorithm. *)
  let ((_, _, _, m) as topo_one), pq' = Pifo.pop_exn pq in
  (* Now we need up to d-1 more topologies, IF they have height m. *)
  let one, two = helper pq' m [ topo_one ] (d - 1) in
  (one, two, m)

let rec merge_into_one_topo pq d : t * map_t =
  (* Accepts a priority queue of PIFO trees ordered by (minimum) height.
     Each tree is further accompanied by the embedding function that maps some
     subtree of a source tree onto the tree in question.
     This method merges the PQ's trees into one tree, as described in the paper.
  *)
  match Pifo.length pq with
  | 0 -> failwith "Cannot merge an empty PQ of topologies."
  | 1 ->
      (* Success: there was just one tree left.
         Discard the hint and the height and return the tree and its map.
      *)
      let t, _, map, _ = Pifo.top_exn pq in
      (t, map)
  | _ -> (
      (* Extract up to d trees with minimum height m. *)
      let trees, pq', m = pop_d_topos pq d in
      match trees with
      | [ (topo, hint, map, _) ] ->
          (* There was just one tree with height m.
             Reinsert it with height m+1 and recurse.
          *)
          let pq'' = Pifo.push pq' (topo, hint, map, m + 1) in
          merge_into_one_topo pq'' d
      | _ ->
          (* There were two or more trees with height m.
             Pad the tree list with Stars until it has length d.
             Then make a new node with those d topologies as its children.
             Make, also, a new embedding map and a new hint map.
          *)
          let k = List.length trees in
          let trees' =
            trees
            @ List.init (d - k) (fun _ ->
                  (Star, (fun _ -> None), (fun _ -> None), 1))
          in
          let node = Node (List.map (fun (t, _, _, _) -> t) trees') in
          (* This is the new node. *)
          (* For the map and the hint, it will pay to tag the trees' list with integers. *)
          let trees'' =
            List.mapi (fun i (a, b, c, d) -> (i, a, b, c, d)) trees'
          in
          (* The hint map is just the union of the hints of the children. *)
          let map = function
            | [] -> Some []
            | n :: rest ->
                (* The step n will determine which of our children we'll rely on.
                   The rest of the address will be processed by that child's map.
                   Which, if any, of the hints in trees'' have a value registered for n?
                *)
                let* i, _, hint_i, map_i, _ =
                  List.find_opt
                    (fun (_, _, hint, _, _) -> hint n <> None)
                    trees''
                in
                (* If none of my children can get to it, neither can I.
                   But if my i'th child knows how to get to it, I'll go via that child. *)
                let* x = hint_i n in
                (* Now we have the rest of the address, but we need to prepend i. *)
                Some ((i :: x) @ Option.get (map_i rest))
          in
          (* Add the new node to the priority queue. *)
          let hint n =
            (* The new hint for the node is the union of the children's hints,
               but, since we are growing taller by one level, we need to arbitrate
               _between_ those d children using 0, 1, ..., d-1 as a prefix.
            *)
            let* i, _, hint_i, _, _ =
              List.find_opt (fun (_, _, hint, _, _) -> hint n <> None) trees''
            in
            (* If none of my children can get to it, neither can I.
               But if my i'th child knows how to get to it, I'll go via that child. *)
            let* x = hint_i n in
            Some (i :: x)
          in
          (* The height of this tree is clearly one more than its children. *)
          let height = m + 1 in
          (* Add the new node to the priority queue. *)
          let pq'' = Pifo.push pq' (node, hint, map, height) in
          (* Recurse. *)
          merge_into_one_topo pq'' d)

let rec build_d_ary d = function
  | Star ->
      (* The embedding of a Star is a Star, and the map is the identity for []. *)
      (Star, fun addr -> if addr = [] then Some [] else None)
  | Node ts ->
      let (ts' : (t * hint_t * map_t * int) list) =
        (* We will decorate this list of subtrees a little. *)
        List.mapi
          (fun i t ->
            (* Get embeddings and maps for the subtrees. *)
            let t', map = build_d_ary d t in
            (* For each child, creat a hints map that just has
               the binding i -> Some []. *)
            let hint addr = if addr = i then Some [] else None in
            (* Get the height of this tree. *)
            let height = height t' in
            (* Put it all together. *)
            (t', hint, map, height))
          ts
      in
      (* A PIFO of these decorated subtrees, prioritized by height.
         Shorter is higher-priority.
      *)
      let pq = Pifo.of_list ts' (fun (_, _, _, a) (_, _, _, b) -> a - b) in
      merge_into_one_topo pq d

let build_binary = build_d_ary 2

let rec remove_prefix (prefix : addr_t) (addr : addr_t) =
  (* Maybe this is unduly specific to addresses, but ah well. *)
  match (prefix, addr) with
  | [], addr -> addr
  | p :: prefix, a :: addr ->
      if p = a then remove_prefix prefix addr
      else failwith "Prefix does not match address."
  | _ -> failwith "Prefix does not match address."

let rec add_prefix prefix r path_rest =
  match prefix with
  | [] -> path_rest
  | j :: prefix ->
      (* Add (j,r) to the path path_rest. *)
      (j, r) :: add_prefix prefix r path_rest

let rec lift_tilde (f : map_t) tree (path : Path.t) =
  (* Topology tree can embed into some topology tree'.
     We don't need tree' as an argument.
     We have f, the partial map that takes
     addresses in tree to addresses in tree'.
     Given a path in tree, we want to find the corresponding path in tree'.
  *)
  match (tree, path) with
  | Star, [ _ ] ->
      (* When the toplogy is a star, the embedded topology is also a Star.
         The path better be a singleton; we can check with via pattern-matching.
         We return the path unchanged.
      *)
      path
  | Node ts, (i, r) :: pt ->
      (* When the topology is a node, the embedded topology is a node.
         The path better be a non-empty list; we can check with via pattern-matching.
         If this node embeds into node' in the embedded topology,
         this node's ith child embeds somewhere under node' in the embedded topology.
      *)
      let f_i addr =
        (* First we compute that embedding.
           We need to check what f would have said about (i::addr).
           The resultant list has some prefix that is f's answer for [i] alone.
           We must remove that prefix.
        *)
        let* whole = f (i :: addr) in
        let* prefix = f [ i ] in
        Some (remove_prefix prefix whole)
      in
      let path_rest = lift_tilde f_i (List.nth ts i) pt in
      (* We are not done.
         For each j in the prefix, we must add (j,r) to the front of path_rest.
      *)
      add_prefix (Option.get (f [ i ])) r path_rest
  | _ -> failwith "Topology and path do not match."

(* A few topologies to play with. *)
let one_level_ternary = Node [ Star; Star; Star ]
let one_level_binary = Node [ Star; Star ]
let two_level_binary = Node [ Node [ Star; Star ]; Star ]
let two_level_ternary = Node [ Star; Star; Node [ Star; Star; Star ] ]

let three_level_ternary =
  Node [ Star; Star; Node [ Star; Star; Node [ Star; Star; Star ] ] ]

let irregular = Node [ Star; Star; Star; Node [ Star; Star; Star ] ]
let four_wide = Node [ Star; Star; Star; Star ]
