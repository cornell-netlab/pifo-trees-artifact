type t

val create : string -> t
val last_pkt_time : t -> Time.t
val first_pkt_time : t -> Time.t
val packets : t -> Packet.t list
val hd_tl : t -> (Packet.t * t) option
val length : t -> int
val print_from_filename : string -> unit
val print_pkts : Packet.t list -> unit
val update_pkts : t -> Packet.t list -> t
