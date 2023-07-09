(lang dune 2.9)

(name pifotrees)

(generate_opam_files true)

(package
 (name pifotrees)
 (synopsis "Programmable packet scheduling at line rate.")
 (description
  "A formalism and implementation of PIFO trees, a recently proposed primitive for packet scheduling. Accompanied by an algorithm to compile a scheduler written to run atop of a PIFO tree of some heterogeous shape into a scheduler that runs on a PIFO tree of some other, regular-branching, shape.")
 (authors
  "Anshuman Mohan"
  "Yunhe Liu"
  "Tobias Kapp\195\169"
  "Dexter Kozen"
  "Nate Foster")
 (maintainers "Anshuman Mohan")
 (source
  (github cornell-netlab/pifo-trees-artifact))
 (depends
  (csv
   (>= 2.4))
  (core_kernel
   (>= v0.15.0))
  (pcap-format
   (>= 0.6.0))
  (hex
   (>= 1.5.0))
  (mmap
   (>= 1.2.0))))
