type t = Star | Node of t list
type addr_t
type mapping_t = addr_t -> addr_t Option.t

val build_binary : t -> t * mapping_t
val print_tree : t -> unit

(* val print_mapping : mapping_t -> unit *)
val one_level_ternary : t
val two_level_binary : t
val two_level_ternary : t
val three_level_ternary : t
val irregular : t
val complex_binary : t
