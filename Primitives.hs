module Primitives where

import Maybe
import Vector
import Ray

data Color = Color Double Double Double deriving Show

data Material = Material Color deriving Show
type MaterialName = String

data HitInfo = HitInfo Double Vertex Normal Material deriving Show

data Primitive =
    Sphere MaterialName Vertex Double
  | Triangle MaterialName Vertex Vertex Vertex Normal Normal Normal
    deriving Show

fakehit = HitInfo 0 (Vector3 0 0 0) (Vector3 0 0 0) (Material (Color 0 0 0))

intersect :: Ray -> Double -> Double -> Primitive -> Maybe HitInfo
intersect (Ray o d) tMin tMax (Sphere material center radius) =
    if discriminant < 0 || t < tMin || t > tMax then Nothing else Just fakehit
    where
        discriminant = bsquared - fourAC
        bsquared = let b = d >. toCenter in b * b
        fourAC = dd * ((mag2 toCenter) - (radius*radius))
        dd = mag2 d
        toCenter = o >- center
        t = (tmpt + rootshift) / dd
        tmpt = (-(d >. toCenter))
        rootshift = if root > tmpt then root else (-root)
        root = sqrt discriminant
