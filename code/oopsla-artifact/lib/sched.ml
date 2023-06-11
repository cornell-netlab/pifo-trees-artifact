type t = State.t -> Packet.t -> Path.t * State.t

let noop s (p : Packet.t) =
  ([ (0, Rank.of_float (Time.to_float (Packet.to_meta p).time)) ], s)
