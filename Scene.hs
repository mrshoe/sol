module Scene where

import Maybe
import Vector
import Camera
import Ray
import Primitives

sceneObjects = map (\x -> Sphere "black" (Vector3 x 0 0) 0.5) [2..10] ++ [Triangle "black" (Vector3 8 0.6 (-0.5)) (Vector3 8 0.6 0.5) (Vector3 8 1 0) xaxis xaxis xaxis]

sceneLights = [PointLight 750 (Vector3 5 10 0) (Vector3 1 1 1)
              ]

minHit :: [Maybe HitInfo] -> Maybe HitInfo
minHit = foldr isCloser Nothing

isCloser :: Maybe HitInfo -> Maybe HitInfo -> Maybe HitInfo
isCloser old Nothing = old
isCloser Nothing new = new
isCloser old@(Just (HitInfo d1 _ _ _)) new@(Just (HitInfo d2 _ _ _)) = if d1 < d2 then old else new

sceneIntersect :: Ray -> Maybe HitInfo
sceneIntersect ray = minHit $ map (intersect ray 0 10000) sceneObjects

sceneShade :: Maybe HitInfo -> RGBColor
sceneShade Nothing = Vector3 0 0 0
sceneShade (Just hitinfo) = foldr (>+) (Vector3 0 0 0) $ map (sceneShadeLight hitinfo) sceneLights

-- TODO: lightcolor
sceneShadeLight :: HitInfo -> Light -> RGBColor
sceneShadeLight (HitInfo dist p n (Material rgbcolor))
                (PointLight wattage lightpos lightcolor) = rgbcolor >* (diffuse / lightFalloff)
    where
        diffuse = n >. (norm toLight) -- for now (should come from the material)
        toLight = lightpos >- p
        lightFalloff = (4 * pi * lightDistSq) / (fromIntegral wattage)
        lightDistSq = mag2 toLight
