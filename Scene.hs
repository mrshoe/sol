module Scene where

import Maybe
import Vector
import Ray
import Primitives

sceneObjects = [Sphere "black" (Vector3 3 0 0) 0.5]

minHit :: [Maybe HitInfo] -> Maybe HitInfo
minHit = foldr isCloser Nothing

isCloser :: Maybe HitInfo -> Maybe HitInfo -> Maybe HitInfo
isCloser old Nothing = old
isCloser Nothing new = new
isCloser old@(Just (HitInfo d1 _ _ _)) new@(Just (HitInfo d2 _ _ _)) = if d1 < d2 then old else new

sceneIntersect :: Ray -> Maybe HitInfo
sceneIntersect ray = minHit $ map (intersect ray 0 10000) sceneObjects
