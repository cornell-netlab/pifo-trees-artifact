open Pcap
open Ethernet

type packet_header_t = { time : Time.t; size_incl : int32; size_actu : int32 }
type ethernet_t = { dst : int; src : int }
type complete = { header : packet_header_t; payload : ethernet_t }

type t = {
  (* We will mostly pass around the lighter-weight metadata of packets,
     not the whole thing.
  *)
  time : Time.t;
  len : int;
  src : int;
  dst : int;
  pushed : Time.t option;
  popped : Time.t option;
  pka : int list;
}

let complete_to_meta p =
  {
    time = p.header.time;
    len = Int32.to_int p.header.size_incl;
    src = p.payload.src;
    dst = p.payload.dst;
    pushed = None;
    popped = None;
    pka = [];
  }

let create h (ph, pb) =
  (* packet header, packet body *)
  let module H = (val h : HDR) in
  let hex_to_int = function `Hex s -> int_of_string ("0x" ^ s) in
  let header =
    {
      time =
        Time.of_floats
          (H.get_pcap_packet_ts_sec ph)
          (H.get_pcap_packet_ts_usec ph);
      size_incl = H.get_pcap_packet_incl_len ph;
      size_actu = H.get_pcap_packet_orig_len ph;
    }
  in
  let payload =
    {
      src = hex_to_int (Hex.of_string (copy_ethernet_src pb));
      dst = hex_to_int (Hex.of_string (copy_ethernet_dst pb));
    }
  in
  complete_to_meta { header; payload }

let sprint t =
  Printf.sprintf "src  : %d\ndst  : %d\nlen  : %d\ntime : %f" t.src t.dst t.len
    (Time.to_float t.time)

let punch_in t time = { t with pushed = Some time }
let punch_out t time = { t with popped = Some time }

let write_to_csv ts overdue filename =
  let format_to_csv metas overdue =
    let headers =
      "\"src\", \"dst\", \"arrived\", \"length\", \"pushed\", \"popped\""
    in
    let format_one_to_csv meta =
      let pushed, popped =
        match (meta.pushed, meta.popped) with
        | Some pushed', Some popped' ->
            (Time.to_float pushed', Time.to_float popped')
        | Some pushed', None -> (Time.to_float pushed', Time.to_float overdue)
        | _, _ -> (0.0, 0.0)
      in
      Printf.sprintf "\"%d\",\"%d\",\"%f\",\"%d\",\"%f\",\"%f\"" meta.src
        meta.dst (Time.to_float meta.time) meta.len pushed popped
    in
    Printf.sprintf "%s\n%s" headers
      (String.concat "\n" (List.map format_one_to_csv metas))
  in
  let payload = format_to_csv ts overdue in
  let ecsv = Csv.input_all (Csv.of_string payload) in
  Csv.save filename ecsv
