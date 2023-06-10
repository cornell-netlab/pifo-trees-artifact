open Util

type t = Leaf of Packet.meta Pifo.t | Internal of (t list * int Pifo.t)

let rec pop (t : t) : (Packet.meta * t) option =
  match t with
  | Leaf p ->
      let* pkt, p' = Pifo.pop p in
      Some (pkt, Leaf p')
  | Internal (qs, p) ->
      let* i, p' = Pifo.pop p in
      let* pkt, q' = pop (List.nth qs i) in
      Some (pkt, Internal (replace_nth qs i q', p'))
