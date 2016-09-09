/*
 * Sol.c
 */

#include "Sol.h"
#include "BSP.h"
#include "Camera.h"
#include "Image.h"
#include "OpenGL.h"
#include "Scene.h"

extern void ParseFile(FILE *sceneFile);		//defined in Parser.y

void SolError()
{
	fprintf(stderr,TEXT_RED"Error:\n\t"TEXT_NORMAL);
}

void SolDebug()
{
	fprintf(stderr,TEXT_GREEN"Debug: "TEXT_NORMAL);
}

int SolInit(int argc, char *argv[])
{
	FILE *sceneFile;
	if(argc < 2)
	{
		fprintf(stderr,"Usage:\n\t%s scenefile\n",argv[0]);
		return false;
	}
	if(!(sceneFile = fopen(argv[1],"r")))
	{
		SolError();
		fprintf(stderr,"Unable to open scene file %s\n", argv[1]);
		return false;
	}
	ParseFile(sceneFile);
	fclose(sceneFile);
	return true;
}

void SolExit()
{
	fprintf(stderr,"\n");
	exit(0);
}

int main(int argc, char *argv[])
{
	SceneInit();
	if(SolInit(argc, argv))
	{
		glutInit(&argc, argv);
		CameraInit(scene.width,scene.height);
		BSPTreeBuild();
		ScenePhotonTrace();
		OpenGLInit();
		glutMainLoop();
	}
	return 0;
}
