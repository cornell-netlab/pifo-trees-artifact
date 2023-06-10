type t

val create : int -> t
val lookup : t -> string -> float
val rebind : t -> string -> float -> unit
val isdefined : t -> string -> bool
