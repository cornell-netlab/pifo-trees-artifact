open Pifotrees_lib
open Alg
open Run

let extension_run () = run WFQ_Flat_Four.simulate four_flows "extension"

let _ = extension_run ()
