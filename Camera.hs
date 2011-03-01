module Camera where
import Vector
import Ray

--                   eye    dir   width height    u       v       w       b       t
data Camera = Camera Vertex Vector3 Int Int Vector3 Vector3 Vector3 Vector3 Vector3 deriving Show

initCamera :: Vertex -> Vector3 -> Int -> Int -> Camera
initCamera eye lookAt width height = Camera eye dir width height u v w b t
    where
        dir = norm $ lookAt >- eye
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
eyeRay (Camera eye _ width height u v w b@(Vector3 bx by bz) t@(Vector3 tx ty tz)) xpos ypos = Ray o d
    where
        o = eye
        d = norm $ uprime >+ vprime >+ wprime
        dirx = bx + (tx - bx) * ((fromIntegral xpos + 0.5) / (fromIntegral width))
        diry = by + (ty - by) * ((fromIntegral ypos + 0.5) / (fromIntegral height))
        uprime = u >* dirx
        vprime = v >* diry
        wprime = w >* bz
