type t = Star | Node of t list

val to_binary : t -> t
val one_level_ternary : t
val binary_three_leaves : t
val two_level_ternary : t
val three_level_ternary : t
