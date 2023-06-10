open Util

type t = Leaf of Packet.t Pifo.t | Internal of (t list * int Pifo.t)

let rec pop (t : t) : (Packet.t * t) option =
  match t with
  | Leaf p ->
      let* pkt, p' = Pifo.pop p in
      Some (pkt, Leaf p')
  | Internal (qs, p) ->
      let* i, p' = Pifo.pop p in
      let* pkt, q' = pop (List.nth qs i) in
      Some (pkt, Internal (replace_nth qs i q', p'))

let rec push (t : t) (pkt : Packet.t) (path : Path.t) : t =
  match (t, path) with
  | Leaf p, [ (_, r) ] -> Leaf (Pifo.push p pkt r)
  | Internal (qs, p), (i, r) :: pt ->
      let p' = Pifo.push p i r in
      let q' = push (List.nth qs i) pkt pt in
      Internal (replace_nth qs i q', p')
  | _ -> failwith "Push: invalid path"
