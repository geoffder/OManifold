open OCADml

module Curvature : sig
  module Bounds : sig
    type t =
      { min_mean : float
      ; max_mean : float
      ; min_gaussian : float
      ; max_gaussian : float
      }
  end

  (** Computed vertex curvatures of a {!Manifold.t}

     The inverse of the radius of curvature, and signed such that
     positive is convex and negative is concave. There are two orthogonal
     principal curvatures at any point on a manifold, with one maximum and the
     other minimum. Gaussian curvature is their product, while mean curvature is
     their sum. This approximates them for every vertex (returned as vectors in
     the structure) and also returns their minimum and maximum values. *)
  type t =
    { bounds : Bounds.t
    ; vert_mean : float list
    ; vert_gaussian : float list
    }
end

module MeshRelation : sig
  module BaryRef : sig
    type t =
      { mesh_id : int (** unique ID to the particular instance of the mesh *)
      ; original_id : int (** ID corresponding to the source mesh *)
      ; tri : int (** triangle index in the source mesh to which {!vert_bary} refers *)
      ; vert_bary : int * int * int
            (** an index for each vertex into the {!barycentric} list if that
   index is [>= 0], indicating it is a new vertex, otherwise, if the index is [<
    0], this indicates it is an original vertex (the [index + 3] vertex of the
   reference triangle) *)
      }
  end

  type t =
    { barycentric : v3 list
    ; tri_bary : BaryRef.t list (** same length as {!MMesh.points} *)
    }
end

module Polygons : sig
  type t

  (** {1 Constructors}*)

  (** [make paths]

       Create a set of polygons from a set of 2d paths. These can vary from
       arbitrarily nested to completely separate, describing one or more complex
       polygons with holes. *)
  val make : Path2.t list -> t

  (** {1 OCADml Conversion}

       These are nothing special, but are provided for convenience (prepending
       the outer path onto the list of holes before applying {!make}). *)

  (** [of_path path]

      Lift a 2d {!OCADml.Path2.t} into a manifold polygon set. *)
  val of_path : Path2.t -> t

  (** [of_paths paths]

       Lump together a set of 2d {!OCADml.Path2.t}s into a manifold polygon
       set. Equivalent to {!make}. *)
  val of_paths : Path2.t list -> t

  (** [of_poly2 poly]

       Lift a 2d {!OCADml.Poly2.t} into a manifold polygon set. *)
  val of_poly2 : Poly2.t -> t

  (** [of_poly2s polys]

       Lump together a set of 2d {!OCADml.Poly2.t}s into a manifold polygon set. *)
  val of_poly2s : Poly2.t list -> t
end

module MMesh : sig
  (** Mesh properties which can optionally be provided to {!Manifold.of_mmesh}. *)
  type properties =
    { tris : (int * int * int) list (** Indices into props for each tri of the mesh *)
    ; props : float list
          (** Sets of property values, the length of which should be the largest
                 index in [tris] times the length of [tolerances] (the number of properties).
                 Think of it as a property matrix indexed as [idx * n_tolerances + tolerance_idx]. *)
    ; tolerances : float list
          (** Precision values. This is the amount of interpolation error allowed
              before two neighouring triangles are considered not coplanar.
              A good place to start is [1e-5] times the largest value you expect
              this property to take. *)
    }

  (** The 3-dimensional mesh representation of the Manifold library. *)
  type t

  (** {1 Constructor} *)

  (** [make ?normals ?tangents points triangles]

       Create a manifold mesh from a set of [points], and [triangles]
       represented as triples of indices into [points]. Vertex [normals] and
       half-edge [tangents] can optionally be provided. If so, they must be the
       same length as [points] and 3x the length of [triangles] respectively --
       [Invalid_argument] will be raised otherwise. *)
  val make
    :  ?normals:v3 list
    -> ?tangents:v4 list
    -> v3 list
    -> (int * int * int) list
    -> t

  (** {1 Data Extraction} *)

  (** [points t]

       Retrieve the points making up the mesh [t]. *)
  val points : t -> v3 list

  (** [triangles t]

       Retrieve the triangular faces of the mesh [t] as triples of indices into
       its {!points}. *)
  val triangles : t -> (int * int * int) list

  (** [normals t]

       Retrieve the vertex normals of the mesh [t] (same length as {!points}). *)
  val normals : t -> v3 list

  (** [halfedge_tangents t]

       Retrieve the halfedge tangents of the mesh [t] (three for each of the
       [t]'s {!triangles}). *)
  val halfedge_tangents : t -> v4 list

  (** {1 OCADml conversion}

      To and from the OCADml [Mesh.t] type. As [Mesh.t] follows the OpenSCAD
      winding convention (opposite to manifold) the triangles/faces are
      reversed. *)

  (** [of_mesh m]

       Create a manifold mesh from the [OCADml.Mesh.t] [m].  *)
  val of_mesh : Mesh.t -> t

  (** [to_mesh t]

       Create an [OCADml.Mesh.t] from the manifold mesh [t].  *)
  val to_mesh : t -> Mesh.t
end

module MMeshGL : sig
  (** A graphics library friendly representation of manifold's {!MMesh.t}.
       Obtained solely via {!Manifold.to_mmeshgl} *)
  type t

  (** {1 Data Extraction} *)

  val points : t -> float list
  val triangles : t -> int list
  val normals : t -> float list
  val halfedge_tangents : t -> float list
end

module Box : sig
  (** The 3-dimensional bounding box representation of the Manifold library. *)
  type t

  (** {1 Constructor} *)

  (** [make a b]

       Create a bounding box that contains the points [a] and [b]. *)
  val make : v3 -> v3 -> t

  (** {1 Data / Queries} *)

  (** [min t]

       The minimum bound of the box [t]. *)
  val min : t -> v3

  (** [max t]

       The maximum bound of the box [t]. *)
  val max : t -> v3

  (** [center t]

       The center point of the box [t]. *)
  val center : t -> v3

  (** [dimensions t]

       The 3-dimensional extent (xyz) of the box [t]. *)
  val dimensions : t -> v3

  (** [abs_max_coord t]

       The absolute largest dimensional coordinate of the box [t]. *)
  val abs_max_coord : t -> float

  (** [contains_pt t p]

       Determine whether the box [t] contains the point [p]. *)
  val contains_pt : t -> v3 -> bool

  (** [contains_box a b]

       Determine whether the box [a] contains the box [b]. *)
  val contains_box : t -> t -> bool

  (** [overlaps_pt t p]

       Determine whether the projection/shadow of the box [t] on the xy plane
       contains that of the point [p]. *)
  val overlaps_pt : t -> v3 -> bool

  (** [overlaps_box a b]

       Determine whether the projection/shadow of the box [a] on the xy plane
       overlaps that of the box [b]. *)
  val overlaps_box : t -> t -> bool

  (** [is_finite t]

       Determine whether the box [t] is finite. *)
  val is_finite : t -> bool

  (** {1 Booleans} *)

  (** [union a b]

       Return the union of the boxes [a] and [b] (enveloping the space of
       both). *)
  val union : t -> t -> t

  (** [include_pt t p]

       Expand the box [t] (mutating it) to include the point [p]. *)
  val include_pt : t -> v3 -> unit

  (** {1 Transformations} *)

  (** [translate p t]

       Move the box [t] along the vector [p]. *)
  val translate : v3 -> t -> t

  (** [scale factors t]

       Scale (multiply) the box [t] by the given xyz [factors]. *)
  val scale : v3 -> t -> t

  (** [transform m t]

       Transform box [t] with the affine transformation matrix [m]. *)
  val transform : Affine3.t -> t -> t

  (** {1 OCADml conversion} *)

  (** [of_bbox b]

       Construct a manifold box from the bounds of the 3d OCADml bounding box [b]. *)
  val of_bbox : V3.bbox -> t

  (** [to_bbox t]

       Return the minimum and maximum bounds of the manifold box [t] as an
       OCADml bounding box. *)
  val to_bbox : t -> V3.bbox
end

module Manifold : sig
  module Id : sig
    (** Unique identifier for a manifold {!type:t}, or a tag indicating that it
          is the result of transformations/operations on original/product manifolds *)
    type t =
      | Original of int
      | Product

    (** [to_int t]

          Return the plain integer ID. If the corresponding manifold was a
          product, rather than an original, this returns [-1]. *)
    val to_int : t -> int
  end

  (** Spatial properties of a {!Manifold.t}, returned by {!val:size} *)
  type size =
    { surface_area : float
    ; volume : float
    }

  type t

  (** {1 Basic Constructors} *)

  (** [empty ()]

       Construct an empty manifold. *)
  val empty : unit -> t

  (** [copy t]

       Return a copy of the manifold [t]. *)
  val copy : t -> t

  (** [as_original t]

       If you copy a manifold, but you want this new copy to have new properties
       (e.g. a different UV mapping), you can reset its {!MeshRelation.BaryRef.mesh_id} to a new original,
       meaning it will now be referenced by its descendents instead of the meshes it
       was built from, allowing you to differentiate the copies when applying your
       properties to the final result.

       This function also condenses all coplanar faces in the relation, and
       collapses those edges. If you want to have inconsistent properties across
       these faces, meaning you want to preserve some of these edges, you should
       instead use {!to_mmesh}, calculate your properties and use these to construct
       a new manifold. *)
  val as_original : t -> t

  (** [compose ts]
       Constructs a new manifold from a list of other manifolds. This is a purely
       topological operation, so care should be taken to avoid creating
       overlapping results. It is the inverse operation of {!decompose}. *)
  val compose : t list -> t

  (** [decompose t]

       This operation returns a list of manifolds that are topologically
       disconnected. If everything is connected, the result is singular copy of
       the original. It is the inverse operation of {!compose}. *)
  val decompose : t -> t list

  (** {1 Shapes} *)

  (** [tetrahedron ()]

       Create a tetrahedron centred at the origin with one vertex at
       [(v3 1. 1. 1.)] and the rest at similarly symmetric points. *)
  val tetrahedron : unit -> t

  (** [sphere ?fn radius]

       Create a sphere with given [radius] at the origin of the coordinate
       system. The number of segments along the diameter can be explicitly set by
       [fn], otherwise it is determined by the {{!section-quality} quality globals}. *)
  val sphere : ?fn:int -> float -> t

  (** [cube ?center dimensions]

    Create a cube in the first octant, with the given xyz [dimensions]. When
    [center] is true, the cube is centered on the origin. *)
  val cube : ?center:bool -> v3 -> t

  (** [cylinder ?center ?fn ~height radius]

     Creates a cylinder centered about the z-axis. When [center] is true, it will
     also be centered vertically, otherwise the base will sit upon the XY
     plane. The number of segments along the diameter can be explicitly set by
     [fn], otherwise it is determined by the {{!section-quality} quality globals}. *)
  val cylinder : ?center:bool -> ?fn:int -> height:float -> float -> t

  (** [cone ?center ?fn ~height r1 r2 ]

     Create cone with bottom radius [r1] and top radius [r2]. When [center] is
     true, it will also be centered vertically, otherwise the base will sit upon
     the XY plane. The number of segments along the diameter can be explicitly set by
     [fn], otherwise it is determined by the {{!section-quality} quality globals}.*)
  val cone : ?center:bool -> ?fn:int -> height:float -> float -> float -> t

  (** {1 Mesh Conversions} *)

  (** [of_mmesh ?properties m]

       Create a manifold from the mesh [m], returning [Error] if [m] is not an
       oriented 2-manifold. Will collapse degenerate triangles and unnecessary
       vertices. If [properties] is provided, it will be used to determine which
       coplanar triangles can be safely merged due to all properties being colinear
       (the properties themselves are not stored as part of the {!MMesh.t}). Any
       edges that define property boundaries will be retained in the output of
       arbitrary boolean operations such that these properties can be properly
       reapplied to the result using the {!MeshRelation.t}. *)
  val of_mmesh : ?properties:MMesh.properties -> MMesh.t -> (t, string) result

  (** [of_mmesh_exn ?properties m]

       Same as {!of_mmesh}, but raising a [Failure] rather than returning an
       [Error]. *)
  val of_mmesh_exn : ?properties:MMesh.properties -> MMesh.t -> t

  (** [of_mesh m]

       Create a manifold from an OCADml mesh [m], returning [Error] if [m] is
       not an oriented 2-manifold. Will collapse degenerate triangles and
       unnecessary vertices. *)
  val of_mesh : Mesh.t -> (t, string) result

  (** [of_mesh_exn ?properties m]

       Same as {!of_mesh}, but raising a [Failure] rather than returning an
       [Error]. *)
  val of_mesh_exn : Mesh.t -> t

  (** [smooth ?smoothness m]

       Constructs a smooth version of the input mesh [m] by creating tangents,
       returning an error if you have already supplied tangents for it. The actual
       triangle resolution is unchanged, thus you will likely want to follow up
       with {!refine} to interpolate to higher-resolution curves.

       By default, every edge is calculated for maximum smoothness (very much
       approximately), attempting to minimize the maximum mean Curvature magnitude.
       No higher-order derivatives are considered, as the interpolation is
       independent per triangle, only sharing constraints on their boundaries.
       To control the relative smoothness at particular halfedges (ideally
       limited to a small subset of all halfedges), [smoothness] can be provided
       with [(index, s)] pairs specifying a smoothness factor [s] between [0.]
       and [1.] for the [index] interperpreted as [3 * triangle + {0,1,2}] where
       [0] is the edge between the first and second vertices of the [triangle].

       At a smoothness value of zero, a sharp crease is made. The smoothness is
       interpolated along each edge, so the specified value should be thought of as
       an average. Where exactly two sharpened edges meet at a vertex, their
       tangents are rotated to be colinear so that the sharpened edge can be
       continuous. Vertices with only one sharpened edge are completely smooth,
       allowing sharpened edges to smoothly vanish at termination. A single vertex
       can be sharpened by sharping all edges that are incident on it, allowing
       cones to be formed. *)
  val smooth : ?smoothness:(int * float) list -> MMesh.t -> (t, string) result

  (** [smooth_exn ?smoothness m]

       Same as {!smooth}, but raising [Failure] rather than returning [Error]. *)
  val smooth_exn : ?smoothness:(int * float) list -> MMesh.t -> t

  (** [to_mmesh t]

       Obtain a mesh describing the shape of the manifold [t]. *)
  val to_mmesh : t -> MMesh.t

  (** [to_mmeshgl t]

       Obtain a graphics library (gl) friendly mesh representation of the manifold [t]. *)
  val to_mmeshgl : t -> MMeshGL.t

  (** [to_mesh t]

       Obtain an OCADml mesh describing the shape ot the manifold [t]. *)
  val to_mesh : t -> Mesh.t

  (** {1 2D to 3D} *)

  (** [extrude ?slices ?twist ?scale ~height polygons]

    Vertically extrude non-overlapping set of 2d [polygons] from the XY plane to
    [height]. If [?center] is [true], the resulting 3D object is centered around
    the XY plane, rather than resting on top of it.
    - [?twist] rotates the shape by the specified angle (in radians) as it is
      extruded upwards
    - [?slices] specifies the number of intermediate points along the Z axis of
      the extrusion. By default this increases with the value of [?twist],
      though manual refinement may improve results.
    - [?scale] expands or contracts the shape in X and Y as it is extruded
      upward. Default is [(v2 1. 1.)], no scaling. If set to [(v2 0. 0.)], a
      pure cone is formed, with only a single vertex at the top. *)
  val extrude
    :  ?slices:int
    -> ?fa:float
    -> ?twist:float
    -> ?scale:v2
    -> ?center:bool
    -> height:float
    -> Polygons.t
    -> t

  (** [revolve ?fn polygons]

       Revolve a non-overapping set of 2d [polygons] around the y-axis and then set this
       as the z-axis of the resulting manifold. If the polygons cross the y-axis, only
       the part on the positive x side is used. Geometrically valid input will result
       in geometrically valid output. The number of segments in the revolution
       can be set explicitly with [fn], otherwise it is determined by the
       {{!section-quality} quality globals}. *)
  val revolve : ?fn:int -> Polygons.t -> t

  (** {1 Booleans} *)

  (** [add a b]

       Union (logical {b or}) the manifolds [a] and [b]. *)
  val add : t -> t -> t

  (** [union ts]

       Union (logical {b or}) the list of manifolds [ts]. *)
  val union : t list -> t

  (** [sub a b]

       Subtract (logical {b and not}) the manifold [b] from the manifold [a]. *)
  val sub : t -> t -> t

  (** [difference t d]

       Subtract (logical {b and not}) the list of manifolds [d] from the manifold [t]. *)
  val difference : t -> t list -> t

  (** [intersection ts]

       Compute the intersection (logical {b and}) of the manifolds [ts]. Only
       the area which is common or shared by {b all } shapes are retained. If
       [ts] is empty, an empty manifold {!t} will result. *)
  val intersection : t list -> t

  (** [split a b]

       Splits the manifold [a] into two using the cutter manifold [b]. The
       first result is the intersection, and the second is the difference. *)
  val split : t -> t -> t * t

  (** [split_by_plane p t]

       Splits the manifold [t] in two, one above the plane [p], and the other below. *)
  val split_by_plane : Plane.t -> t -> t * t

  (** [trim_by_plane p t]

       Cut away the portion of the manifold [t] lying below the plane [p]. *)
  val trim_by_plane : Plane.t -> t -> t

  (** {1 Transformations} *)

  (** [translate p t]

       Move [t] along the vector [p]. *)
  val translate : v3 -> t -> t

  (** [xtrans x t]

    Move [t] by the distance [x] along the x-axis. *)
  val xtrans : float -> t -> t

  (** [ytrans y t]

    Move [t] by the distance [y] along the y-axis. *)
  val ytrans : float -> t -> t

  (** [ztrans z t]

    Move [t] by the distance [z] along the z-axis. *)
  val ztrans : float -> t -> t

  (** [rotate ?about r t]

    Performs an Euler rotation (zyx). If it is provided, rotations are performed
    around the point [about], otherwise rotation is about the origin. Angle(s)
    [r] are in radians. *)
  val rotate : ?about:v3 -> v3 -> t -> t

  (** [xrot ?about r t]

    Rotate the manifold [t] around the x-axis through the origin (or the point
    [about] if provided) by [r] (in radians). *)
  val xrot : float -> t -> t

  (** [yrot ?about r t]

    Rotate the manifold [t] around the y-axis through the origin (or the point
    [about] if provided) by [r] (in radians). *)
  val yrot : float -> t -> t

  (** [zrot ?about r t]

    Rotate the manifold [t] around the z-axis through the origin (or the point
    [about] if provided) by [r] (in radians). *)
  val zrot : float -> t -> t

  (** [affine m t]

    Transform the manifold [t] with the affine transformation matrix [m]. *)
  val affine : Affine3.t -> t -> t

  (** [quaternion ?about q t]

    Applys the quaternion rotation [q] around the origin (or the point [about]
    if provided) to [t]. *)
  val quaternion : ?about:v3 -> Quaternion.t -> t -> t

  (** [axis_rotate ?about ax r t]

    Rotates [t] about the arbitrary axis [ax] through the origin (or the point
    [about] if provided) by the angle [r] (in radians). *)
  val axis_rotate : ?about:v3 -> v3 -> float -> t -> t

  (** [warp f t]

       Map over the vertices of the manifold [t] with the function [f], allowing
       their positions to be updated arbitrarily, but note that the topology is
       unchanged. It is easy to create a function that warps a geometrically valid
       object into one which overlaps, but that is not checked here, so it is up to
       the user to choose their function with discretion. *)
  val warp : (v3 -> v3) -> t -> t

  (** [scale factors t]

    Scales [t] by the given [factors] in xyz. *)
  val scale : v3 -> t -> t

  (** [xscale s t]

    Scales [t] by the factor [s] in the x-dimension. *)
  val xscale : float -> t -> t

  (** [yscale s t]

    Scales [t] by the factor [s] in the y-dimension. *)
  val yscale : float -> t -> t

  (** [zscale s t]

    Scales [t] by the factor [s] in the z-dimension. *)
  val zscale : float -> t -> t

  (** [refine n t]

       Increase the density of the meshes in [t] by splitting every edge into
       [n] pieces. For instance, with [n = 2], each triangle will be split into 4
       triangles. These will all be coplanar (and will not be immediately collapsed)
       unless the contained {!MMesh.t} within has {!MMesh.halfedge_tangents}
       specified (e.g. from the {!smooth} constructor), in which case the new
       vertices will be moved to the interpolated surface according to their
       barycentric coordinates. *)
  val refine : int -> t -> t

  (** [hull ts]

       Create a convex hull that encloses all of the vertices of the manifolds
       in [ts]. Note that this operation comes from OCADml and is not guaranteed
       to produce a valid manifold. *)
  val hull : t list -> (t, string) result

  (** [hull_exn ts]

       Same as {!hull}, but a [Failure] is raised if the resulting mesh does
       not describe a valid manifold. *)
  val hull_exn : t list -> t

  (** {1 Data Extraction} *)

  (** [original_id t]

       If this mesh is an original, this returns its
       {!MeshRelation.BaryRef.mesh_id} that can be referenced by product manifolds'
       {!MeshRelation.t}. *)
  val original_id : t -> Id.t

  (** [num_vert t]

       The number of vertices in the manifold [t]. *)
  val num_vert : t -> int

  (** [num_edge t]

       The number of edges in the manifold [t]. *)
  val num_edge : t -> int

  (** [num_tri t]

       The number of triangles in the manifold [t]. *)
  val num_tri : t -> int

  (** [bounding_box t]

       Return the axis-aligned bounding box of all of the manifold [t]'s
       vertices. *)
  val bounding_box : t -> Box.t

  (** [precision t]
       Returns the precision of this manifold's vertices, which tracks the
       approximate rounding error over all the transforms and operations that have
       led to this state. Any triangles that are colinear within this precision are
       considered degenerate and removed. This is the value of &epsilon; defining
       {{:https://github.com/elalish/manifold/wiki/manifold-Library#definition-of-%CE%B5-valid}
       &epsilon;-valid}. *)
  val precision : t -> float

  (** [genus t]

       The genus is a topological property of the manifold, representing the
       number of "handles". A sphere is 0, torus 1, etc. It is only meaningful
       for a single mesh, so it is best use {!decompose} first. *)
  val genus : t -> int

  (** [size t]

       The physical size (surface area and volume) of the manifold [t]. *)
  val size : t -> size

  (** [curvature t]

       The inverse of the radius of curvature, and signed such that
       positive is convex and negative is concave. There are two orthogonal
       principal curvatures at any point on a manifold, with one maximum and the
       other minimum. Gaussian curvature is their product, while mean curvature is
       their sum. This approximates them for every vertex (returned as vectors in
       the structure) and also returns their minimum and maximum values. *)
  val curvature : t -> Curvature.t

  (** [mesh_relation t]

       Gets the relationship to the previous meshes, for the purpose of
       assigning properties like texture coordinates. The
       {!MeshRelation.tri_bary} vector is the same length as
       {!MMesh.points}: {!MeshRelation.BaryRef.original_id} indicates the source
       mesh and {!MeshRelation.BaryRef.tri} is that mesh's triangle index to which
       these barycentric coordinates refer. {!MeshRelation.BaryRef.vert_bary} gives
       an index for each vertex into the barycentric vector if that index is >= 0,
       indicating it is a new vertex. If the index is < 0, this indicates it is an
       original vertex, the index + 3 vert of the referenced triangle.

       {!MeshRelation.BaryRef.mesh_id} is a unique ID to the particular instance
       of a given mesh.  For instance, if you want to convert the triangle mesh to a
       polygon mesh, all the triangles from a given face will have the same
       [mesh_id] and [tri] values. *)
  val mesh_relation : t -> MeshRelation.t

  (** [points t]

       Retrieve the points making up the meshes of the manifold [t]. *)
  val points : t -> v3 list

  (** {1:quality Quality Globals}

       Akin to {{:https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/The_OpenSCAD_Language#$fa,_$fs_and_$fn}OpenSCAD}'s facet governing "special"
       parameters, [$fn], [$fa], and [$fs]. These are global variables that are
       handy for quickly switching from quick and dirty rough iteration
       quality to computationally expensive smooth final products. *)

  (** [get_circular_segments r]

       Determine how many segment there would be in a circle with radius [r],
       based on the global quality parameters (set by {!set_circular_segments},
       {!set_min_circular_angle}, and {!set_min_circular_edge_length}). *)
  val get_circular_segments : float -> int

  (** [set_circular_segments fn]

       Set a default number of segments that circular shape are drawn with (by
       default this is unset, and minimum circular angle and length are used to
       calculate the number of segments instead). This takes precedence over both
       minumum circular angle and edge length, and is akin to defining the special
       [$fn] variable at the top level of an {{:https://openscad.org/}OpenSCAD} script. *)
  val set_circular_segments : int -> unit

  (** [set_min_circular_angle fa]

       Change the default minimum angle (in radians) between consecutive segments on a
       circular object/edge (default is [pi /. 18.]). This is akin to setting
       the special [$fa] variable at the top level of an
       {{:https://openscad.org/}OpenSCAD} script. *)
  val set_min_circular_angle : float -> unit

  (** [set_min_circular_edge_length fs]

       Change the default minimum edge length for segments that that circular
       objects/edges are drawn with (default = [1.]). This is akin to setting
       the special [$fs] variable at the top level of an
       {{:https://openscad.org/}OpenSCAD} script. *)
  val set_min_circular_edge_length : float -> unit
end

module Sdf2 : sig
  type t = OCADml.v2 -> float

  (** {1 Shapes} *)

  val circle : float -> t
  val square : ?round:float -> v2 -> t
  val rounded_box : ?tl:float -> ?tr:float -> ?bl:float -> ?br:float -> v2 -> t
  val rhombus : ?round:float -> v2 -> t

  (** {1 Transformations} *)

  val translate : v2 -> t -> t
  val xtrans : float -> t -> t
  val ytrans : float -> t -> t
  val rotate : ?about:v2 -> float -> t -> t
  val zrot : ?about:v2 -> float -> t -> t
  val scale : float -> t -> t
  val round : float -> t -> t
  val onion : float -> t -> t

  (** [elongate h]

       Elongate the 2d sdf [t] by the xy distance vector [h]. Basically, the
       field is split and moved apart by [h] in each dimension and connected. *)
  val elongate : v2 -> t -> t

  (** {1 2d to 3d} *)

  (** [extrude ~height t]

       Extrude the 2d signed distance field [t] into a 3d field extending
       [height /. 2.] above and below the xy plane. *)
  val extrude : height:float -> t -> Sdf3.t

  (** [revolve ?offset t]

       Revolve the 2d signed distance field [t] around the
       y-axis. If provided [offset] translates [t] in x beforehand. *)
  val revolve : ?offset:float -> t -> Sdf3.t
end

module Sdf3 : sig
  (** A negative inside, positive outside signed-distance function. *)
  type t = v3 -> float

  (** {1 Shapes} *)

  val sphere : float -> t
  val cube : ?round:float -> v3 -> t
  val torus : v2 -> t
  val cylinder : ?round:float -> height:float -> float -> t

  (** {1 Transformations} *)

  val translate : v3 -> t -> t
  val xtrans : float -> t -> t
  val ytrans : float -> t -> t
  val ztrans : float -> t -> t
  val rotate : ?about:v3 -> v3 -> t -> t
  val xrot : ?about:v3 -> float -> t -> t
  val yrot : ?about:v3 -> float -> t -> t
  val zrot : ?about:v3 -> float -> t -> t
  val quaternion : ?about:v3 -> Quaternion.t -> t -> t
  val axis_rotate : ?about:v3 -> v3 -> float -> t -> t
  val scale : float -> t -> t
  val round : float -> t -> t
  val onion : float -> t -> t
  val elongate : v3 -> t -> t

  (** {1 Booleans} *)

  val union : ?smooth:float -> t -> t -> t
  val difference : ?smooth:float -> t -> t -> t
  val intersection : ?smooth:float -> t -> t -> t

  (** {1 Mesh Generation} *)

  (** [to_mmesh ?level ?edge_length ~box t]

       Constructs a level-set Mesh from the signed-distance function [t].
       This uses a form of Marching Tetrahedra (akin to Marching Cubes, but better
       for manifoldness). Instead of using a cubic grid, it uses a body-centered
       cubic grid (two shifted cubic grids). This means if your function's interior
       exceeds the given bounds, you will see a kind of egg-crate shape closing off
       the manifold, which is due to the underlying grid. The output is
       guaranteed to be manifold, thus should always be an appropriate input to
       {!Manifold.of_mmesh}.

      - [box] is and axis-aligned bounding box defining the extent of the grid
        overwhich [t] is evaluated
      - [edge_length] is the the approximate maximum edge length of the triangles
        in the final result. This affects grid spacing, thus strongly impacting performance.
      - [level] can be provided with a positive value to inset the mesh, or a
        negative value to outset it (default is [0.] -- no offset) *)
  val to_mmesh : ?level:float -> ?edge_length:float -> box:Box.t -> t -> MMesh.t
end

module Export : sig
  (** Writing manifold meshes to disk via {{:https://github.com/assimp/assimp}
    Open Asset Import Library (assimp)}. *)

  module Material : sig
    type t

    val make
      :  ?roughness:float
      -> ?metalness:float
      -> ?color:v4
      -> ?vert_color:v4 list
      -> unit
      -> t
  end

  module Opts : sig
    (** Export options *)
    type t

    val make : ?faceted:bool -> ?material:Material.t -> unit -> t
  end

  val mmesh : ?opts:Opts.t -> string -> MMesh.t -> unit
  val manifold : ?opts:Opts.t -> string -> Manifold.t -> unit
end
