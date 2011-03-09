import Foreign
import Graphics.Rendering.OpenGL hiding (Vector3)
import Graphics.UI.GLUT hiding (Vector3)
import Maybe
import Vector
import Scene
import Camera
import Primitives

myPoints :: [(GLfloat, GLfloat, GLfloat)]
myPoints = map (\k -> (sin(2*pi*k/12), cos(2*pi*k/12), 0.0)) [1..12]

screenWidth = 800 :: Int
screenHeight = 800 :: Int

screenWidthf = fromIntegral screenWidth :: GLfloat
screenHeightf = fromIntegral screenHeight :: GLfloat

pixels :: [(Int, Int)]
pixels = [(x, y) | x <- [1..(screenWidth-1)], y <- [1..(screenHeight-1)]]

openGLInit :: IO ()
openGLInit = do
    createWindow "Hello World"
    displayCallback $= display
    viewport $= (Position 0 0, Size 800 800)
    loadIdentity
    ortho2D 0 1 0 1
    shadeModel $= Flat
    lighting $= Disabled
    combineRGB $= Replace'
    [texName] <- genObjectNames 1
    textureBinding Texture2D $= Just texName
    textureFilter Texture2D $= ((Nearest, Nothing), Nearest)
    pxFloats <- mallocArray (screenWidth*screenHeight*3) :: IO (Ptr Float)
    texImage2D Nothing NoProxy 0 RGB' (TextureSize2D 800 800) 0 (PixelData RGB Float pxFloats)
    free pxFloats
    texture Texture2D $= Enabled
    textureFunction $= Replace

setColor :: Ptr Float -> (Int, Int) -> RGBColor -> IO ()
setColor pxFloats (x, y) (Vector3 r g b) = let fidx = (y*800+x)*3 in do
    pokeElemOff pxFloats fidx (realToFrac r)
    pokeElemOff pxFloats (fidx+1) (realToFrac g)
    pokeElemOff pxFloats (fidx+2) (realToFrac b)

display =
    let cam = initCamera (Vector3 (0.5) 0 0) xaxis screenWidth screenHeight in
    do
        clear [ColorBuffer]
        pxFloats <- mallocArray (800*800*3) :: IO (Ptr Float)
        mapM_ (\(x, y) -> setColor pxFloats (x,y) (sceneShade $ sceneIntersect $ eyeRay cam x y)) pixels
        texSubImage2D Nothing 0 (TexturePosition2D 0 0) (TextureSize2D 800 800) (PixelData RGB Float pxFloats)
        free pxFloats
        renderPrimitive Quads $ do
            texCoord $ TexCoord2 (0::GLfloat) (0::GLfloat)
            vertex $ Vertex2 (0::GLfloat) (0::GLfloat)
            texCoord $ TexCoord2 (0::GLfloat) (1::GLfloat)
            vertex $ Vertex2 (0::GLfloat) (1::GLfloat)
            texCoord $ TexCoord2 (1::GLfloat) (1::GLfloat)
            vertex $ Vertex2 (1::GLfloat) (1::GLfloat)
            texCoord $ TexCoord2 (1::GLfloat) (0::GLfloat)
            vertex $ Vertex2 (1::GLfloat) (0::GLfloat)
        flush

main = do
    (progname, _) <- getArgsAndInitialize
    openGLInit
    mainLoop
