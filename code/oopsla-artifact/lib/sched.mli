type t = State.t -> Packet.t -> Path.t * State.t

val noop : t
