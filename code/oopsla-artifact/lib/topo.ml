type t = Star | Node of t list
type addr_t = int list
type mapping_t = addr_t -> addr_t Option.t (* A partial map from addr to addr *)

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

(*let sprint_int_list l =
   let rec helper l =
     match l with
     | [] -> ""
     | [ x ] -> string_of_int x
     | x :: xs -> string_of_int x ^ ", " ^ helper xs
   in
   "[" ^ helper l ^ "]"

  let print_mapping ((partial_fun, defined_on) : mapping_t) =
    let rec helper targets =
      match targets with
      | [] -> ()
      | target :: rest ->
          Printf.printf "%s -> %s\n" (sprint_int_list target)
            (match partial_fun target with
            | None ->
                failwith "Mapping is not complete when it was expected to be!"
            | Some x -> sprint_int_list x);
          helper rest
    in
    helper defined_on *)

let rec treeify (pq : (t * mapping_t * int) Pifo.t) : t * mapping_t =
  match Pifo.length pq with
  | 0 -> failwith "Cannot treeify empty PQ."
  | 1 ->
      (* Success: there was just one tree of height _height. *)
      let t, mapping, _height = Pifo.top_exn pq in
      (t, mapping)
  | _ ->
      (* Grab the shortest two trees. *)
      let (a, map_a, height_a), pq' = Pifo.pop_exn pq in
      let (b, map_b, height_b), pq'' = Pifo.pop_exn pq' in
      (* Do they have the same height? *)
      if height_a = height_b then
        (* Yes: make a new node, plus a new mapping. *)
        let new_node = Node [ a; b ] in
        let new_map addr =
          match addr with
          | [] -> Some []
          | steps -> (
              match (map_a steps, map_b steps) with
              | None, None -> None
              | Some x, None -> Some (0 :: x)
              | None, Some x -> Some (1 :: x)
              | Some _, Some _ -> failwith "Impossible.")
        in
        (* Add the new node to the PQ. *)
        (* The height of this tree is clearly one more than its children. *)
        let pq''' = Pifo.push pq'' (new_node, new_map, height_a + 1) in
        treeify pq'''
      else
        (* No: reinsert the two trees, the first with its height artificially increased by one, and try again. *)
        let pq''' =
          Pifo.push
            (Pifo.push pq'' (a, map_a, height_a + 1))
            (b, map_b, height_b)
        in
        treeify pq'''

let build_binary t =
  let rec helper t : t * mapping_t =
    match t with
    | Star -> (t, fun _ -> None)
    | Node ts ->
        let (ts' : (t * mapping_t * int) list) =
          List.mapi
            (fun i t ->
              (* Get embeddings and mappings for all of this node's children. *)
              let t', mapping = helper t in
              (* For each child, add the partial map i -> [] to its mapping function. *)
              let mapping_fn addr =
                if addr = [ i ] then Some [] else mapping addr
              in
              (* AM: should this be None? *)
              (* Get the height of this tree. *)
              let height = height t' in
              (* Put it all together. *)
              (t', mapping_fn, height))
            ts
        in
        let pq = Pifo.of_list ts' (fun (_, _, a) (_, _, b) -> a - b) in
        treeify pq
  in
  helper t

let one_level_ternary = Node [ Star; Star; Star ]
let two_level_binary = Node [ Node [ Star; Star ]; Star ]
let two_level_ternary = Node [ Star; Star; Node [ Star; Star; Star ] ]

let three_level_ternary =
  Node [ Star; Star; Node [ Star; Star; Node [ Star; Star; Star ] ] ]

let irregular = Node [ Star; Star; Star; Node [ Star; Star; Star ] ]

let complex_binary =
  Node
    [ Node [ Node [ Star; Star ]; Star ]; Node [ Node [ Star; Star ]; Star ] ]
