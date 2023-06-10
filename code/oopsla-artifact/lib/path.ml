type t = (int * Rank.t) list
(* The foot of this list has a bogus value in the `int` slot.
   We only care about the `rank` of the foot.

   Another way of writing this type is:
    type t = (int * Rank.t) list * Rank.t
   where the final `Rank.t` is the singeton foot of the list.
   However, the existing version is a little easier to work with.
*)
