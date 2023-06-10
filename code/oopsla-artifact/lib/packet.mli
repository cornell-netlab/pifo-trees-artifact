open Pcap

type t

type meta = {
  time : Time.t;
  len : int;
  src : int;
  dst : int;
  pushed : Time.t option;
  popped : Time.t option;
  pka : int list;
}

val to_meta : t -> meta
val create : (module HDR) -> Cstruct.t * Cstruct.t -> t
val sprint : t -> string
val write_to_csv : meta list -> Time.t -> string -> unit
