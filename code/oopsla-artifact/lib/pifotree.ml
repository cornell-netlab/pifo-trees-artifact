open Util

type t =
  | Leaf of (Packet.t * Rank.t) Pifo.t
  | Internal of (t list * (int * Rank.t) Pifo.t)

let rec pop (t : t) : (Packet.t * t) option =
  match t with
  | Leaf p ->
      let* (pkt, _), p' = Pifo.pop p in
      Some (pkt, Leaf p')
  | Internal (qs, p) ->
      let* (i, _), p' = Pifo.pop p in
      let* pkt, q' = pop (List.nth qs i) in
      Some (pkt, Internal (replace_nth qs i q', p'))

let rec push (t : t) (pkt : Packet.t) (path : Path.t) : t =
  match (t, path) with
  | Leaf p, [ (_, r) ] -> Leaf (Pifo.push p (pkt, r))
  | Internal (qs, p), (i, r) :: pt ->
      let p' = Pifo.push p (i, r) in
      let q' = push (List.nth qs i) pkt pt in
      Internal (replace_nth qs i q', p')
  | _ -> failwith "Push: invalid path"

let rec size (t : t) : int =
  (* The size of a PIFO tree is the number of packets in its leaves. *)
  match t with
  | Leaf p -> Pifo.length p
  | Internal (qs, _p) -> List.fold_left (fun acc q -> acc + size q) 0 qs

let rec well_formed (t : t) : bool =
  let pifo_count_occ p ele = Pifo.count (fun (v, _) -> v = ele) p in
  match t with
  | Leaf _ -> true
  | Internal (qs, p) ->
      for i = 0 to List.length qs - 1 do
        assert (
          well_formed (List.nth qs i)
          && pifo_count_occ p i = size (List.nth qs i))
      done;
      true

let rec snapshot (t : t) : Packet.t list list =
  match t with
  | Leaf p -> [ List.map fst (Pifo.flush p) ]
  | Internal (qs, _p) -> List.fold_left (fun acc q -> acc @ snapshot q) [] qs

let rec flush (t : t) : Packet.t list =
  match size t with
  | 0 -> []
  | _ -> (
      match pop t with
      | None -> failwith "Flush: malformed tree."
      | Some (pkt, q') -> flush q' @ [ pkt ])
