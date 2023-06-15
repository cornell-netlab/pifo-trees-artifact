type t = (int * Rank.t) list
(* The _foot_ of this list has a bogus value in the `int` slot.
   We only care about the `rank` of the foot.

   Another way of writing this type is:
    type t = (int * Rank.t) list * Rank.t
   where the final `rank` is the singeton foot of the list.
   However, the existing version is a little easier to work with.
*)

let to_string (l : t) : string =
  let rec loop (l : t) : string =
    match l with
    | [] -> "\n"
    | (i, r) :: t -> Printf.sprintf "%d @ %s\t %s" i (Rank.to_string r) (loop t)
  in
  loop l
