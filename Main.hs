import Control.Concurrent
import Foreign
import Graphics.Rendering.OpenGL hiding (Vector3)
import Graphics.UI.GLUT hiding (Vector3)
import Maybe
import Vector
import Scene
import Camera
import Primitives

screenWidth = 512 :: Int
screenHeight = 512 :: Int

screenWidthf = fromIntegral screenWidth :: GLfloat
screenHeightf = fromIntegral screenHeight :: GLfloat

openGLInit :: IO ()
openGLInit =
    do
    createWindow "Hello World"
    windowSize $= (Size 512 512)
    viewport $= (Position 0 0, Size 512 512)
    displayCallback $= display
    finishedChunk <- newEmptyMVar
    idleCallback $= Just (idle finishedChunk)
    loadIdentity
    ortho2D 0 1 0 1
    shadeModel $= Flat
    lighting $= Disabled
    combineRGB $= Replace'
    texture Texture2D $= Enabled
    textureFunction $= Replace
    [texName] <- genObjectNames 1
    textureBinding Texture2D $= Just texName
    textureFilter Texture2D $= ((Nearest, Nothing), Nearest)
    pxFloats <- mallocArray (screenWidth*screenHeight*3) :: IO (Ptr Float)
    texImage2D Nothing NoProxy 0 RGB' (TextureSize2D 512 512) 0 (PixelData RGB Float pxFloats)
    mapM_ (\(x, y, width, height) -> forkIO (doChunk finishedChunk cam x y width height)) chunks
    free pxFloats
    where
        cam = initCamera (Vector3 (-5) 6 0) (Vector3 3 0 0) screenWidth screenHeight
        chunks = [(x*chunksize, y*chunksize, chunksize, chunksize) | x <- [0..(chunksPerSide-1)], y <- [0..(chunksPerSide-1)]]
        chunksize = 64
        chunksPerSide = 8

setColor :: Ptr Float -> Int -> RGBColor -> IO ()
setColor pxFloats idx (Vector3 r g b) = let fidx = idx*3 in do
    pokeElemOff pxFloats fidx (realToFrac r)
    pokeElemOff pxFloats (fidx+1) (realToFrac g)
    pokeElemOff pxFloats (fidx+2) (realToFrac b)

doChunk finishedChunk cam startx starty width height =
    let pixels = [(x, y) | y <- [starty..(starty+height-1)], x <- [startx..(startx+width-1)]] in
    do
        pxFloats <- mallocArray (width*height*3) :: IO (Ptr Float)
        mapM_ (\(idx, (x, y)) -> setColor pxFloats idx (sceneShade $ sceneIntersect $ eyeRay cam x y)) $ zip [0..] pixels
        putMVar finishedChunk (startx, starty, width, height, pxFloats)

display =
    do
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

idle finishedChunk =
    do
        (startx, starty, width, height, pxFloats) <- takeMVar finishedChunk
        texSubImage2D Nothing 0 (TexturePosition2D (fromIntegral startx) (fromIntegral starty)) (TextureSize2D (fromIntegral width) (fromIntegral height)) (PixelData RGB Float pxFloats)
        free pxFloats
        postRedisplay Nothing

main = do
    (progname, _) <- getArgsAndInitialize
    openGLInit
    mainLoop
