open Pcap
open Ethernet

type packet_header_t = { time : Time.t; size_incl : int32; size_actu : int32 }
type ethernet_t = { dst : int; src : int }

type packet_complete = {
  (* This is the type for all the information we get'll get
     about an individual packet from the PCAP. *)
  header : packet_header_t;
  payload : ethernet_t;
}

type t = {
  (* We will mostly pass around this lighter-weight metadata. *)
  time : Time.t;
  len : int;
  src : int;
  dst : int;
  pushed : Time.t option;
  popped : Time.t option;
}

type pcap_header_t = {
  (* This is the type for all the information we'll get from a PCAP's header. *)
  endian : endian;
  magic : int32;
  ver_maj : int;
  ver_min : int;
  thiszone : int32;
  sigfigs : int32;
  snaplen : int32;
  network : int32;
}

type pcap = {
  (* A PCAP will then consist of a header and a list of packet-metadata.
     This is what we'll parse from a file.pcap. *)
  header : pcap_header_t;
  packets : t list;
}

let complete_to_meta (p : packet_complete) =
  (* We can discard some information and keep just the metadata in this way. *)
  {
    time = p.header.time;
    len = Int32.to_int p.header.size_incl;
    src = p.payload.src;
    dst = p.payload.dst;
    pushed = None;
    popped = None;
  }

(* It is occasionally useful to read/write fields in the metadata. *)
let time t = t.time
let src t = t.src

let len t =
  (* The only user of this immediately converts
     it into a float, so we just do it here. *)
  float_of_int t.len

let punch_in t time = { t with pushed = Some time }
let punch_out t time = { t with popped = Some time }

let create_pcap_header h buf =
  let module H = (val h : HDR) in
  {
    endian = H.endian;
    magic = H.get_pcap_header_magic_number buf;
    ver_maj = H.get_pcap_header_version_major buf;
    ver_min = H.get_pcap_header_version_minor buf;
    thiszone = H.get_pcap_header_thiszone buf;
    sigfigs = H.get_pcap_header_sigfigs buf;
    snaplen = H.get_pcap_header_snaplen buf;
    network = H.get_pcap_header_network buf;
  }

let create_pkt h (ph, pb) =
  (* `ph` is the packet header; `pb` is the packet body. *)
  let module H = (val h : HDR) in
  let hex_to_int = function `Hex s -> int_of_string ("0x" ^ s) in
  let header =
    {
      time =
        Time.of_ints
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
  (* For debugging etc, it is useful to compute the "complete" version and
     then discard some information to get the metadata we are interested in.
  *)
  complete_to_meta { header; payload }

let create_pcap_packets h body : t list =
  List.rev (Cstruct.fold (fun l p -> create_pkt h p :: l) (packets h body) [])

let pkts_from_file filename =
  let open_file filename =
    (* Note: this will leak fds and memory *)
    let fd = Unix.(openfile filename [ O_RDONLY ] 0) in
    let ba =
      Bigarray.(
        array1_of_genarray
          (Mmap.V1.map_file fd Bigarray.char c_layout false [| -1 |]))
    in
    Cstruct.of_bigarray ba
  in
  let read_header filename =
    let buf = open_file filename in
    match Pcap.detect buf with
    | Some h -> (h, buf)
    | None ->
        failwith (Printf.sprintf "can't parse pcap header from %s" filename)
  in
  let h, buf = read_header filename in
  let _, body = Cstruct.split buf sizeof_pcap_header in
  let pcap =
    { header = create_pcap_header h buf; packets = create_pcap_packets h body }
  in
  pcap.packets

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
