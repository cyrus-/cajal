(lang dune 3.0)

(name cajal)

(generate_opam_files true)

(source
 (github cyrus-/cajal))

(license MIT)

(authors "Cyrus Omar")

(maintainers "Cyrus Omar")

(package
 (name cajal)
 (synopsis "Purkinje cells after Ramón y Cajal, grown by a growth-cone simulation")
 (depends
  (ocaml
   (>= 4.14))
  dune))
