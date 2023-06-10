type schedule =
  Time.t -> int list -> bool -> Packet.meta -> State.t -> Rank.t * State.t

type control = { s : State.t; schedule : schedule }
type t = Pifotree.t * control

val init_scheduler : schedule
val create : Baretree.t -> t

val simulate :
  Time.t ->
  (Packet.t -> int list) ->
  float ->
  float ->
  Flow.t ->
  t ->
  Packet.meta list

(* val simulate_three :
   Time.t -> float -> float -> float -> Flow.t -> t -> t -> t -> Packet.meta list *)

val add_to_state : string -> float -> t -> unit
val modify_scheduler : schedule -> t -> t
