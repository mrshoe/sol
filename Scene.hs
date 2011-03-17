module Scene where

import Maybe
import Vector
import Camera
import Ray
import Primitives

--sceneObjects = map (\x -> Sphere "black" (Vector3 x 0 0) 0.5) [2..10] ++ [Triangle "black" (Vector3 8 0.6 (-0.5)) (Vector3 8 0.6 0.5) (Vector3 8 1 0) xaxis xaxis xaxis]
sceneObjects = [
    (Sphere "mirror" (Vector3 4 1 (-1.5)) 1),
    (Sphere "green" (Vector3 2 1 1.5) 1),
    (Triangle "red" (Vector3 0 0 (-3)) (Vector3 6 0 (-3)) (Vector3 0 6 (-3)) zaxis zaxis zaxis), -- side
    (Triangle "red" (Vector3 6 6 (-3)) (Vector3 6 0 (-3)) (Vector3 0 6 (-3)) zaxis zaxis zaxis),
    (Triangle "blue" (Vector3 0 0 3) (Vector3 6 0 3) (Vector3 0 6 3) (Vector3 0 0 (-1)) (Vector3 0 0 (-1)) (Vector3 0 0 (-1))), -- side
    (Triangle "blue" (Vector3 6 6 3) (Vector3 6 0 3) (Vector3 0 6 3) (Vector3 0 0 (-1)) (Vector3 0 0 (-1)) (Vector3 0 0 (-1))),
    (Triangle "white" (Vector3 0 0 (-3)) (Vector3 0 0 3) (Vector3 6 0 3) yaxis yaxis yaxis), -- floor
    (Triangle "white" (Vector3 0 0 (-3)) (Vector3 6 0 (-3)) (Vector3 6 0 3) yaxis yaxis yaxis),
    (Triangle "white" (Vector3 0 6 (-3)) (Vector3 0 6 3) (Vector3 6 6 3) (Vector3 0 (-1) 0) (Vector3 0 (-1) 0) (Vector3 0 (-1) 0)), -- ceiling
    (Triangle "white" (Vector3 0 6 (-3)) (Vector3 6 6 (-3)) (Vector3 6 6 3) (Vector3 0 (-1) 0) (Vector3 0 (-1) 0) (Vector3 0 (-1) 0)),
    (Triangle "white" (Vector3 6 0 (-3)) (Vector3 6 0 3) (Vector3 6 6 3) (Vector3 (-1) 0 0) (Vector3 (-1) 0 0) (Vector3 (-1) 0 0)), -- back
    (Triangle "white" (Vector3 6 0 (-3)) (Vector3 6 6 (-3)) (Vector3 6 6 3) (Vector3 (-1) 0 0) (Vector3 (-1) 0 0) (Vector3 (-1) 0 0))
    ]

sceneLights = [
--    PointLight 60 (Vector3 (-1) 4 0) (Vector3 1 1 1),
    PointLight 90 (Vector3 3 4 0) (Vector3 1 1 1)
    ]

minHit :: [Maybe HitInfo] -> Maybe HitInfo
minHit = foldr isCloser Nothing

isCloser :: Maybe HitInfo -> Maybe HitInfo -> Maybe HitInfo
isCloser old Nothing = old
isCloser Nothing new = new
isCloser old@(Just (HitInfo d1 _ _ _)) new@(Just (HitInfo d2 _ _ _)) = if d1 < d2 then old else new

sceneIntersect :: Double -> Double -> Ray -> Maybe HitInfo
sceneIntersect tMin tMax ray = minHit $ map (intersect ray tMin tMax) sceneObjects

sceneShade :: Int -> Maybe HitInfo -> RGBColor
sceneShade _ Nothing = v3zero
sceneShade depth (Just hitinfo)
    | depth < 4 = foldr (>+) v3zero $ map (sceneShadeLight depth hitinfo) sceneLights
    | otherwise = v3zero

-- TODO: lightcolor
sceneShadeLight :: Int -> HitInfo -> Light -> RGBColor
sceneShadeLight depth (HitInfo dist p n (Material rgbcolor specular))
                light@(PointLight wattage lightpos lightcolor) =
    (rgbcolor >* (diffuse / lightFalloff)) >+ specularColor
    where
        diffuse = if shadowRay then 0 else max 0.0 $ n >. (norm toLight)
        toLight = lightpos >- p
        lightFalloff = (4 * pi * lightDistSq) / (fromIntegral wattage)
        lightDistSq = mag2 toLight
        shadowRay = isJust $ sceneIntersect 0.001 (sqrt lightDistSq) (Ray p (norm toLight))
        specularColor = if specular > 0.01 then (specularRay (Ray p n)) >* specular else v3zero
        specularRay r = sceneShade (depth+1) $ sceneIntersect 0.001 10000 r
