type t = Node of int * bool * t list

val path_to_random_node : t -> int list
val path_to_node : int -> t -> int list
val ternary_to_binary : t -> t
val print_tree : t -> unit

(* val get_id : t -> Id.t
   val size : t -> int *)
(* val height : t -> int *)
(* val postorder : t -> Id.t list
   val random_node : t -> Id.t
   val leaves : t -> Id.t list
   val parent_arr : t -> Id.t array *)

val solo : t
val flat_one : t
val flat_two : t
val flat_three : t
val two_tier_ternary : t
val two_tier_ternary' : t
val three_tier_ternary : t
val flat_four : t
val binary_three_leaves : t
val binary_four_leaves : t
