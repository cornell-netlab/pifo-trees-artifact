open Pifotrees_lib
open Alg
open Run

let extension_run () = run Extension_Flat.simulate four_flows "extension"

let _ = extension_run ()
