type sched_t = State.t -> Packet.t -> Path.t * State.t
type t = { s : State.t; q : Pifotree.t; z : sched_t }

val simulate : float -> float -> float -> Packet.t list -> t -> Packet.t list
