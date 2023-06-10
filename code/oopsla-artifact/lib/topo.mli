type t = Star | Node of t list

val to_binary : t -> t
