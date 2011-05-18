import Data.Time.Clock
import Data.IORef
import Control.Concurrent
import Control.Monad
import System.IO
import Foreign
import Graphics.Rendering.OpenGL hiding (Vector3)
import Graphics.UI.GLUT hiding (Vector3)
--import Maybe
import Vector
import Scene
import Camera
import Primitives

imgWidth = 512 :: Int
imgHeight = 512 :: Int

imgWidth32 = (fromIntegral imgWidth) :: Int32
imgHeight32 = (fromIntegral imgHeight) :: Int32

antialiasing = 3 :: Double

openGLInit :: IO ()
openGLInit =
    do
    createWindow "sol"
    windowSize $= (Size imgWidth32 imgHeight32)
    viewport $= (Position 0 0, Size imgWidth32 imgHeight32)
    displayCallback $= display
    chunkMVars <- replicateM (chunksPerSide*chunksPerSide) newEmptyMVar
    camMVars <- replicateM (chunksPerSide*chunksPerSide) newEmptyMVar
    keyRef <- newIORef (False, False, False, False)
    mouseRef <- newIORef (0, 0, 0, 0)
    idleCallback $= Just (idle cam chunkMVars camMVars keyRef mouseRef 0 0)
    keyboardMouseCallback $= Just (keyboardMouse keyRef mouseRef)
    motionCallback $= Just (mouseMotion mouseRef)
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
    pxFloats <- mallocArray (imgWidth*imgHeight*3) :: IO (Ptr Float)
    texImage2D Nothing NoProxy 0 RGB' (TextureSize2D imgWidth32 imgHeight32) 0 (PixelData RGB Float pxFloats)
    free pxFloats
    mapM_ (\(chunkMVar, camMVar, (x, y, width, height)) -> forkIO (doChunk chunkMVar camMVar x y width height)) $ zip3 chunkMVars camMVars chunks
    where
        cam = initCamera (Vector3 (-7.25) 3 0) (Vector3 1 0 0) imgWidth imgHeight
        chunks = [(x*chunksize, y*chunksize, chunksize, chunksize) | x <- [0..(chunksPerSide-1)], y <- [0..(chunksPerSide-1)]]
        chunksize = 128
        chunksPerSide = 4

setColor :: Ptr Float -> Int -> RGBColor -> IO ()
setColor pxFloats idx (Vector3 r g b) = let fidx = idx*3 in do
    pokeElemOff pxFloats fidx (realToFrac r)
    pokeElemOff pxFloats (fidx+1) (realToFrac g)
    pokeElemOff pxFloats (fidx+2) (realToFrac b)

getColor :: Camera -> Int -> Int -> RGBColor
getColor cam x y = avgColor $ map doEyeRay eyePoints
    where
        doEyeRay (ex,ey) = sceneShade 0 $ sceneIntersect 0 10000 $ eyeRay cam ex ey
        eyePoints = [((fromIntegral x)+(i*antialias_step), (fromIntegral y)+(j*antialias_step)) | i <- [0..(antialiasing-1)], j <- [0..(antialiasing-1)]]
        avgColor colors = (foldr (>+) v3zero colors) >* (1/(fromIntegral $ length colors))
        antialias_step = (1/antialiasing)

doChunk chunkMVar camMVar startx starty width height =
    let pixels = [(x, y) | y <- [starty..(starty+height-1)], x <- [startx..(startx+width-1)]] in
    forever $ do
        cam <- takeMVar camMVar
        pxFloats <- mallocArray (width*height*3) :: IO (Ptr Float)
        mapM_ (\(idx, (x, y)) -> setColor pxFloats idx (getColor cam x y)) $ zip [0..] pixels
        putMVar chunkMVar (startx, starty, width, height, pxFloats)

idle cam chunkMVars camMVars keyRef mouseRef nextSample numFrames =
    do
        mapM_ (\v -> putMVar v cam) camMVars -- pass the current camera to each worker thread
        mapM_ drawChunk chunkMVars
        keys <- readIORef keyRef -- fetch the key state to modify the camera for the next frame
        (mousex, mousey, mousedx, mousedy) <- readIORef mouseRef
        writeIORef mouseRef (mousex, mousey, 0, 0)
        endTime <- getCurrentTime
        if (utctDayTime endTime) > nextSample then do
            putStr $ "\r" ++ (show numFrames) ++ "fps          "
            hFlush stdout
            idleCallback $= Just (idle (cameraMouseLook (mousedx, mousedy) (cameraProcessKeys keys cam)) chunkMVars camMVars keyRef mouseRef ((utctDayTime endTime) + 1) 0)
        else do
            idleCallback $= Just (idle (cameraMouseLook (mousedx, mousedy) (cameraProcessKeys keys cam)) chunkMVars camMVars keyRef mouseRef nextSample (numFrames + 1))
        postRedisplay Nothing
    where
        drawChunk chunkMVar = do
            (startx, starty, width, height, pxFloats) <- takeMVar chunkMVar
            texSubImage2D Nothing 0 (TexturePosition2D (fromIntegral startx) (fromIntegral starty)) (TextureSize2D (fromIntegral width) (fromIntegral height)) (PixelData RGB Float pxFloats)
            free pxFloats

stateBool Up = False
stateBool Down = True

keyboardMouse keyRef mouseRef (Char 'w') state modifiers position = do
    (fwd, back, left, right) <- readIORef keyRef
    writeIORef keyRef ((stateBool state), back, left, right)
keyboardMouse keyRef mouseRef (Char 's') state modifiers position = do
    (fwd, back, left, right) <- readIORef keyRef
    writeIORef keyRef (fwd, (stateBool state), left, right)
keyboardMouse keyRef mouseRef (Char 'a') state modifiers position = do
    (fwd, back, left, right) <- readIORef keyRef
    writeIORef keyRef (fwd, back, (stateBool state), right)
keyboardMouse keyRef mouseRef (Char 'd') state modifiers position = do
    (fwd, back, left, right) <- readIORef keyRef
    writeIORef keyRef (fwd, back, left, (stateBool state))
keyboardMouse keyRef mouseRef (MouseButton LeftButton) Down modifiers (Position x y) = do
    writeIORef mouseRef (x, y, 0, 0)
keyboardMouse keyRef mouseRef key state modifiers position = return ()

mouseMotion mouseRef (Position x y) = do
    (oldx, oldy, dx, dy) <- readIORef mouseRef
    writeIORef mouseRef (x, y, dx+(x-oldx), dy+(y-oldy))

display =
    do
        renderPrimitive Quads $ do
            texCoord $ TexCoord2 (1::GLfloat) (0::GLfloat)
            vertex $ Vertex2 (0::GLfloat) (0::GLfloat)
            texCoord $ TexCoord2 (1::GLfloat) (1::GLfloat)
            vertex $ Vertex2 (0::GLfloat) (1::GLfloat)
            texCoord $ TexCoord2 (0::GLfloat) (1::GLfloat)
            vertex $ Vertex2 (1::GLfloat) (1::GLfloat)
            texCoord $ TexCoord2 (0::GLfloat) (0::GLfloat)
            vertex $ Vertex2 (1::GLfloat) (0::GLfloat)
        flush

main = do
    (progname, _) <- getArgsAndInitialize
    openGLInit
    mainLoop
