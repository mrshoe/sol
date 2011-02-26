module Scene where
import Vector
import Ray

sceneIntersect :: Ray -> Bool
sceneIntersect ray = d ray >. xaxis < cos (pi/8)
