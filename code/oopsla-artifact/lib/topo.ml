type t = Star | Node of t list

let rec treeify pq : t =
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

let rec height t =
  match t with
  | Star -> 1
  | Node trees -> 1 + List.fold_left max 0 (List.map height trees)

let to_binary t =
  let rec helper t : t =
    match t with
    | Star -> t (* We don't do anything to Stars. *)
    | Node trees ->
        let trees' =
          List.map
            (fun t ->
              let t' = helper t in
              (t', height t'))
            trees
        in
        let pq = Pifo.of_list trees' (fun (_, a) (_, b) -> a - b) in
        treeify pq
  in
  helper t

let one_level_ternary : t = Node [ Star; Star; Star ]
let binary_three_leaves : t = Node [ Node [ Star; Star ]; Star ]
let two_level_ternary : t = Node [ Star; Star; Node [ Star; Star; Star ] ]

let three_level_ternary : t =
  Node [ Star; Star; Node [ Star; Star; Node [ Star; Star; Star ] ] ]
