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

-- use barycentric coords
-- see page 157 of shirley's book for the math
intersect (Ray o@(Vector3 ox oy oz) d@(Vector3 g h i)) tMin tMax
    (Triangle material (Vector3 x1 y1 z1) (Vector3 x2 y2 z2) (Vector3 x3 y3 z3)
                        n1 n2 n3) =
    if t < tMin || t > tMax || bigB < (-0.0001) || bigB > 1.0001 ||
       bigG < (-0.0001) || bigG > (1.0001-bigB)
    then Nothing
    else Just fakehit
    where
        t = -1*((f*(a*k-j*b) + e*(j*c-a*l) + d*(b*l-k*c))/bigM)
        a = x1 - x2
        b = y1 - y2
        c = z1 - z2
        d = x1 - x3
        e = y1 - y3
        f = z1 - z3
        j = x1 - ox
        k = y1 - oy
        l = z1 - oz
        ei_hf = e*i - h*f
        gf_di = g*f - d*i
        dh_eg = d*h - e*g
        bigM = a*ei_hf + b*gf_di + c*dh_eg
        bigB = (j*ei_hf + k*gf_di + l*dh_eg)/bigM
        bigG = (i*(a*k-j*b) + h*(j*c-a*l) + g*(b*l-k*c))/bigM
