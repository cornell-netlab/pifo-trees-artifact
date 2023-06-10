open Hashtbl

type t = (string, float) Hashtbl.t

let create size = create size

let lookup h v =
  try Hashtbl.find h v
  with Not_found -> failwith (Printf.sprintf "Uninitialized variable: %s" v)

(* we do a more aggressive rebind because
    "Hashtbl.add tbl key data adds a binding of key to data in table tbl.
     Previous bindings for key are not removed, but simply hidden.
     _That is, after performing Hashtbl.remove tbl key,
     the previous binding for key, if any, is restored._"
*)
let rebind h k v =
  Hashtbl.remove h k;
  Hashtbl.add h k v

let isdefined = Hashtbl.mem
