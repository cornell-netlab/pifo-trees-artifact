type t = Node of int * bool * t list

let size tree =
  let rec helper ans (Node (_, _, trees)) =
    List.fold_left helper (ans + 1) trees
  in
  helper 0 tree

let rec height (Node (_, _, trees)) =
  1 + List.fold_left max 0 (List.map height trees)

(* let rec postorder (Node (i, trees)) = List.concat_map postorder trees @ [ i ] *)

let path_to_node target t =
  let rec helper (Node (id, _, kids)) =
    if id = target then Some []
    else if kids = [] then None
    else
      let tagged_kids = List.mapi (fun i x -> (i, helper x)) kids in
      match List.filter (fun (_, b) -> Option.is_some b) tagged_kids with
      | [] -> None
      | [ (i, Some ans) ] -> Some (i :: ans)
      | _ -> None
  in
  Option.get (helper t)

let path_to_random_node t =
  let target = Random.int (size t) in
  let ans = path_to_node target t in
  ans

let print_tree tree =
  let rec print_tree_helper space (Node (id, istransient, trees)) : unit =
    Printf.printf "%s %d %s" space id
      (if istransient then "trans" else "anchor");
    print_newline ();
    ignore (List.map (print_tree_helper (space ^ "\t")) trees)
  in
  print_tree_helper "" tree;
  print_newline ()

let n = ref 0

let new_id () =
  let id = !n in
  incr n;
  id

let rec treeify pq : t =
  match Fheap.length pq with
  | 0 -> failwith "Cannot treeify empty PQ"
  | 1 -> fst (Fheap.top_exn pq)
  | _ -> (
      let (first, ht), pq' = Fheap.pop_exn pq in
      (* found one tree with this height *)
      match Fheap.pop_if pq' (fun (_, ht') -> ht = ht') with
      | Some ((second, _), pq'') ->
          (* ...and a second element with the same height *)
          (* this new tree is assumed to be transient node,
             unless we later tag it as an anchor *)
          let new_tree = Node (new_id (), true, [ first; second ]) in
          let pq''' = Fheap.add pq'' (new_tree, ht + 1) in
          treeify pq'''
      | None ->
          (* no more elements of this ht! reinsert it with increased ht *)
          let pq'' = Fheap.add pq' (first, ht + 1) in
          treeify pq'')

let ternary_to_binary tree =
  let rec ternary_to_binary_inner tree : t =
    match tree with
    | Node (_, _, []) -> tree
    | Node (_, _, [ _ ]) -> tree
    | Node (id, istransient, trees) ->
        let compiled_trees =
          List.map
            (fun t ->
              let t' = ternary_to_binary_inner t in
              (t', height t'))
            trees
        in
        let pq =
          Fheap.of_list compiled_trees ~compare:(fun (_, a) (_, b) -> a - b)
        in
        (* we can clobber the topmost generated ID with our own
           the same is true of the istransient status *)
        let (Node (_, _, trees)) = treeify pq in
        (* we decrement the counter to keep ID numbers contiguous *)
        decr n;
        Node (id, istransient, trees)
  in
  n := size tree;
  ternary_to_binary_inner tree

let solo = Node (0, false, [])
let flat_one = Node (0, false, [ Node (1, false, []) ])
let flat_two = Node (0, false, [ Node (1, false, []); Node (2, false, []) ])

let flat_three =
  Node
    (0, false, [ Node (1, false, []); Node (2, false, []); Node (3, false, []) ])

let two_tier_ternary =
  Node
    ( 0,
      false,
      [
        Node (1, false, []);
        Node (2, false, []);
        Node
          ( 3,
            false,
            [ Node (4, false, []); Node (5, false, []); Node (6, false, []) ] );
      ] )

let two_tier_ternary' =
  Node
    ( 0,
      false,
      [
        Node
          ( 1,
            false,
            [ Node (4, false, []); Node (5, false, []); Node (6, false, []) ] );
        Node (2, false, []);
        Node
          ( 3,
            false,
            [ Node (7, false, []); Node (8, false, []); Node (9, false, []) ] );
      ] )

let three_tier_ternary =
  Node
    ( 0,
      false,
      [
        Node (1, false, []);
        Node (2, false, []);
        Node
          ( 3,
            false,
            [
              Node (4, false, []);
              Node (5, false, []);
              Node
                ( 6,
                  false,
                  [
                    Node (7, false, []); Node (8, false, []); Node (9, false, []);
                  ] );
            ] );
      ] )

let flat_four =
  Node
    ( 0,
      false,
      [
        Node (1, false, []);
        Node (2, false, []);
        Node (3, false, []);
        Node (4, false, []);
      ] )

let binary_three_leaves =
  Node
    ( 0,
      false,
      [
        Node (1, false, [ Node (3, false, []); Node (4, false, []) ]);
        Node (2, false, []);
      ] )

let binary_four_leaves =
  Node
    ( 0,
      false,
      [
        Node (1, false, [ Node (3, false, []); Node (4, false, []) ]);
        Node (2, false, [ Node (5, false, []); Node (6, false, []) ]);
      ] )
