type t = { s : State.t; q : Pifotree.t; z : Sched.t }

val create : Topo.t -> t
val add_to_state : t -> string -> float -> unit
val mod_sched : t -> Sched.t -> t
val simulate : Time.t -> float -> float -> Packet.t list -> t -> Packet.t list
