type t = Star | Node of t list
type addr_t

val build_and_embed_binary : t -> (addr_t, addr_t) Hashtbl.t * t
val print_tree : t -> unit
val sprint_addr : addr_t -> string
val one_level_ternary : t
val two_level_binary : t
val two_level_ternary : t
val three_level_ternary : t
val irregular : t
val complex_binary : t
