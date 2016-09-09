private import Camera, Image, OpenGL, Scene, Sol;
int main(char[][] args)
{
	scene = new Scene();
	image = new Image();
	camera = new Camera();
	int argc = 0;
	if(SolInit(args))
	{
		camera.Init();
		glutInit(&argc,null);
		OpenGLInit();
		scene.Build();
		glutMainLoop();
	}
	return 0;
}
