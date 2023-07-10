open Pifotrees_lib
open Alg
open Run

let extension_embed_run () =
  run Extension_Ternary.simulate four_flows "extension_ternary"

let _ = extension_embed_run ()
