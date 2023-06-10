type t =
  | Leaf of { q : (Packet.meta * Time.t) Pifo.t (* time = pushtime *) }
  | Node of {
      q : ((int * Packet.meta) * (Rank.t * Time.t)) Pifo.t;
      (* int = which of my children to index to. time = pushtime *)
      kids : t list;
      istransient : bool;
    }

val create : Baretree.t -> t
val random_target : t -> int list
val istransient : t -> bool
val anchor_of : int list -> t -> int list
