open Pifotrees_lib
open Alg
open Run

let extension_embed_run () =
  run ThreePol_Irregular_Tern.simulate seven_flows "extension_ternary"

let _ = extension_embed_run ()
