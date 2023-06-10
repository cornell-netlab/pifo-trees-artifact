type 'a t = 'a Fheap.t

let create cmp = Fheap.create ~compare:cmp
let push = Fheap.add
let peek = Fheap.top
let pop = Fheap.pop
let pop_exn = Fheap.pop_exn
let is_empty = Fheap.is_empty
let length = Fheap.length

let count f t =
  (* Count how many elements in the PIFO satisfy `f`. *)
  List.fold_left (fun acc x -> if f x then acc + 1 else acc) 0 (Fheap.to_list t)

let flush t =
  (* Pop the PIFO repeatedly until it is empty.
     Return a list of its elements, in the order they were popped.
  *)
  let rec helper acc =
    match peek t with
    | None -> acc
    | Some x ->
        ignore (pop_exn t);
        helper (x :: acc)
  in
  helper []
