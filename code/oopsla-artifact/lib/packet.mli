type t

val pkts_from_file : string -> t list
val punch_in : t -> Time.t -> t
val punch_out : t -> Time.t -> t
val time : t -> Time.t
val src : t -> int
val len : t -> float
val write_to_csv : t list -> Time.t -> string -> unit
