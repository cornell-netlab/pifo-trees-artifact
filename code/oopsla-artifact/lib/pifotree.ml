open Util

type t =
  | Leaf of (Packet.t * Rank.t) Pifo.t
  | Internal of (t list * (int * Rank.t) Pifo.t)

let rec pop t =
  match t with
  | Leaf p ->
      let* (pkt, _), p' = Pifo.pop p in
      Some (pkt, Leaf p')
  | Internal (qs, p) ->
      let* (i, _), p' = Pifo.pop p in
      let* pkt, q' = pop (List.nth qs i) in
      Some (pkt, Internal (replace_nth qs i q', p'))

let rec push t pkt path =
  match (t, path) with
  | Leaf p, [ (_, r) ] -> Leaf (Pifo.push p (pkt, r))
  | Internal (qs, p), (i, r) :: pt ->
      let p' = Pifo.push p (i, r) in
      let q' = push (List.nth qs i) pkt pt in
      Internal (replace_nth qs i q', p')
  | _ -> failwith "Push: invalid path"

let rec size t =
  (* The size of a PIFO tree is the number of packets in its leaves. *)
  match t with
  | Leaf p -> Pifo.length p
  | Internal (qs, _p) -> List.fold_left (fun acc q -> acc + size q) 0 qs

let rec well_formed t =
  (* A leaf is well-formed.
     An internal node is well-formed if:
      - each of its child trees is well-formed
      - the number of packets in each child-tree is equal to the number of
        times the present node refers to that child in _its own_ PIFO.
  *)
  let pifo_count_occ p ele = Pifo.count (fun (v, _) -> v = ele) p in
  (* Counts how many times `ele` occurs as a value in PIFO `p`. *)
  match t with
  | Leaf _ -> true
  | Internal (qs, p) ->
      for i = 0 to List.length qs - 1 do
        assert (
          well_formed (List.nth qs i)
          && pifo_count_occ p i = size (List.nth qs i))
      done;
      true

let rec snapshot t =
  match t with
  | Leaf p -> [ List.map fst (Pifo.flush p) ]
  | Internal (qs, _p) -> List.fold_left (fun acc q -> acc @ snapshot q) [] qs

let rec flush t =
  match size t with
  | 0 -> []
  | _ -> (
      match pop t with
      | None -> failwith "Flush: malformed tree."
      | Some (pkt, q') -> flush q' @ [ pkt ])
