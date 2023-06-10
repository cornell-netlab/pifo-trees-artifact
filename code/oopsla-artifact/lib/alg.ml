open Alg_util

let a2s k v c =
  Model.add_to_state k v c;
  c

let setup baretree schedule weights =
  let open Model in
  List.fold_left
    (fun c (k, v) -> a2s k v c)
    (create baretree)
    (List.mapi
       (fun i weight ->
         ( Printf.sprintf "%s_weight"
             (Util.int_list_to_string (Baretree.path_to_node i baretree)),
           weight ))
       weights)
  |> modify_scheduler schedule

let specify_hitlist baretree l =
  List.map (fun target -> Baretree.path_to_node target baretree) l

(*
module STFQ : Alg_t = struct
  let baretree = Baretree.solo
  let hitlist = [ 0 ]

  let schedule baretree time anchor istransient (meta : Packet.meta) s =
    let hitlist = specify_hitlist baretree hitlist in
    if not (istransient || List.mem anchor hitlist) then
      (* don't opine: defer to init schedule *)
      Model.init_scheduler time anchor istransient meta s
    else
      let time = Time.to_float time in
      let f = find_flow meta in
      let var_lf = Printf.sprintf "%s_last_finish" f in
      let var_wt = Printf.sprintf "%s_weight" f in
      let weight = State.lookup s var_wt in
      let start =
        if State.isdefined s var_lf then max time (State.lookup s var_lf)
        else time
      in
      State.rebind s var_lf (start +. (float_of_int meta.len /. weight));
      (Rank.of_float start, s)

  let setup baretree =
    setup baretree (schedule baretree) [ 1.0; 0.1; 0.2; 0.4; 0.8 ]

  let model = setup baretree

  let simulate baretree t f =
    Model.simulate t (findleaf_solo baretree) 0.001  poprate f
      (setup baretree)
end
*)

module FCFS_Ternary : Alg_t = struct
  let baretree = Baretree.flat_three
  let hitlist = [ 0 ]

  let schedule baretree time anchor istransient (meta : Packet.meta) s =
    let hitlist = specify_hitlist baretree hitlist in
    if not (istransient || List.mem anchor hitlist) then
      (* don't opine: defer to init schedule *)
      Model.init_scheduler time anchor istransient meta s
    else
      let rank = 1.0 in
      (Rank.of_float rank, s)

  let setup baretree = setup baretree (schedule baretree) []
  let model = setup baretree

  let simulate baretree t f =
    Model.simulate t
      (findleaf_flat_three baretree)
      0.001 poprate f (setup baretree)
end

module Strict_Ternary : Alg_t = struct
  let baretree = Baretree.flat_three
  let hitlist = [ 0 ]

  let schedule baretree time anchor istransient (meta : Packet.meta) s =
    (* Printf.printf "From node %s\n" (Util.int_list_to_string anchor); *)
    let hitlist = specify_hitlist baretree hitlist in
    if not (istransient || List.mem anchor hitlist) then
      (* don't opine: defer to init schedule *)
      (* Printf.printf "Off to the init scheduler\n"; *)
      Model.init_scheduler time anchor istransient meta s
    else
      let f = get_pka meta in
      let rank = 10.0 -. float_of_string f in
      (Rank.of_float rank, s)

  let setup baretree = setup baretree (schedule baretree) []
  let model = setup baretree

  let simulate baretree t f =
    Model.simulate t
      (findleaf_flat_three baretree)
      0.001 poprate f (setup baretree)
end

module RRobin_Ternary : Alg_t = struct
  let baretree = Baretree.flat_three
  let hitlist = [ 0 ]

  let schedule baretree time anchor istransient (meta : Packet.meta) s =
    let hitlist = specify_hitlist baretree hitlist in
    if not (istransient || List.mem anchor hitlist) then
      (* don't opine: defer to init schedule *)
      Model.init_scheduler time anchor istransient meta s
    else
      let time = Time.to_float time in
      let f = get_pka meta in
      let var_lf = Printf.sprintf "%s_last_finish" f in
      let weight = 0.33 in
      let start =
        if State.isdefined s var_lf then max time (State.lookup s var_lf)
        else time
      in
      if not istransient then State.rebind s var_lf (start +. (100.0 /. weight));
      (Rank.of_float start, s)

  let setup baretree = setup baretree (schedule baretree) []
  let model = setup baretree

  let simulate baretree t f =
    Model.simulate t
      (findleaf_flat_three baretree)
      0.001 poprate f (setup baretree)
end

module Fair_Ternary : Alg_t = struct
  let baretree = Baretree.flat_three
  let hitlist = [ 0 ]

  let schedule baretree time anchor istransient (meta : Packet.meta) s =
    let hitlist = specify_hitlist baretree hitlist in
    if not (istransient || List.mem anchor hitlist) then
      (* don't opine: defer to init schedule *)
      Model.init_scheduler time anchor istransient meta s
    else
      let time = Time.to_float time in
      let f = get_pka meta in
      let var_lf = Printf.sprintf "%s_last_finish" f in
      let var_wt = Printf.sprintf "%s_weight" f in
      let start =
        if State.isdefined s var_lf then max time (State.lookup s var_lf)
        else time
      in
      (if not istransient then
       let weight = State.lookup s var_wt in
       State.rebind s var_lf (start +. (float_of_int meta.len /. weight)));
      (Rank.of_float start, s)

  let setup baretree = setup baretree (schedule baretree) [ 1.0; 0.1; 0.2; 0.3 ]
  let model = setup baretree

  let simulate baretree t f =
    Model.simulate t
      (findleaf_flat_three baretree)
      0.001 poprate f (setup baretree)
end

module MRG_Ternary : Alg_t = struct
  let baretree = Baretree.flat_three
  let hitlist = [ 0 ]

  let schedule baretree time anchor istransient (meta : Packet.meta) s =
    let hitlist = specify_hitlist baretree hitlist in
    if not (istransient || List.mem anchor hitlist) then
      (* don't opine: defer to init schedule *)
      Model.init_scheduler time anchor istransient meta s
    else
      (* Printf.printf "Running MRG with anchor %s on a %s node\n" *)
      (* (Util.int_list_to_string anchor) *)
      (* (if istransient then "transient" else "anchor"); *)

      (* find out what flow this payload belongs to, and create variables to get/set *)
      let f = get_pka meta in
      let time = Time.to_float time in
      let var_lt = Printf.sprintf "%s_last_time" f in
      let var_tb = Printf.sprintf "%s_tb" f in
      let var_minrate = Printf.sprintf "%s_minrate" f in
      let burst = State.lookup s "burst" in

      (* find, grow, and prune the token bucket *)
      let tb = State.lookup s var_tb in
      let tb =
        tb +. (State.lookup s var_minrate *. (time -. State.lookup s var_lt))
      in
      let tb = if tb > burst then burst else tb in

      (* decide if we are over or under the MRG *)
      let len = Float.of_int meta.len in
      let ans =
        if tb > len then (
          (* Printf.printf "\n%s ↗" f; *)
          if not istransient then State.rebind s var_tb (tb -. len);
          0.0)
        else (* Printf.printf "\n%s ↘" f; *)
          1.0
      in
      if not istransient then State.rebind s var_lt time;
      (* ans, plus log "last_time := now" into state *)
      (* but don't update state if we were dealing with a transient node *)
      (Rank.of_float ans, s)

  (* this satisfies the signature but is not enough *)
  let setup baretree = setup baretree (schedule baretree) [ 1.0 ]
  let model = setup baretree

  let setup_mrg baretree data model =
    List.fold_left
      (fun c (k, v) -> a2s k v c)
      model
      (List.map
         (fun (target, str, v) ->
           ( Printf.sprintf "%s_%s"
               (Util.int_list_to_string (Baretree.path_to_node target baretree))
               str,
             v ))
         data)

  let setup_full baretree last_time =
    let lt = Time.to_float last_time in
    setup baretree
    |> setup_mrg baretree
         [
           (1, "last_time", lt);
           (2, "last_time", lt);
           (3, "last_time", lt);
           (1, "minrate", 220.0);
           (2, "minrate", 180.0);
           (3, "minrate", 112.0);
           (1, "tb", 0.0);
           (2, "tb", 0.0);
           (3, "tb", 0.0);
         ]
    |> a2s "burst" 512.0

  let simulate baretree t f =
    Model.simulate t
      (findleaf_flat_three baretree)
      0.001 poprate f (setup_full baretree t)
end

module Fair2_Two_Tier_Ternary : Alg_t = struct
  let baretree = Baretree.two_tier_ternary
  let hitlist = [ 0; 3 ]

  let schedule baretree time anchor istransient (meta : Packet.meta) s =
    let hitlist = specify_hitlist baretree hitlist in
    if not (istransient || List.mem anchor hitlist) then
      (* don't opine: defer to init schedule *)
      Model.init_scheduler time anchor istransient meta s
    else
      let time = Time.to_float time in
      let f = get_pka meta in
      let var_lf = Printf.sprintf "%s_last_finish" f in
      let var_wt = Printf.sprintf "%s_weight" f in
      let start =
        if State.isdefined s var_lf then max time (State.lookup s var_lf)
        else time
      in
      (if not istransient then
       let weight = State.lookup s var_wt in
       State.rebind s var_lf (start +. (float_of_int meta.len /. weight)));
      (* don't update state if we were dealing with a transient node *)
      (Rank.of_float start, s)

  let setup baretree =
    setup baretree (schedule baretree)
      [ 1.0; 0.33; 0.33; 0.33; 0.33; 0.33; 0.33 ]

  let model = setup baretree

  let simulate baretree t f =
    Model.simulate t
      (findleaf_two_tier_ternary baretree)
      0.001 poprate f (setup baretree)
end

module Fair_Strict_Two_Tier_Ternary : Alg_t = struct
  let baretree = Baretree.two_tier_ternary
  let hitlist = [ 0; 3 ]

  let strict_schedule baretree time anchor istransient (meta : Packet.meta) s =
    (* Printf.printf "From node %s\n" (Util.int_list_to_string anchor); *)
    let hitlist = specify_hitlist baretree hitlist in
    if not (istransient || List.mem anchor hitlist) then
      (* don't opine: defer to init schedule *)
      (* Printf.printf "Off to the init scheduler\n"; *)
      Model.init_scheduler time anchor istransient meta s
    else
      let f = get_pka meta in
      let rank = 10.0 -. float_of_string f in
      (Rank.of_float rank, s)

  let schedule baretree time anchor istransient (meta : Packet.meta) s =
    let hitlist = specify_hitlist baretree hitlist in
    if not (istransient || List.mem anchor hitlist) then (
      Printf.printf "Off to init scheduler\n";
      (* don't opine: defer to init schedule *)
      Model.init_scheduler time anchor istransient meta s)
    else if anchor = Baretree.path_to_node 3 baretree then
      strict_schedule baretree time anchor istransient meta s
    else
      let time = Time.to_float time in
      let f = get_pka meta in
      let var_lf = Printf.sprintf "%s_last_finish" f in
      let var_wt = Printf.sprintf "%s_weight" f in
      let start =
        if State.isdefined s var_lf then max time (State.lookup s var_lf)
        else time
      in
      (if not istransient then
       let weight = State.lookup s var_wt in
       State.rebind s var_lf (start +. (float_of_int meta.len /. weight)));
      (* don't update state if we were dealing with a transient node *)
      (Rank.of_float start, s)

  (* this satisfies the signature but is not enough *)
  let setup baretree =
    setup baretree (schedule baretree) [ 1.0; 0.10; 0.10; 0.80 ]

  let model = setup baretree

  let simulate baretree t f =
    Model.simulate t
      (findleaf_two_tier_ternary baretree)
      0.001 poprate f (setup baretree)
end

module Fair3_Two_Tier_Ternary' : Alg_t = struct
  let baretree = Baretree.two_tier_ternary'
  let hitlist = [ 0; 1; 3 ]

  let schedule baretree time anchor istransient (meta : Packet.meta) s =
    let hitlist = specify_hitlist baretree hitlist in
    if not (istransient || List.mem anchor hitlist) then
      (* don't opine: defer to init schedule *)
      Model.init_scheduler time anchor istransient meta s
    else
      let time = Time.to_float time in
      let f = get_pka meta in
      let var_lf = Printf.sprintf "%s_last_finish" f in
      let var_wt = Printf.sprintf "%s_weight" f in
      let start =
        if State.isdefined s var_lf then max time (State.lookup s var_lf)
        else time
      in
      (if not istransient then
       let weight = State.lookup s var_wt in
       State.rebind s var_lf (start +. (float_of_int meta.len /. weight)));
      (* don't update state if we were dealing with a transient node *)
      (Rank.of_float start, s)

  let setup baretree =
    setup baretree (schedule baretree)
      [ 1.0; 0.33; 0.33; 0.33; 0.33; 0.33; 0.33; 0.33; 0.33; 0.33 ]

  let model = setup baretree

  let simulate baretree t f =
    Model.simulate t
      (findleaf_two_tier_ternary' baretree)
      0.001 poprate f (setup baretree)
end

module Fair3_Three_Tier_Ternary : Alg_t = struct
  let baretree = Baretree.three_tier_ternary
  let hitlist = [ 0; 3; 6 ]

  let schedule baretree time anchor istransient (meta : Packet.meta) s =
    let hitlist = specify_hitlist baretree hitlist in
    if not (istransient || List.mem anchor hitlist) then
      (* don't opine: defer to init schedule *)
      Model.init_scheduler time anchor istransient meta s
    else
      let time = Time.to_float time in
      let f = get_pka meta in
      let var_lf = Printf.sprintf "%s_last_finish" f in
      let var_wt = Printf.sprintf "%s_weight" f in
      let start =
        if State.isdefined s var_lf then max time (State.lookup s var_lf)
        else time
      in
      (if not istransient then
       let weight = State.lookup s var_wt in
       State.rebind s var_lf (start +. (float_of_int meta.len /. weight)));
      (* don't update state if we were dealing with a transient node *)
      (Rank.of_float start, s)

  let setup baretree =
    setup baretree (schedule baretree)
      [ 1.0; 0.40; 0.40; 0.20; 0.33; 0.33; 0.33; 0.10; 0.40; 0.50 ]

  let model = setup baretree

  let simulate baretree t f =
    Model.simulate t
      (findleaf_three_tier_ternary baretree)
      0.001 poprate f (setup baretree)
end

module HPFQ_Binary_3 : Alg_t = struct
  let baretree = Baretree.binary_three_leaves
  let hitlist = [ 0; 1 ]

  let schedule baretree time anchor istransient (meta : Packet.meta) s =
    (* Printf.printf "From node %s\n" (Util.int_list_to_string anchor); *)
    let hitlist = specify_hitlist baretree hitlist in
    if not (istransient || List.mem anchor hitlist) then
      (* don't opine: defer to init schedule *)
      Model.init_scheduler time anchor istransient meta s
    else
      let time = Time.to_float time in
      let f = get_pka meta in
      let var_lf = Printf.sprintf "%s_last_finish" f in
      let var_wt = Printf.sprintf "%s_weight" f in
      let start =
        if State.isdefined s var_lf then max time (State.lookup s var_lf)
        else time
      in
      (if not istransient then
       let weight = State.lookup s var_wt in
       State.rebind s var_lf (start +. (float_of_int meta.len /. weight)));
      (Rank.of_float start, s)

  let setup baretree =
    setup baretree (schedule baretree) [ 1.0; 0.8; 0.2; 0.75; 0.25 ]

  let model = setup baretree

  let simulate baretree t f =
    Model.simulate t
      (findleaf_binary_three baretree)
      sleeptime poprate f (setup baretree)
end

module HPFQ_Binary_4 : Alg_t = struct
  let baretree = Baretree.binary_four_leaves
  let hitlist = [ 0; 1; 2 ]

  let schedule baretree time anchor istransient (meta : Packet.meta) s =
    let hitlist = specify_hitlist baretree hitlist in
    if not (istransient || List.mem anchor hitlist) then
      (* don't opine: defer to init schedule *)
      Model.init_scheduler time anchor istransient meta s
    else
      let time = Time.to_float time in
      let f = get_pka meta in
      let var_lf = Printf.sprintf "%s_last_finish" f in
      let var_wt = Printf.sprintf "%s_weight" f in
      let start =
        if State.isdefined s var_lf then max time (State.lookup s var_lf)
        else time
      in
      (if not istransient then
       let weight = State.lookup s var_wt in
       State.rebind s var_lf (start +. (float_of_int meta.len /. weight)));
      (Rank.of_float start, s)

  let setup baretree =
    setup baretree (schedule baretree) [ 1.0; 0.8; 0.2; 0.8; 0.2; 0.8; 0.2 ]

  let model = setup baretree

  let simulate baretree t f =
    Model.simulate t
      (findleaf_binary_four baretree)
      sleeptime poprate f (setup baretree)
end

(*******************************)
(***        EMBEDDING        ***)
(*******************************)

module T2B (TernaryAlg : Alg_t) : Alg_t = struct
  (* we craft a new tree,
     and then run the original simulate method with the new tree
  *)
  let baretree = Baretree.ternary_to_binary TernaryAlg.baretree
  let model = TernaryAlg.model (* not used...*)

  let simulate baretree =
    (* Baretree.print_tree baretree; *)
    TernaryAlg.simulate baretree
end

module FCFS_Ternary_Bin = T2B (FCFS_Ternary)
module Strict_Ternary_Bin = T2B (Strict_Ternary)
module RRobin_Ternary_Bin = T2B (RRobin_Ternary)
module Fair_Ternary_Bin = T2B (Fair_Ternary)
module MRG_Ternary_Bin = T2B (MRG_Ternary)
module Fair2_Two_Tier_Ternary_Bin = T2B (Fair2_Two_Tier_Ternary)
module Fair3_Two_Tier_Ternary'_Bin = T2B (Fair3_Two_Tier_Ternary')
module Fair3_Three_Tier_Ternary_Bin = T2B (Fair3_Three_Tier_Ternary)
module Fair_Strict_Two_Tier_Ternary_Bin = T2B (Fair_Strict_Two_Tier_Ternary)

(*******************************)
(***     FUNCTORIZED GEN     ***)
(*******************************)

module type Config_t = sig
  val weights : float list
  val leaffinder : Baretree.t -> Packet.t -> int list
end

(* Generates instances of HPFQ running one-tier binary trees.
    The user gives
    - the weights on the leaves
    - a partition to decide which packets go to which leaves
    by setting up a quick Config module (above)
*)
module BinaryHPFQGen (Config : Config_t) : Alg_t = struct
  let baretree = Baretree.flat_two
  let hitlist = [ 0 ]

  let schedule baretree time anchor istransient (meta : Packet.meta) s =
    let hitlist = specify_hitlist baretree hitlist in
    if not (istransient || List.mem anchor hitlist) then
      (* don't opine: defer to init schedule *)
      (* Printf.printf "Passing to init scheduler\n"; *)
      Model.init_scheduler time anchor istransient meta s
    else
      let time = Time.to_float time in
      let f = get_pka meta in
      (* Printf.printf "Weights per node %s\n" f; *)
      let var_lf = Printf.sprintf "%s_last_finish" f in
      let var_wt = Printf.sprintf "%s_weight" f in
      let start =
        if State.isdefined s var_lf then max time (State.lookup s var_lf)
        else time
      in
      let weight = State.lookup s var_wt in
      if not istransient then
        State.rebind s var_lf (start +. (float_of_int meta.len /. weight));
      (Rank.of_float start, s)

  let setup baretree = setup baretree (schedule baretree) Config.weights
  let model = setup baretree

  let simulate baretree t f =
    Model.simulate t
      (Config.leaffinder baretree)
      sleeptime poprate f (setup baretree)
end

(*******************************)
(***       COMPOSITION       ***)
(*******************************)

module HPFQ_two_leaves_root : Alg_t = struct
  module AB = BinaryHPFQGen (struct
    let weights = [ 1.0; 0.3; 0.7 ]
    let leaffinder = findleaf_flat_two_AB
  end)

  module CD = BinaryHPFQGen (struct
    let weights = [ 1.0; 0.4; 0.6 ]
    let leaffinder = findleaf_flat_two_CD
  end)

  module Root = BinaryHPFQGen (struct
    let weights = [ 1.0; 0.8; 0.2 ]
    let leaffinder = findleaf_flat_two_CD
  end)

  let baretree = Baretree.binary_four_leaves

  let schedule baretree time anchor istransient (meta : Packet.meta) s =
    if anchor = Baretree.path_to_node 0 baretree then
      (* Printf.printf "Passing to root scheduler\n"; *)
      (snd Root.model).schedule time anchor istransient meta s
    else if anchor = Baretree.path_to_node 1 baretree then
      (* Printf.printf "Passing to AB scheduler\n"; *)
      (snd AB.model).schedule time [] istransient
        { meta with pka = List.tl meta.pka }
        s
    else if anchor = Baretree.path_to_node 2 baretree then
      (* Printf.printf "Passing to CD scheduler\n"; *)
      (snd CD.model).schedule time [] istransient
        { meta with pka = List.tl meta.pka }
        s
    else
      (* Printf.printf "Passing to init scheduler\n"; *)
      Model.init_scheduler time anchor istransient meta s

  let model =
    let tree, brain = Root.model in
    let tree' =
      match tree with
      | Leaf _ -> failwith "Bad setup"
      | Node n -> Pifotree.Node { n with kids = [ fst AB.model; fst CD.model ] }
    in
    (tree', brain) |> Model.modify_scheduler (schedule baretree)

  let simulate baretree t f =
    Model.simulate t (findleaf_binary_four baretree) sleeptime poprate f model
end
