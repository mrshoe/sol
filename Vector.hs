module Vector where
data Vector3 = Vector3 { x :: Double, y :: Double, z :: Double } deriving Show

(>*) :: Vector3 -> Double -> Vector3
(>*) v i = Vector3 ((x v) * i) ((y v) * i) ((z v) * i)

(>+) :: Vector3 -> Vector3 -> Vector3
(>+) a b = Vector3 (add_comp x) (add_comp y) (add_comp z)
	where add_comp c = (c a) + (c b)

(>-) :: Vector3 -> Vector3 -> Vector3
(>-) a b = Vector3 (sub_comp x) (sub_comp y) (sub_comp z)
	where sub_comp c = (c a) - (c b)

(>.) :: Vector3 -> Vector3 -> Double
(>.) a b = (mul_comp x) + (mul_comp y) + (mul_comp z)
	where mul_comp c = (c a) * (c b)

(><) :: Vector3 -> Vector3 -> Vector3
(><) a b = Vector3 ((y a) * (z b) - (z a) * (y b)) ((z a) * (x b) - (x a) * (z b)) ((x a) * (y b) - (y a) * (x b))

mag2 :: Vector3 -> Double
mag2 v = (x v)*(x v) + (y v)*(y v) + (z v)*(z v)

mag :: Vector3 -> Double
mag = sqrt . mag2

neg :: Vector3 -> Vector3
neg v = Vector3 (-(x v)) (-(y v)) (-(z v))

norm :: Vector3 -> Vector3
norm v = let inv_mag = 1.0/mag v in
				Vector3 ((x v)*inv_mag) ((y v)*inv_mag) ((z v)*inv_mag)

dist2 :: Vector3 -> Vector3 -> Double
dist2 a b = mag2 $ b >- a

dist :: Vector3 -> Vector3 -> Double
dist a = sqrt . dist2 a

-- some handy vectors
v3zero = Vector3 0 0 0
xaxis = Vector3 1 0 0
yaxis = Vector3 0 1 0
zaxis = Vector3 0 0 1
