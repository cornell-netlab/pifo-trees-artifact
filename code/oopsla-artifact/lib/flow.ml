open Pcap

type pcap_header_t = {
  endian : endian;
  magic : int32;
  ver_maj : int;
  ver_min : int;
  thiszone : int32;
  sigfigs : int32;
  snaplen : int32;
  network : int32;
}

type t = { header : pcap_header_t; packets : Packet.t list }

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

let create_packets h body : Packet.t list =
  List.rev
    (Cstruct.fold (fun l p -> Packet.create h p :: l) (packets h body) [])

(* Note: this will leak fds and memory *)
let open_file filename =
  let fd = Unix.(openfile filename [ O_RDONLY ] 0) in
  let ba =
    Bigarray.(
      array1_of_genarray
        (Mmap.V1.map_file fd Bigarray.char c_layout false [| -1 |]))
  in
  Cstruct.of_bigarray ba

let read_header filename =
  let buf = open_file filename in
  match Pcap.detect buf with
  | Some h -> (h, buf)
  | None -> failwith (Printf.sprintf "can't parse pcap header from %s" filename)

let create filename =
  let h, buf = read_header filename in
  let _, body = Cstruct.split buf sizeof_pcap_header in
  (* print_string "opened file\n";  *)
  { header = create_pcap_header h buf; packets = create_packets h body }

let last_pkt_time flow = (List.hd (List.rev flow.packets)).time
let first_pkt_time flow = (List.hd flow.packets).time
let packets flow = flow.packets

let hd_tl flow =
  let packets = flow.packets in
  match packets with [] -> None | h :: t -> Some (h, { flow with packets = t })

let length flow = List.length (packets flow)

let print_pkts pkts =
  print_string
    (String.concat "\n=-=-=-=-=-=-=-=-=-=-=\n" (List.map Packet.sprint pkts))

let print_from_filename filename = print_pkts (create filename).packets
let update_pkts f pkts = { f with packets = pkts }
