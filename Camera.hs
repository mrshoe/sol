module Camera where
import Graphics.Rendering.OpenGL (GLint)
import Vector
import Ray

--                   eye    dir   width height    u       v       w       b       t
data Camera = Camera Vertex Vector3 Int Int Vector3 Vector3 Vector3 Vector3 Vector3 deriving Show

initCamera :: Vertex -> Vector3 -> Int -> Int -> Camera
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
eyeRay (Camera eye _ width height u v w b@(Vector3 bx by bz) t@(Vector3 tx ty tz)) xpos ypos = Ray o d
    where
        o = eye
        d = norm $ uprime >+ vprime >+ wprime
        dirx = bx + (tx - bx) * ((fromIntegral xpos + 0.5) / (fromIntegral width))
        diry = by + (ty - by) * ((fromIntegral ypos + 0.5) / (fromIntegral height))
        uprime = u >* dirx
        vprime = v >* diry
        wprime = w >* bz

cameraMove :: Camera -> Vertex -> Camera
cameraMove (Camera eye dir width height _ _ _ _ _) neweye =
    initCamera neweye dir width height

cameraForward :: Camera -> Camera
cameraForward cam@(Camera eye dir _ _ _ _ _ _ _) = cameraMove cam $ eye >+ (dir >* 0.2)

cameraBack :: Camera -> Camera
cameraBack cam@(Camera eye dir _ _ _ _ _ _ _) = cameraMove cam $ eye >- (dir >* 0.2)

cameraRight :: Camera -> Camera
cameraRight cam@(Camera eye dir _ _ _ _ _ _ _) = cameraMove cam $ eye >+ ((dir >< yaxis) >* 0.2)

cameraLeft :: Camera -> Camera
cameraLeft cam@(Camera eye dir _ _ _ _ _ _ _) = cameraMove cam $ eye >+ ((yaxis >< dir) >* 0.2)

cameraProcessKeys :: (Bool, Bool, Bool, Bool) -> Camera -> Camera
cameraProcessKeys (fwd, back, left, right) = 
    foldr (.) id $ map snd $ filter fst $ zip [fwd, back, left, right] [cameraForward, cameraBack, cameraLeft, cameraRight]

-- a gross approximation :-P
cameraMouseLook :: (GLint, GLint) -> Camera -> Camera
cameraMouseLook (dx, dy) (Camera eye dir width height _ _ _ _ _) = initCamera eye newdir width height
    where newdir = norm $ dir >+ ((dir >< yaxis) >* ((fromIntegral dx)/500)) >+ (yaxis >* (-(fromIntegral dy)/500))
