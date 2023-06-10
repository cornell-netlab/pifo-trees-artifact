type t = float

let cmp t1 t2 =
  let diff = t1 -. t2 in
  if diff < 0.0 then -1 else if diff = 0.0 then 0 else 1

let to_float t = t
let of_float t = t
