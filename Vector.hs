module Vector where
data Vector3 = Vector3 Double Double Double deriving Show
type Vertex = Vector3
type Normal = Vector3
type RGBColor = Vector3

(>*) :: Vector3 -> Double -> Vector3
(>*) (Vector3 x y z) i = Vector3 (x * i) (y * i) (z * i)

(>+) :: Vector3 -> Vector3 -> Vector3
(>+) (Vector3 x1 y1 z1) (Vector3 x2 y2 z2) = Vector3 (x1+x2) (y1+y2) (z1+z2)

(>-) :: Vector3 -> Vector3 -> Vector3
(>-) (Vector3 x1 y1 z1) (Vector3 x2 y2 z2) = Vector3 (x1-x2) (y1-y2) (z1-z2)

(>.) :: Vector3 -> Vector3 -> Double
(>.) (Vector3 x1 y1 z1) (Vector3 x2 y2 z2) = (x1*x2) + (y1*y2) + (z1*z2)

(><) :: Vector3 -> Vector3 -> Vector3
(><) (Vector3 x1 y1 z1) (Vector3 x2 y2 z2) = Vector3 (y1*z2 - z1*y2) (z1*x2 - x1*z2) (x1*y2 - y1*x2)

mag2 :: Vector3 -> Double
mag2 (Vector3 x y z) = x*x + y*y + z*z

mag :: Vector3 -> Double
mag = sqrt . mag2

neg :: Vector3 -> Vector3
neg (Vector3 x y z) = Vector3 (-x) (-y) (-z)

norm :: Vector3 -> Vector3
norm v@(Vector3 x y z) = let inv_mag = 1.0/mag v in Vector3 (x*inv_mag) (y*inv_mag) (z*inv_mag)

dist2 :: Vector3 -> Vector3 -> Double
dist2 a b = mag2 $ b >- a

dist :: Vector3 -> Vector3 -> Double
dist a = sqrt . dist2 a

-- some handy vectors
v3zero = Vector3 0 0 0
xaxis = Vector3 1 0 0
yaxis = Vector3 0 1 0
zaxis = Vector3 0 0 1
