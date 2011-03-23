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
--    Light 90 (PointLight (Vector3 3 4 0)) (Vector3 1 1 1)
    Light 120 (RectLight (Vector3 1.5 5.99 (-1.5)) (xaxis >* 3) (zaxis >* 3)) (Vector3 1 1 1)
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

shadowRay :: Vertex -> Vertex -> Double
shadowRay p lightpos =  case sceneIntersect 0.001 1.0 (Ray p $ lightpos >- p) of
                                            Just _ -> 0.0
                                            Nothing -> 1.0

-- TODO: lightcolor
sceneShadeLight :: Int -> HitInfo -> Light -> RGBColor
sceneShadeLight depth (HitInfo dist p n (Material rgbcolor specular))
                light@(Light wattage lightshape lightcolor) =
    (rgbcolor >* diffuseTotal) >+ specularColor
    where
        diffuseTotal = foldr (+) 0.0 $ map diffuse lightSamples
        diffuse lightpos = let toLight = (lightpos >- p) in (lightPower lightpos) * (shadowRay p lightpos) * (max 0.0 $ n >. toLight) / mag toLight
        lightPower lightpos = (fromIntegral wattage) / (4 * pi * (mag2 (lightpos >- p)) * numLightSamples)
        specularColor = if specular > 0.01 then (specularRay (Ray p n)) >* specular else v3zero
        specularRay r = sceneShade (depth+1) $ sceneIntersect 0.001 10000 r
        lightSamples = lightSample lightshape strata
        numLightSamples = fromIntegral $ length lightSamples
        strata = 10
