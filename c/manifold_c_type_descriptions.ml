module Types (F : Cstubs.Types.TYPE) = struct
  open Ctypes
  open F

  module Status = struct
    let no_error = constant "NO_ERROR" int64_t
    let non_finite_vertex = constant "NON_FINITE_VERTEX" int64_t
    let not_manifold = constant "NOT_MANIFOLD" int64_t
    let vertex_index_out_of_bounds = constant "VERTEX_INDEX_OUT_OF_BOUNDS" int64_t
    let properties_wrong_length = constant "PROPERTIES_WRONG_LENGTH" int64_t
    let tri_properties_wrong_length = constant "TRI_PROPERTIES_WRONG_LENGTH" int64_t
    let tri_properties_out_of_bounds = constant "TRI_PROPERTIES_OUT_OF_BOUNDS" int64_t

    type t =
      | NoError
      | NonFiniteVertex
      | NotManifold
      | VertexIndexOutOfBounds
      | PropertiesWrongLength
      | TriPropertiesWrongLength
      | TriPropertiesOutOfBounds

    let t =
      enum
        "ManifoldError"
        [ NoError, no_error
        ; NonFiniteVertex, non_finite_vertex
        ; NotManifold, not_manifold
        ; VertexIndexOutOfBounds, vertex_index_out_of_bounds
        ; PropertiesWrongLength, properties_wrong_length
        ; TriPropertiesWrongLength, tri_properties_wrong_length
        ; TriPropertiesOutOfBounds, tri_properties_out_of_bounds
        ]
        ~unexpected:(fun _ -> assert false)
  end

  module Manifold = struct
    type t = [ `Manifold ] structure

    let t : t typ = structure "ManifoldManifold"
  end

  module SimplePolygon = struct
    type t = [ `SimplePolygon ] structure

    let t : t typ = structure "ManifoldSimplePolygon"
  end

  module Polygons = struct
    type t = [ `Polygons ] structure

    let t : t typ = structure "ManifoldPolygons"
  end

  module Mesh = struct
    type t = [ `Mesh ] structure

    let t : t typ = structure "ManifoldMesh"
  end

  module MeshGL = struct
    type t = [ `MeshGL ] structure

    let t : t typ = structure "ManifoldMeshGL"
  end

  module Curvature = struct
    type t = [ `Curvature ] structure

    let t : t typ = structure "ManifoldCurvature"
  end

  module Components = struct
    type t = [ `Components ] structure

    let t : t typ = structure "ManifoldComponents"
  end

  module Properties = struct
    type t = [ `Properties ] structure

    let t : t typ = structure "ManifoldProperties"
    let surface_area = field t "surface_area" float
    let volume = field t "volume" float
    let () = seal t
  end

  module MeshRelation = struct
    type t = [ `MeshRelation ] structure

    let t : t typ = structure "ManifoldMeshRelation"
  end

  module Box = struct
    type t = [ `Box ] structure

    let t : t typ = structure "ManifoldBox"
  end

  module Material = struct
    type t = [ `Material ] structure

    let t : t typ = structure "ManifoldMaterial"
  end

  module ExportOptions = struct
    type t = [ `ExportOptions ] structure

    let t : t typ = structure "ManifoldExportOptions"
  end

  module ManifoldPair = struct
    type t = [ `ManifoldPair ] structure

    let t : t typ = structure "ManifoldManifoldPair"
    let first = field t "first" (ptr Manifold.t)
    let second = field t "second" (ptr Manifold.t)
    let () = seal t
  end

  module Vec2 = struct
    type t = [ `Vec2 ] structure

    let t : t typ = structure "ManifoldVec2"
    let x = field t "x" float
    let y = field t "y" float
    let () = seal t
  end

  module Vec3 = struct
    type t = [ `Vec3 ] structure

    let t : t typ = structure "ManifoldVec3"
    let x = field t "x" float
    let y = field t "y" float
    let z = field t "z" float
    let () = seal t
  end

  module IVec3 = struct
    type t = [ `IVec3 ] structure

    let t : t typ = structure "ManifoldIVec3"
    let x = field t "x" int
    let y = field t "y" int
    let z = field t "z" int
    let () = seal t
  end

  module Vec4 = struct
    type t = [ `Vec4 ] structure

    let t : t typ = structure "ManifoldVec4"
    let x = field t "x" float
    let y = field t "y" float
    let z = field t "z" float
    let w = field t "w" float
    let () = seal t
  end

  module PolyVert = struct
    type t = [ `PolyVert ] structure

    let t : t typ = structure "ManifoldPolyVert"
    let pos = field t "pos" Vec2.t
    let idx = field t "idx" int
    let () = seal t
  end

  module BaryRef = struct
    type t = [ `BaryRef ] structure

    let t : t typ = structure "ManifoldBaryRef"
    let mesh_id = field t "mesh_id" int
    let original_id = field t "original_id" int
    let tri = field t "tri" int
    let vert_bary = field t "vert_bary" IVec3.t
    let () = seal t
  end

  module CurvatureBounds = struct
    type t = [ `CurvatureBounds ] structure

    let t : t typ = structure "ManifoldCurvatureBounds"
    let max_mean_curvature = field t "max_mean_curvature" float
    let min_mean_curvature = field t "min_mean_curvature" float
    let max_gaussian_curvature = field t "max_gaussian_curvature" float
    let min_gaussian_curvature = field t "min_gaussian_curvature" float
    let () = seal t
  end
end
