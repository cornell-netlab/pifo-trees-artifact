type t = Leaf of Packet.meta Pifo.t | Internal of (t list * int Pifo.t)
