import Graphics.Rendering.OpenGL
import Graphics.UI.GLUT
import Vector
import Scene
import Camera

myPoints :: [(GLfloat, GLfloat, GLfloat)]
myPoints = map (\k -> (sin(2*pi*k/12), cos(2*pi*k/12), 0.0)) [1..12]

screenWidth = 800 :: Int
screenHeight = 800 :: Int

screenWidthf = fromIntegral screenWidth :: GLfloat
screenHeightf = fromIntegral screenHeight :: GLfloat

pixels :: [(Int, Int)]
pixels = [(x, y) | x <- [1..screenWidth], y <- [1..screenHeight]]

main = do
	(progname, _) <- getArgsAndInitialize
	createWindow "Hello World"
	displayCallback $= display
	viewport $= (Position 0 0, Size 800 800)
	loadIdentity
	ortho2D 0 1 0 1
	mainLoop

display =
	let cam = initCamera v3zero xaxis screenWidth screenHeight in
	do
		clear [ColorBuffer]
		renderPrimitive Points $ mapM_ (\(x,y) -> vertex $ Vertex2 ((fromIntegral x)/screenWidthf) ((fromIntegral y)/screenHeightf)) (filter (\(px,py) -> sceneIntersect $ eyeRay cam px py) pixels)
		flush
