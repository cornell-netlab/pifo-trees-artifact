type 'a t = 'a Fheap.t

let create cmp = Fheap.create ~compare:cmp
let push = Fheap.add
let peek = Fheap.top
let top_exn = Fheap.top_exn
let pop = Fheap.pop
let pop_if = Fheap.pop_if
let pop_exn = Fheap.pop_exn
let is_empty = Fheap.is_empty
let length = Fheap.length
let of_list l cmp = Fheap.of_list l ~compare:cmp

let count f t =
  (* Count how many elements in the PIFO satisfy f. *)
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
