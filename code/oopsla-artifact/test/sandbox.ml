open Lazysiv_lib
open Baretree

let _ =
  (* print_tree three_tier_ternary; *)
  (* print_string *)
  (* (Util.int_list_to_string *)
  (* (Pifotree.anchor_of [ 2; 2 ] (Pifotree.create three_tier_ternary))) *)
  print_tree flat_three;
  print_tree (ternary_to_binary flat_three)
