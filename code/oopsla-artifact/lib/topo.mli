type t = Star | Node of t list
type addr_t = int list
type map_t = addr_t -> addr_t Option.t

val build_binary : t -> t * map_t
val print_tree : t -> unit
val print_map : map_t -> addr_t list -> unit
val lift_tilde : map_t -> t -> Path.t -> Path.t

(* A few topologies to play with. *)
val one_level_ternary : t
val one_level_binary : t
val two_level_binary : t
val two_level_ternary : t
val three_level_ternary : t
val irregular : t
val four_wide : t
