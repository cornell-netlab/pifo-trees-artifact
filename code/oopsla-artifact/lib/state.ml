open Hashtbl

type t = (string, float) Hashtbl.t

let create size = create size

let lookup v t =
  try Hashtbl.find t v
  with Not_found -> failwith (Printf.sprintf "Uninitialized variable: %s" v)

(* we do a more aggressive rebind because
    "Hashtbl.add tbl key data adds a binding of key to data in table tbl.
     Previous bindings for key are not removed, but simply hidden.
     _That is, after performing Hashtbl.remove tbl key,
     the previous binding for key, if any, is restored._"
*)
let rebind k v t =
  Hashtbl.remove t k;
  Hashtbl.add t k v;
  t

let isdefined mem t = Hashtbl.mem t mem
