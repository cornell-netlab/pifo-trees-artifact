type t = Star | Node of t list
type addr_t = int list
type map_t = addr_t -> addr_t Option.t (* A partial map from addr to addr *)

let rec height t =
  match t with
  | Star -> 1
  | Node trees -> 1 + List.fold_left max 0 (List.map height trees)

let print_tree t =
  (* Just for fun, to see trees change as they are embedded. *)
  let rec print_tree_helper space t =
    match t with
    | Star -> Printf.printf "%s *\n" space
    | Node trees ->
        Printf.printf "%s *--------\n" space;
        ignore (List.map (print_tree_helper (space ^ "\t")) trees)
  in
  print_tree_helper "" t;
  print_newline ()

let sprint_int_list l =
  let rec helper l =
    match l with
    | [] -> ""
    | [ x ] -> string_of_int x
    | x :: xs -> string_of_int x ^ ", " ^ helper xs
  in
  "[" ^ helper l ^ "]"

let print_map (map : map_t) defined_on =
  let rec helper targets =
    match targets with
    | [] -> ()
    | target :: rest ->
        Printf.printf "%s -> %s\n" (sprint_int_list target)
          (match map target with
          | None -> Printf.sprintf "_"
          | Some x -> sprint_int_list x);
        helper rest
  in
  helper defined_on

let rec treeify (pq : (t * map_t * int) Pifo.t) : t * map_t =
  match Pifo.length pq with
  | 0 -> failwith "Cannot treeify empty PQ."
  | 1 ->
      (* Success: there was just one tree of height _height.
         Discard the height and return the tree and its map.
      *)
      let t, map, _height = Pifo.top_exn pq in
      (t, map)
  | _ ->
      (* Extract the shortest two trees. *)
      let (a, map_a, height_a), pq' = Pifo.pop_exn pq in
      let (b, map_b, height_b), pq'' = Pifo.pop_exn pq' in
      (* Do they have the same height? *)
      if height_a = height_b then
        (* Yes: make a new node, plus a new map. *)
        let node' = Node [ a; b ] in
        let map' addr =
          if addr = [] then Some []
          else
            match (map_a addr, map_b addr) with
            | None, None ->
                (* If neither of my children can get to it, neither can I. *)
                Printf.printf "Treeifying the trees:\n";
                print_tree a;
                Printf.printf "and\n";
                print_tree b;
                Printf.printf "but neither had maps defined on address %s.\n%!"
                  (sprint_int_list addr);
                None
            | Some x, None ->
                (* If my left child knows how to get to it, I'll go via left. *)
                Some (0 :: x)
            | None, Some x ->
                (* If my right child knows how to get to it, I'll go via right. *)
                Some (1 :: x)
            | Some x, Some y ->
                (* Impossible? *)
                Printf.printf "Treeifying the trees:\n";
                print_tree a;
                print_map map_a [ [ 0 ]; [ 1 ] ];
                Printf.printf "and\n";
                print_tree b;
                print_map map_b [ [ 0 ]; [ 1 ] ];
                Printf.printf
                  "but both the trees I extracted had maps defined on address \
                   %s. They are %s and %s.\n\
                   %!"
                  (sprint_int_list addr) (sprint_int_list x) (sprint_int_list y);
                failwith
                  "Impossible: both children have maps defined on the same \
                   address."
        in
        (* Add the new node to the PQ. *)
        (* The height of this tree is clearly one more than its children. *)
        let pq''' = Pifo.push pq'' (node', map', height_a + 1) in
        treeify pq'''
      else
        (* No: reinsert the two trees, the first with its height artificially increased by one, and try again. *)
        let pq''' =
          Pifo.push
            (Pifo.push pq'' (a, map_a, height_a + 1))
            (b, map_b, height_b)
        in
        treeify pq'''

let rec build_binary t =
  match t with
  | Star ->
      (* The embedding of a star is a star, and the map is the identity for []. *)
      (Star, fun addr -> if addr = [] then Some [] else None)
  | Node ts ->
      let (ts' : (t * map_t * int) list) =
        (* We will decorate this list of subtrees a little. *)
        List.mapi
          (fun i t ->
            (* Get embeddings and maps for the subtrees. *)
            let t', map = build_binary t in
            (* For each child, add the binding `i -> []`
               to its map if it does not already have it. *)
            (* let map' addr = if map [ i ] = None then Some [] else map addr in *)
            let map' addr =
              if addr = [ i ] && map [ i ] = None then Some [] else map addr
            in
            (* AM: I think there is a bug here. *)
            (* Get the height of this tree. *)
            let height = height t' in
            (* Put it all together. *)
            (t', map', height))
          ts
      in
      (* A PIFO of these decorated subtrees, prioritized by height.
         Shorter is higher-priority.
      *)
      let pq = Pifo.of_list ts' (fun (_, _, a) (_, _, b) -> a - b) in
      treeify pq

let one_level_ternary = Node [ Star; Star; Star ]
let one_level_binary = Node [ Star; Star ]
let two_level_binary = Node [ Node [ Star; Star ]; Node [ Star; Star ] ]
let two_level_ternary = Node [ Star; Star; Node [ Star; Star; Star ] ]

let three_level_ternary =
  Node [ Star; Star; Node [ Star; Star; Node [ Star; Star; Star ] ] ]

let irregular = Node [ Star; Star; Star; Node [ Star; Star; Star ] ]

let complex_binary =
  Node
    [ Node [ Node [ Star; Star ]; Star ]; Node [ Node [ Star; Star ]; Star ] ]
