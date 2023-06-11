type t = Star | Node of t list

val to_binary : t -> t
val one_level_ternary : t
