(* cajal: draw Purkinje cells as SVG.

     cajal [--seed N] [--ink sepia|forest|indigo] [-o FILE]
     cajal --gallery DIR [--from N] [--count K] [--ink NAME]

   The first form writes one cell (to standard output unless -o is given);
   the second writes a run of seeds and an index.html to look at them. *)

open Cajal

let write file contents = Out_channel.with_open_bin file (fun oc -> Out_channel.output_string oc contents)

let gallery ~dir ~from ~count ~ink =
  if not (Sys.file_exists dir) then Sys.mkdir dir 0o755;
  let seeds = List.init count (fun i -> from + i) in
  List.iter
    (fun seed -> write (Filename.concat dir (Printf.sprintf "seed-%d.svg" seed)) (Purkinje.draw ~ink seed))
    seeds;
  let figure seed =
    Printf.sprintf "<figure><img src=\"seed-%d.svg\" alt=\"Purkinje cell, seed %d\"><figcaption>seed %d</figcaption></figure>"
      seed seed seed
  in
  write (Filename.concat dir "index.html")
    (Printf.sprintf
       "<!doctype html><meta charset=\"utf-8\"><title>Purkinje cells</title><style>body{margin:24px;background:#f5deb3;font:14px \
        system-ui,sans-serif;color:#6b5a45}main{display:grid;grid-template-columns:repeat(auto-fill,minmax(280px,1fr));gap:24px}figure{margin:0}img{width:100%%;display:block}</style><main>%s</main>"
       (String.concat "" (List.map figure seeds)))

let () =
  let seed = ref 1 and ink = ref "sepia" and out = ref "" in
  let dir = ref "" and from = ref 1 and count = ref 8 in
  Arg.parse
    [
      ("--seed", Arg.Set_int seed, "N  which cell to draw (default 1)");
      ("--ink", Arg.Set_string ink, "NAME  sepia (default), forest or indigo");
      ("-o", Arg.Set_string out, "FILE  write the SVG here instead of standard output");
      ("--gallery", Arg.Set_string dir, "DIR  write a run of seeds and an index.html into DIR");
      ("--from", Arg.Set_int from, "N  first seed of the gallery (default 1)");
      ("--count", Arg.Set_int count, "K  how many seeds in the gallery (default 8)");
    ]
    (fun a -> raise (Arg.Bad ("unexpected argument " ^ a)))
    "cajal: draw Purkinje cells after Ramón y Cajal, as SVG";
  match Purkinje.ink_named !ink with
  | None ->
      prerr_endline ("cajal: unknown ink " ^ !ink ^ " (try sepia, forest or indigo)");
      exit 2
  | Some ink ->
      if !dir <> "" then gallery ~dir:!dir ~from:!from ~count:!count ~ink
      else
        let svg = Purkinje.draw ~ink !seed in
        if !out = "" then print_string svg else write !out svg
