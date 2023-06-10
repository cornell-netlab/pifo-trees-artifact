type 'a t

val create : ('a -> 'a -> int) -> 'a t
val push : 'a t -> 'a -> 'a t
val peek : 'a t -> 'a option
val pop : 'a t -> ('a * 'a t) option
val pop_exn : 'a t -> 'a * 'a t
val is_empty : 'a t -> bool
val length : 'a t -> int
val count : ('a -> bool) -> 'a t -> int
val flush : 'a t -> 'a list
