type t =
  | Leaf of (Packet.t * Rank.t) Pifo.t
  | Internal of (t list * (int * Rank.t) Pifo.t)

val pop : t -> (Packet.meta * t) option
val push : t -> Packet.meta -> Path.t -> t
val size : t -> int
