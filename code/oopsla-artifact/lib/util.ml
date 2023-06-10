let ( let* ) = Option.bind
let replace_nth l n nth' = List.mapi (fun i x -> if i = n then nth' else x) l

let rec find_nth l n =
  match l with
  | [] -> raise Not_found
  | h :: t -> if n = 0 then h else find_nth t (n - 1)

let int_list_to_string l =
  if l = [] then "root"
  else List.fold_left ( ^ ) "" (List.map (Printf.sprintf "%d") l)

let list_hd_body l = List.rev (List.tl (List.rev l))
