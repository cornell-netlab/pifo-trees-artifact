type t = Leaf of Packet.meta Pifo.t | Internal of (t list * int Pifo.t)

val pop : t -> (Packet.meta * t) option
val push : t -> Packet.meta -> Path.t -> t
