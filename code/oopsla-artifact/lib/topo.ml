type t = Star | Node of t list

let rec treeify pq : t =
  match Pifo.length pq with
  | 0 -> failwith "Cannot treeify empty PQ"
  | 1 -> fst (Pifo.top_exn pq)
  | _ -> (
      let (first, ht), pq' = Pifo.pop_exn pq in
      (* Found one tree with this height *)
      match Pifo.pop_if pq' (fun (_, ht') -> ht = ht') with
      | Some ((second, _), pq'') ->
          (* ...and a second tree with the same height. *)
          let new_tree = Node [ first; second ] in
          let pq''' = Pifo.push pq'' (new_tree, ht + 1) in
          treeify pq'''
      | None ->
          (* no more elements of this ht! reinsert the first tree that we
             extracted but with falsely-increased ht. *)
          let pq'' = Pifo.push pq' (first, ht + 1) in
          treeify pq'')

let rec height t =
  match t with
  | Star -> 1
  | Node trees -> 1 + List.fold_left max 0 (List.map height trees)

let to_binary t =
  let rec to_binary_inner t : t =
    match t with
    | Star | Node [ _ ] -> t
    (* We don't do anything to Stars and Nodes with single children. *)
    | Node trees ->
        let compiled_trees =
          List.map
            (fun t ->
              let t' = to_binary_inner t in
              (t', height t'))
            trees
        in
        let pq = Pifo.of_list compiled_trees (fun (_, a) (_, b) -> a - b) in
        (* we can clobber the topmost generated ID with our own
           the same is true of the istransient status *)
        treeify pq
  in
  to_binary_inner t

let one_level_ternary : t = Node [ Star; Star; Star ]
let two_level_binary : t = Node [ Star; Node [ Star; Star ] ]
let _ = assert (to_binary one_level_ternary = two_level_binary)
