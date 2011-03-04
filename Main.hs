import Graphics.UI.GLUT
import OpenGL

main = do
    (progname, _) <- getArgsAndInitialize
    openGLInit
    mainLoop
