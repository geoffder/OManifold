open OCADml
open Conv

module Status = struct
  type t = C.Types.Status.t =
    | NoError
    | NonFiniteVertex
    | NotManifold
    | VertexIndexOutOfBounds
    | PropertiesWrongLength
    | TriPropertiesWrongLength
    | TriPropertiesOutOfBounds

  let to_string = function
    | NoError -> "NO_ERROR"
    | NonFiniteVertex -> "NON_FINITE_VERTEX"
    | NotManifold -> "NOT_MANIFOLD"
    | VertexIndexOutOfBounds -> "VERTEX_INDEX_OUT_OF_BOUNDS"
    | PropertiesWrongLength -> "PROPERTIES_WRONG_LENGTH"
    | TriPropertiesWrongLength -> "TRI_PROPERTIES_WRONG_LENGTH"
    | TriPropertiesOutOfBounds -> "TRI_PROPERTIES_OUT_OF_BOUNDS"
end

type t = C.Types.Manifold.t Ctypes_static.ptr

let size = C.Funcs.manifold_size () |> size_to_int
let destruct t = C.Funcs.destruct_manifold t

let alloc () =
  let finalise = Mem.finaliser C.Types.Manifold.t destruct in
  let buf = Mem.allocate_buf ~finalise size in
  buf, Ctypes_static.(Ctypes.coerce (ptr void) (ptr C.Types.Manifold.t) buf)

let empty () =
  let buf, t = alloc () in
  let _ = C.Funcs.manifold_empty buf in
  t

let copy t =
  let buf, man = alloc () in
  let _ = C.Funcs.manifold_copy buf t in
  man

let as_original t =
  let buf, man = alloc () in
  let _ = C.Funcs.manifold_as_original buf t in
  man

let status t = C.Funcs.manifold_status t
let original_id t = C.Funcs.manifold_original_id t
let num_vert t = C.Funcs.manifold_num_vert t
let num_edge t = C.Funcs.manifold_num_edge t
let num_tri t = C.Funcs.manifold_num_tri t

let bounding_box t =
  let buf, box = Box.alloc () in
  let _ = C.Funcs.manifold_bounding_box buf t in
  box

let precision t = C.Funcs.manifold_precision t
let genus t = C.Funcs.manifold_genus t
let circular_segments t r = C.Funcs.manifold_get_circular_segments t r

let curvature t =
  let buf, curv = Curvature.alloc () in
  let _ = C.Funcs.manifold_get_curvature buf t in
  Curvature.of_ptr curv

let mesh_relation t =
  let buf, rel = MeshRelation.alloc () in
  let _ = C.Funcs.manifold_get_mesh_relation buf t in
  MeshRelation.of_ptr rel

(* Shapes *)

let tetrahedron () =
  let buf, t = alloc () in
  let _ = C.Funcs.manifold_tetrahedron buf in
  t

let sphere ?(fn = 32) rad =
  let buf, t = alloc () in
  let _ = C.Funcs.manifold_sphere buf rad fn in
  t

let cube ?(center = false) { x; y; z } =
  let buf, t = alloc () in
  let _ = C.Funcs.manifold_cube buf x y z (Bool.to_int center) in
  t

let cylinder ?(center = false) ?(fn = 32) ~height r =
  let buf, t = alloc () in
  let _ = C.Funcs.manifold_cylinder buf height r r fn (Bool.to_int center) in
  t

let cone ?(center = false) ?(fn = 32) ~height r1 r2 =
  let buf, t = alloc () in
  let _ = C.Funcs.manifold_cylinder buf height r1 r2 fn (Bool.to_int center) in
  t

let of_mmesh m =
  (* TODO: mesh properties type with optional provision *)
  let buf, t = alloc () in
  let _ = C.Funcs.manifold_of_mesh buf m in
  match status t with
  | NoError -> t
  | e ->
    failwith
      (Printf.sprintf "Faiure to build Manifold from mesh: %s" (Status.to_string e))

let smooth ?(smoothness = []) m =
  let open Ctypes in
  let buf, t = alloc () in
  let len = List.length smoothness in
  let edge_idxs = CArray.make int len
  and edge_ks = CArray.make float len in
  List.iteri
    (fun i (idx, s) ->
      CArray.set edge_idxs i idx;
      CArray.set edge_ks i s )
    smoothness;
  let idx_ptr = CArray.start edge_idxs
  and k_ptr = CArray.start edge_ks in
  let _ = C.Funcs.manifold_smooth buf m idx_ptr k_ptr (size_of_int len) in
  t

let compose ts =
  let buf, t = alloc () in
  let len = List.length ts in
  let ms = Ctypes.(CArray.make (ptr C.Types.Manifold.t) len) in
  List.iteri (fun i t -> Ctypes.CArray.set ms i t) ts;
  let _ = C.Funcs.manifold_compose buf (Ctypes.CArray.start ms) (size_of_int len) in
  t

let decompose t =
  let sz = C.Funcs.manifold_decompose_length t in
  let len = size_to_int sz in
  let bufs = Ctypes.(CArray.make (ptr void) len)
  and ts = ref [] in
  for i = 0 to len - 1 do
    let buf, man = alloc () in
    Ctypes.CArray.set bufs i buf;
    ts := man :: !ts
  done;
  let _ = C.Funcs.manifold_decompose (Ctypes.CArray.start bufs) t sz in
  !ts

(* 2D to 3D *)

let extrude ?(slices = 16) ?(twist = 0.) ?(scale = v2 1. 1.) ~height:h polys =
  (* TODO: take list of paths and build the polygons type within? Or just
    preemptively have a Polygons module in anticipation of more going in there
    other than of_paths and of_poly2? *)
  let buf, t = alloc ()
  and tw = Math.deg_of_rad twist in
  (* TODO: no default for slices and calculate based on twist *)
  let _ = C.Funcs.manifold_extrude buf polys h slices tw scale.x scale.y in
  t

let revolve ?(fn = 32) polys =
  (* TODO: see extrude *)
  let buf, t = alloc () in
  let _ = C.Funcs.manifold_revolve buf polys fn in
  t

(* Booleans *)

let add a b =
  let buf, t = alloc () in
  let _ = C.Funcs.manifold_union buf a b in
  t

let sub a b =
  let buf, t = alloc () in
  let _ = C.Funcs.manifold_difference buf a b in
  t

let intersect a b =
  let buf, t = alloc () in
  let _ = C.Funcs.manifold_intersection buf a b in
  t

let union = function
  | [] -> failwith "replace with manifold_empty"
  | [ _a ] -> failwith "replace with manifold_copy"
  | [ a; b ] -> add a b
  | a :: ts -> List.fold_left (fun t e -> add t e) a ts

let difference t = function
  | [] -> copy t
  | ts -> List.fold_left (fun t e -> sub t e) t ts

let intersection t = function
  | [] -> copy t
  | ts -> List.fold_left (fun t e -> intersect t e) t ts

let split a b =
  let buf1, first = alloc ()
  and buf2, second = alloc () in
  let _ = C.Funcs.manifold_split buf1 buf2 a b in
  first, second

let split_by_plane ({ a; b; c; d } : Plane.t) t =
  let buf1, first = alloc ()
  and buf2, second = alloc () in
  let _ = C.Funcs.manifold_split_by_plane buf1 buf2 t a b c d in
  first, second

let trim_by_plane ({ a; b; c; d } : Plane.t) t =
  let buf, trimmed = alloc () in
  let _ = C.Funcs.manifold_trim_by_plane buf t a b c d in
  trimmed

(* Transformations *)

let warp f t =
  let buf, warped = alloc () in
  let f x y z = Conv.vec3_of_v3 (f (v3 x y z)) in
  let f =
    Ctypes.(coerce (Foreign.funptr C.Funcs.warp_t) (static_funptr C.Funcs.warp_t) f)
  in
  let _ = C.Funcs.manifold_warp buf t f in
  warped

let translate { x; y; z } t =
  let buf, translated = alloc () in
  let _ = C.Funcs.manifold_translate buf t x y z in
  translated

let[@inline] xtrans x t = translate (v3 x 0. 0.) t
let[@inline] ytrans y t = translate (v3 0. y 0.) t
let[@inline] ztrans z t = translate (v3 0. 0. z) t

let rotate ?about r t =
  let { x; y; z } = V3.deg_of_rad r in
  let rot t =
    let buf, rotated = alloc () in
    let _ = C.Funcs.manifold_rotate buf t x y z in
    rotated
  in
  match about with
  | None -> rot t
  | Some p -> translate (V3.neg p) t |> rot |> translate p

let[@inline] xrot x t = rotate (v3 x 0. 0.) t
let[@inline] yrot y t = rotate (v3 0. y 0.) t
let[@inline] zrot z t = rotate (v3 0. 0. z) t

let affine (a : Affine3.t) t =
  let buf, transformed = alloc () in
  let _ =
    C.Funcs.manifold_transform
      buf
      t
      a.r0c0
      a.r1c0
      a.r2c0
      a.r0c1
      a.r1c1
      a.r2c1
      a.r0c2
      a.r1c2
      a.r2c2
      a.r0c3
      a.r1c3
      a.r2c3
  in
  transformed

let quaternion ?about q t =
  let a = Quaternion.to_affine q in
  match about with
  | None -> affine a t
  | Some p -> translate (V3.neg p) t |> affine a |> translate p

let axis_rotate ?about ax angle t = quaternion ?about (Quaternion.make ax angle) t

let scale { x; y; z } t =
  let buf, scaled = alloc () in
  let _ = C.Funcs.manifold_scale buf t x y z in
  scaled

let[@inline] xscale x t = scale (v3 x 1. 1.) t
let[@inline] yscale y t = scale (v3 1. y 1.) t
let[@inline] zscale z t = scale (v3 1. 1. z) t

let refine n t =
  let buf, refined = alloc () in
  let _ = C.Funcs.manifold_refine buf t n in
  refined

let set_circular_segments t fn = C.Funcs.manifold_set_circular_segments t fn

let set_min_circular_angle t fa =
  C.Funcs.manifold_set_min_circular_angle t (Math.deg_of_rad fa)

let set_min_circular_edge_length t fs = C.Funcs.manifold_set_min_circular_edge_length t fs

let to_mmesh t =
  let buf, mesh = MMesh.alloc () in
  let _ = C.Funcs.manifold_get_mesh buf t in
  mesh

let to_mmeshgl t =
  let buf, mesh = MMeshGL.alloc () in
  let _ = C.Funcs.manifold_get_meshgl buf t in
  mesh

let points t = MMesh.points (to_mmesh t)
let of_mesh ?normals ?tangents m = of_mmesh @@ MMesh.of_mesh ?normals ?tangents m
let to_mesh t = MMesh.to_mesh @@ to_mmesh t

let hull ts =
  let ps = List.fold_left (fun ps t -> List.rev_append (points t) ps) [] ts in
  of_mesh (Mesh.hull ps)
