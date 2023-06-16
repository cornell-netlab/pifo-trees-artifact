type t = Star | Node of t list
type addr_t = int list
type hint_t = int -> addr_t Option.t (* A partial map from int to addr. *)
type map_t = addr_t -> addr_t Option.t (* A partial map from addr to addr. *)

let ( let* ) = Option.bind

let rec height = function
  | Star -> 1
  | Node trees -> 1 + List.fold_left max 0 (List.map height trees)

let print_tree t =
  (* Just for fun, to see trees change as they are embedded. *)
  let rec print_tree_helper space = function
    | Star -> Printf.printf "%s *\n" space
    | Node trees ->
        Printf.printf "%s *--------\n" space;
        ignore (List.map (print_tree_helper (space ^ "\t")) trees)
  in
  print_tree_helper "" t;
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

let rec treeify (pq : (t * hint_t * map_t * int) Pifo.t) : t * map_t =
  match Pifo.length pq with
  | 0 -> failwith "Cannot treeify empty PQ."
  | 1 ->
      (* Success: there was just one tree left.
         Discard the hint and the height and return the tree and its map.
      *)
      let t, _, map, _ = Pifo.top_exn pq in
      (t, map)
  | _ ->
      (* Extract the shortest two trees. *)
      let (a, hint_a, map_a, height_a), pq' = Pifo.pop_exn pq in
      let (b, hint_b, map_b, height_b), pq'' = Pifo.pop_exn pq' in
      (* Do they have the same height? *)
      if height_a = height_b then
        (* Yes! Make a new node, a new embedding map, and new hint map. *)
        let node = Node [ a; b ] in
        let map = function
          | [] -> Some []
          | n :: rest -> (
              (* The step n will determine which of our children we'll rely on.
                 The rest will be processed by that child's map.
              *)
              match (hint_a n, hint_b n) with
              (* If neither of my children can get to it, neither can I. *)
              | None, None -> None
              (* If my left child knows how to get to it, I'll go via left. *)
              | Some x, None -> Some ((0 :: x) @ Option.get (map_a rest))
              (* If my right child knows how to get to it, I'll go via right. *)
              | None, Some x -> Some ((1 :: x) @ Option.get (map_b rest))
              (* Clashes like this should be impossible. *)
              | Some _, Some _ -> failwith "Unification error.")
        in
        (* Add the new node to the priority queue. *)
        let hint n =
          (* The new hint for the node is the union of the children's hints,
             but, since we are growing taller by one level, we need to arbitrate
             _between_ those two children using 0 or 1 as a prefix.
          *)
          match (hint_a n, hint_b n) with
          | None, None -> None
          | Some x, None -> Some (0 :: x)
          | None, Some x -> Some (1 :: x)
          | Some _, Some _ -> failwith "Unification error."
        in
        (* The height of this tree is clearly one more than its children. *)
        let height = height_a + 1 in
        (* Add the new node to the priority queue. *)
        let pq''' = Pifo.push pq'' (node, hint, map, height) in
        (* Recurse. *)
        treeify pq'''
      else
        (* No, the two shortest trees had different heights.
           Reinsert the two trees, the first with its height artificially increased by one, and recurse. *)
        let pq''' =
          Pifo.push
            (Pifo.push pq'' (a, hint_a, map_a, height_a + 1))
            (b, hint_b, map_b, height_b)
        in
        treeify pq'''

let rec build_binary = function
  | Star ->
      (* The embedding of a Star is a Star, and the map is the identity for []. *)
      (Star, fun addr -> if addr = [] then Some [] else None)
  | Node ts ->
      let (ts' : (t * hint_t * map_t * int) list) =
        (* We will decorate this list of subtrees a little. *)
        List.mapi
          (fun i t ->
            (* Get embeddings and maps for the subtrees. *)
            let t', map = build_binary t in
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
      treeify pq

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

let complex_binary =
  Node
    [ Node [ Node [ Star; Star ]; Star ]; Node [ Node [ Star; Star ]; Star ] ]

let four_wide = Node [ Star; Star; Star; Star ]
