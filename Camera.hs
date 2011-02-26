module Camera where
import Vector
import Ray

data Camera = Camera {
	eye :: Vector3,
	dir :: Vector3,
	width :: Int,
	height :: Int,
	u :: Vector3,
	v :: Vector3,
	w :: Vector3,
	b :: Vector3,
	t :: Vector3
} deriving Show

initCamera :: Vector3 -> Vector3 -> Int -> Int -> Camera
initCamera eye dir width height = Camera eye dir width height u v w b t
	where
		t = Vector3 tx ty (bz + 1)
		b = Vector3 (-tx) (-ty) bz
		w = norm dir
		u = yaxis >< w
		v = w >< u
		tx = aspect * ty
		ty = bz * tan fov
		bz = 0.0001
		fov = pi * (45/360)
		aspect = (fromIntegral width) / (fromIntegral height)
	
eyeRay :: Camera -> Int -> Int -> Ray
eyeRay cam xpos ypos = Ray o d
	where
		o = eye cam
		d = norm $ uprime >+ vprime >+ wprime
		dirx = (x $ b cam) + (((x $ t cam) - (x $ b cam)) * ((fromIntegral xpos + 0.5) / camw))
		diry = (y $ b cam) + (((y $ t cam) - (y $ b cam)) * ((fromIntegral ypos + 0.5) / camh))
		camw = fromIntegral $ width cam
		camh = fromIntegral $ height cam
		dirz = z $ b cam
		uprime = u cam >* dirx
		vprime = v cam >* diry
		wprime = w cam >* dirz
