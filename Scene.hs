module Scene where

import Maybe
import Vector
import Camera
import Ray
import Primitives

sceneObjects = [Sphere "black" (Vector3 3 0 0) 0.5
               ,Triangle "black" (Vector3 3 0.6 (-0.5)) (Vector3 3 0.6 0.5) (Vector3 3 1 0) xaxis xaxis xaxis
               ]

minHit :: [Maybe HitInfo] -> Maybe HitInfo
minHit = foldr isCloser Nothing

isCloser :: Maybe HitInfo -> Maybe HitInfo -> Maybe HitInfo
isCloser old Nothing = old
isCloser Nothing new = new
isCloser old@(Just (HitInfo d1 _ _ _)) new@(Just (HitInfo d2 _ _ _)) = if d1 < d2 then old else new

sceneIntersect :: Ray -> Maybe HitInfo
sceneIntersect ray = minHit $ map (intersect ray 0 10000) sceneObjects

--sceneChuck :: Camera -> Rect -> [Color]
--sceneChuck cam (Rect x y width height) = map sintersect [(px,py) | x <- [x..(x+width-1)] , y <- [y..(y+height-1)]]
--    where
--        sintersect (px, py) = case (sceneIntersect $ eyeRay cam px py) of Nothing -> Color 0 0 0
--                                    Just _ -> Color 1 1 1
