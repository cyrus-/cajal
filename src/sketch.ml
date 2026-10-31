(* The few pieces the drawing needs: randomness, plane geometry and SVG.

   Everything is a pure function of its arguments. "Random" choices come
   from [Rng], where a value is a hash of the path of keys that leads to it,
   so the same seed always draws the same picture without threading any
   state. *)

(** {1 Randomness} *)

module Rng = struct
  type t = int

  let make (seed : int) : t = Hashtbl.hash ("flora", seed)
  let key (r : t) (k : string) : t = Hashtbl.hash (r, k)
  let nth (r : t) (i : int) : t = Hashtbl.hash (r, i)
  let unit r = float_of_int (Hashtbl.hash (r, "unit") land 0xffffff) /. 16777216.
  let range r lo hi = lo +. ((hi -. lo) *. unit r)
  let chance r p = unit r < p
end

(** {1 Geometry} *)

type v = { x : float; y : float }

let v x y = { x; y }
let ( +: ) a b = v (a.x +. b.x) (a.y +. b.y)
let ( -: ) a b = v (a.x -. b.x) (a.y -. b.y)
let ( *: ) k a = v (k *. a.x) (k *. a.y)
let dir a = v (cos a) (sin a)
let angle_of a = Float.atan2 a.y a.x
let pi = Float.pi
let up = -.pi /. 2.
let lerp a b t = a +. ((b -. a) *. t)

(* How far to turn from heading [a] to face [b], in (-pi, pi]. *)
let turn_to a b = Float.rem (b -. a +. (3. *. pi)) (2. *. pi) -. pi

(* A path from [p] whose heading is a function of the distance travelled,
   sampled about every [step]. *)
let curve ?(step = 2.) p length heading =
  let n = max 1 (int_of_float (length /. step)) in
  let step = length /. float n in
  let rec go i p acc =
    if i >= n then List.rev acc
    else
      let p = p +: (step *: dir (heading (float i *. step))) in
      go (i + 1) p (p :: acc)
  in
  go 0 p [ p ]

(** {1 SVG} *)

let num x =
  let s = Printf.sprintf "%.1f" x in
  if s = "-0.0" then "0" else s

let pt p = num p.x ^ "," ^ num p.y

let line_d = function
  | [] -> ""
  | p :: ps -> "M" ^ pt p ^ String.concat "" (List.map (fun p -> "L" ^ pt p) ps)

(* A closed path of cubic Béziers, each given as two controls and an end. *)
let cubic_d start segs =
  "M" ^ pt start
  ^ String.concat "" (List.map (fun (a, b, c) -> "C" ^ pt a ^ " " ^ pt b ^ " " ^ pt c) segs)
  ^ "Z"

let attrs kvs = String.concat "" (List.map (fun (k, v) -> Printf.sprintf " %s=\"%s\"" k v) kvs)
let path d a = Printf.sprintf "<path d=\"%s\"%s/>" d (attrs a)
let circle c r a = Printf.sprintf "<circle cx=\"%s\" cy=\"%s\" r=\"%s\"%s/>" (num c.x) (num c.y) (num r) (attrs a)
let fill c = ("fill", c)
let stroke c w = [ ("stroke", c); ("stroke-width", num w) ]
let round = [ ("stroke-linecap", "round"); ("stroke-linejoin", "round") ]
let no_fill = fill "none"
