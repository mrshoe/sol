module Primitives where

import Maybe
import Vector
import Ray
import qualified Data.Map as M

data Material = Material RGBColor Double deriving Show
type MaterialName = String

sceneMaterials = M.fromList [
	("red", Material (Vector3 1 0.3 0.3) 0.0),
	("blue", Material (Vector3 0.3 0.3 1) 0.0),
	("green", Material (Vector3 0 1 0) 0.0),
	("white", Material (Vector3 1 1 1) 0.0),
	("mirror", Material (Vector3 0.2 0.2 0.2) 1.0)
    ]
defaultMaterial = Material (Vector3 1 1 1) 0.0

lookupMaterial :: MaterialName -> Material
lookupMaterial name = case M.lookup name sceneMaterials of
                        Just m -> m
                        Nothing -> defaultMaterial

data HitInfo = HitInfo Double Vertex Normal Material deriving Show

-- offset x,y, width, height
data Rect = Rect Double Double Double Double

data Primitive =
    Sphere MaterialName Vertex Double
  | Triangle MaterialName Vertex Vertex Vertex Normal Normal Normal
    deriving Show

data Light =
    PointLight Int Vertex RGBColor
    deriving Show

intersect :: Ray -> Double -> Double -> Primitive -> Maybe HitInfo
intersect (Ray o d) tMin tMax (Sphere material center radius) =
    if discriminant < 0 || t < tMin || t > tMax then Nothing else Just thehit
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
        thehit = HitInfo t p n $ lookupMaterial material
        p = o >+ (d >* t)
        n = norm $ p >- center

-- use barycentric coords
-- see page 157 of shirley's book for the math
intersect (Ray ro@(Vector3 ox oy oz) rd@(Vector3 g h i)) tMin tMax
    (Triangle material (Vector3 x1 y1 z1) (Vector3 x2 y2 z2) (Vector3 x3 y3 z3)
                        n1 n2 n3) =
    if t < tMin || t > tMax || bigB < (-0.0001) || bigB > 1.0001 ||
       bigG < (-0.0001) || bigG > (1.0001-bigB)
    then Nothing
    else Just thehit
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
        thehit = HitInfo t p n $ lookupMaterial material
        p = ro >+ (rd >* t)
        n = n1 -- TODO
