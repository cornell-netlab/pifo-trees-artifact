open Pcap

type t = {
  time : Time.t;
  len : int;
  src : int;
  dst : int;
  pushed : Time.t option;
  popped : Time.t option;
  pka : int list;
}

val create : (module HDR) -> Cstruct.t * Cstruct.t -> t
val sprint : t -> string
val write_to_csv : t list -> Time.t -> string -> unit
val punch_in : t -> Time.t -> t
val punch_out : t -> Time.t -> t
