module Ray where
import Vector

data Ray = Ray { o :: Vector3, d :: Vector3 } deriving Show
