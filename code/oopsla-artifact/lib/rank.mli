type t

val cmp : t -> t -> int
val create : float -> Time.t -> t
val time : t -> Time.t
