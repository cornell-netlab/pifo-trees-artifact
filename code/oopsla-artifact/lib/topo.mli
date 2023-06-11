type t = Star | Node of t list

val to_binary : t -> t
val print_tree : t -> unit
val one_level_ternary : t
val two_level_binary : t
val two_level_ternary : t
val three_level_ternary : t
val irregular : t
val irregular_binary : t
