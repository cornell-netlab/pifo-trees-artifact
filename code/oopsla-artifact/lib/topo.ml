type t = Star | Node of t list
type decorated_t = Star_dec of int | Node_dec of int * decorated_t list

(* It is sometimes convenient to temporarily index the topology with int indices. *)
type addr_t = int list

let rec height dec_t =
  match dec_t with
  | Star_dec _ -> 1
  | Node_dec (_, trees) -> 1 + List.fold_left max 0 (List.map height trees)

let decorate t =
  (* Adds integer indices to the Nodes and Stars of the tree. *)
  let new_id =
    (* Generates integer indices. *)
    let n = ref 0 in
    fun () ->
      let id = !n in
      incr n;
      id
  in
  let rec helper t =
    match t with
    | Star -> Star_dec (new_id ())
    | Node trees ->
        let trees' = List.map (fun tree -> helper tree) trees in
        Node_dec (new_id (), trees')
  in
  helper t

let undecorate t_dec =
  (* Removes integer indices from the Nodes and Stars of the tree. *)
  let rec helper t_dec =
    match t_dec with
    | Star_dec _ -> Star
    | Node_dec (_, trees) -> Node (List.map (fun tree -> helper tree) trees)
  in
  helper t_dec

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

let _print_decorated_tree dec_t =
  (* Just for fun, to see trees change as they are embedded. *)
  let rec print_tree_helper space dec_t =
    match dec_t with
    | Star_dec i -> Printf.printf "%s *%d\n" space i
    | Node_dec (i, trees) ->
        Printf.printf "%s *%d--------\n" space i;
        ignore (List.map (print_tree_helper (space ^ "\t")) trees)
  in
  print_tree_helper "" dec_t;
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
          let new_tree = Node_dec (8888, [ first; second ]) in
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
    | Star_dec _ -> t
    | Node_dec (index, trees) -> (
        let trees' =
          List.map
            (fun t ->
              let t' = helper t in
              (t', height t'))
            trees
        in
        let pq = Pifo.of_list trees' (fun (_, a) (_, b) -> a - b) in
        match treeify pq with
        | Star_dec _ -> failwith "Impossible."
        | Node_dec (_, trees) -> Node_dec (index, trees))
  in
  helper t

let get_addr_of_index index t_dec : addr_t =
  (* Searches the tree looking for any Node or Star having index `index`.
     Returns the address of that Node or Star, if one exists. *)
  let rec helper t_dec =
    match t_dec with
    | Star_dec id -> if id = index then Some [] else None
    | Node_dec (id, trees) -> (
        if id = index then Some []
        else if trees = [] then None
        else
          let tagged_trees = List.mapi (fun i x -> (i, helper x)) trees in
          match List.filter (fun (_, b) -> Option.is_some b) tagged_trees with
          | [] -> None
          | [ (i, Some ans) ] -> Some (i :: ans)
          | _ -> None)
  in
  Option.get (helper t_dec)

let create_map t1 t2 =
  let rec helper working_tree map =
    (* Creates a mapping from the addresses of the first tree to the
       addresses of the second tree.
       An address is an int list, where each int is the index of a child in the tree.
    *)
    match working_tree with
    | Star_dec i ->
        Hashtbl.add map (get_addr_of_index i t1) (get_addr_of_index i t2)
    | Node_dec (i, trees) ->
        Hashtbl.add map (get_addr_of_index i t1) (get_addr_of_index i t2);
        ignore (List.map (fun tree -> helper tree map) trees)
  in
  let map = Hashtbl.create 100 in
  helper t1 map;
  map

let build_and_embed_binary t =
  let decorated_self = decorate t in
  let decorated_bin = build_binary decorated_self in
  let mapping = create_map decorated_self decorated_bin in
  (mapping, undecorate decorated_bin)

let one_level_ternary = Node [ Star; Star; Star ]
let two_level_binary = Node [ Node [ Star; Star ]; Star ]
let two_level_ternary = Node [ Star; Star; Node [ Star; Star; Star ] ]

let three_level_ternary =
  Node [ Star; Star; Node [ Star; Star; Node [ Star; Star; Star ] ] ]

let irregular = Node [ Star; Star; Star; Node [ Star; Star; Star ] ]

let complex_binary =
  Node
    [ Node [ Node [ Star; Star ]; Star ]; Node [ Node [ Star; Star ]; Star ] ]
