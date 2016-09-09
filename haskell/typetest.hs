module TypeTest where

data BoundingBox = BoundingBox Int Int Int Int deriving Show

data Foo = Bar

class SceneObject a where
    intersect :: a -> String
    intersect _ = "hit an object"

    boundingBox :: a -> BoundingBox
    boundingBox _ = BoundingBox 0 0 0 0

data Sphere = Sphere
data Triangle = Triangle
data Box = Box

instance SceneObject Sphere where
    intersect _ = "hit a sphere"
    boundingBox _ = BoundingBox 1 2 3 4

instance SceneObject Triangle where
    intersect _ = "hit a triangle"
    boundingBox _ = BoundingBox 5 6 7 8

instance SceneObject Box where
    intersect _ = "hit a box"
    boundingBox _ = BoundingBox 2 4 6 8

data ScenePrimitive = SceneTriangle Triangle | SceneSphere Sphere | SceneBox Box

instance SceneObject ScenePrimitive where
    intersect (SceneTriangle o) = intersect o
    intersect (SceneSphere o) = intersect o
    intersect (SceneBox o) = intersect o
    boundingBox (SceneTriangle o) = boundingBox o
    boundingBox (SceneSphere o) = boundingBox o
    boundingBox (SceneBox o) = boundingBox o

sceneobjects = [SceneTriangle Triangle, SceneSphere Sphere, SceneBox Box, SceneTriangle Triangle]

boundingboxes = map boundingBox sceneobjects
hits = map intersect sceneobjects
