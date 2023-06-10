type t =
  | Leaf of (Packet.t * Rank.t) Pifo.t
  | Internal of (t list * (int * Rank.t) Pifo.t)

val pop : t -> (Packet.t * t) option
val push : t -> Packet.t -> Path.t -> t
val size : t -> int
val well_formed : t -> bool
val snapshot : t -> Packet.t list list
val flush : t -> Packet.t list
