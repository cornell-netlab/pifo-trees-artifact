let sleeptime = 0.0005
let poprate = 0.25

let find_flow p =
  match Packet.src p with
  | 17661175009296 -> "A" (* 10:10:10:10:10:10 *)
  | 35322350018592 -> "B" (* 20...*)
  | 52983525027888 -> "C" (* 30...*)
  | 70644700037184 -> "D" (* 40...*)
  | 88305875046480 -> "E" (* 50...*)
  | 105967050055776 -> "F" (* 60...*)
  | 123628225065072 -> "G" (* 70...*)
  | _ -> failwith "Unexpected payload"

let findleaf_solo t pkt =
  let target =
    match find_flow pkt with
    | "A" | "B" | "C" | "D" -> 0
    | _ -> failwith "Received packet with unexpected source"
  in
  Baretree.path_to_node target t

let findleaf_flat_one t pkt =
  let target =
    match find_flow pkt with
    | "A" | "B" | "C" | "D" -> 1
    | _ -> failwith "Received packet with unexpected source"
  in
  Baretree.path_to_node target t

let findleaf_flat_two t pkt =
  let target =
    match find_flow pkt with
    | "A" | "B" -> 1
    | "C" | "D" -> 2
    | _ -> failwith "Received packet with unexpected source"
  in
  Baretree.path_to_node target t

let findleaf_flat_two_AB t pkt =
  let target =
    match find_flow pkt with
    | "A" -> 1
    | "B" -> 2
    | _ -> failwith "Received packet with unexpected source"
  in
  Baretree.path_to_node target t

let findleaf_flat_two_CD t pkt =
  let target =
    match find_flow pkt with
    | "C" -> 1
    | "D" -> 2
    | _ -> failwith "Received packet with unexpected source"
  in
  Baretree.path_to_node target t

let findleaf_flat_three t pkt =
  let target =
    match find_flow pkt with
    | "A" -> 1
    | "B" -> 2
    | "C" -> 3
    | _ -> failwith "Received packet with unexpected source"
  in
  Baretree.path_to_node target t

let findleaf_flat_four t pkt =
  let target =
    match find_flow pkt with
    | "A" -> 1
    | "B" -> 2
    | "C" -> 3
    | "D" -> 4
    | _ -> failwith "Received packet with unexpected source"
  in
  Baretree.path_to_node target t

let findleaf_two_tier_ternary t pkt =
  let target =
    match find_flow pkt with
    | "A" -> 1
    | "B" -> 2
    | "C" -> 4
    | "D" -> 5
    | "E" -> 6
    | _ ->
        failwith
          (Printf.sprintf "Received packet with unexpected source: %d" pkt.src)
  in
  Baretree.path_to_node target t

let findleaf_two_tier_ternary' t pkt =
  let target =
    match find_flow pkt with
    | "A" -> 4
    | "B" -> 5
    | "C" -> 6
    | "D" -> 2
    | "E" -> 7
    | "F" -> 8
    | "G" -> 9
    | _ ->
        failwith
          (Printf.sprintf "Received packet with unexpected source: %d" pkt.src)
  in
  Baretree.path_to_node target t

let findleaf_three_tier_ternary t pkt =
  let target =
    match find_flow pkt with
    | "A" -> 1
    | "B" -> 2
    | "C" -> 4
    | "D" -> 5
    | "E" -> 7
    | "F" -> 8
    | "G" -> 9
    | _ ->
        failwith
          (Printf.sprintf "Received packet with unexpected source: %d" pkt.src)
  in
  Baretree.path_to_node target t

let findleaf_binary_three t pkt =
  let target =
    match find_flow pkt with
    | "A" -> 3
    | "B" -> 4
    | "C" -> 2
    | _ ->
        failwith
          (Printf.sprintf "Received packet with unexpected source: %d" pkt.src)
  in
  Baretree.path_to_node target t

let findleaf_binary_four t pkt =
  let target =
    match find_flow pkt with
    | "A" -> 3
    | "B" -> 4
    | "C" -> 5
    | "D" -> 6
    | _ ->
        failwith
          (Printf.sprintf "Received packet with unexpected source: %d"
             (Packet.src pkt))
  in
  Baretree.path_to_node target t
