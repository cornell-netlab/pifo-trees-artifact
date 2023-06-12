type t = Star | Node of t list

(* It is sometimes convenient to temporarily index the topology with int indices. *)
type addr_t = int list

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

let sprint_addr (addr : addr_t) =
  Printf.sprintf "[ %s ]" (String.concat "; " (List.map string_of_int addr))

let rec treeify pq =
  match Pifo.length pq with
  | 0 -> failwith "Cannot treeify empty PQ."
  | 1 -> fst (Pifo.top_exn pq)
  | _ -> (
      let (first, ht), pq' = Pifo.pop_exn pq in
      (* Found one tree with some height `ht`. *)
      match Pifo.pop_if pq' (fun (_, ht') -> ht = ht') with
      | Some ((second, _), pq'') ->
          (* Now found a _second_ tree with the same height.
             Make them siblings, push the new Node into the PQ, and proceed.
          *)
          let new_tree = Node [ first; second ] in
          let pq''' = Pifo.push pq'' (new_tree, ht + 1) in
          treeify pq'''
      | None ->
          (* Found no more elements of this heigh `ht`!
             Reinsert the first tree that we extracted,
             but with a falsely-increased height.
             Then proceed.
          *)
          let pq'' = Pifo.push pq' (first, ht + 1) in
          treeify pq'')

let build_binary t =
  let rec helper t =
    match t with
    | Star -> t
    | Node trees -> (
        let trees' =
          List.map
            (fun t ->
              let t' = helper t in
              (t', height t'))
            trees
        in
        let pq = Pifo.of_list trees' (fun (_, a) (_, b) -> a - b) in
        match treeify pq with
        | Star -> failwith "Impossible."
        | Node trees -> Node trees)
  in
  helper t

let build_and_embed_binary t =
  let bin_tree = build_binary t in
  let mapping = Hashtbl.create 10 in
  (mapping, bin_tree)

let one_level_ternary = Node [ Star; Star; Star ]
let two_level_binary = Node [ Node [ Star; Star ]; Star ]
let two_level_ternary = Node [ Star; Star; Node [ Star; Star; Star ] ]

let three_level_ternary =
  Node [ Star; Star; Node [ Star; Star; Node [ Star; Star; Star ] ] ]

let irregular = Node [ Star; Star; Star; Node [ Star; Star; Star ] ]

let complex_binary =
  Node
    [ Node [ Node [ Star; Star ]; Star ]; Node [ Node [ Star; Star ]; Star ] ]
