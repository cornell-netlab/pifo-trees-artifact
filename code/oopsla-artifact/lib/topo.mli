type t = Star | Node of t list
type addr_t = int list (* AM: remove *)
type map_t = addr_t -> addr_t Option.t

val build_binary : t -> t * map_t
val print_tree : t -> unit
val print_map : map_t -> addr_t list -> unit
val one_level_ternary : t
val one_level_binary : t
val two_level_binary : t
val two_level_ternary : t
val three_level_ternary : t
val irregular : t
val complex_binary : t
val eight_wide : t
