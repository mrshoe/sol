/*
 * OpenGL.c
 */

#include "Camera.h"
#include "Sol.h"
#include "Scene.h"
#include "Image.h"
#include "OpenGL.h"
#include <time.h>
#include <dispatch/dispatch.h>
#include <Accelerate/Accelerate.h>

#define ANGFACT		0.0025f
#define LEFT		4
#define MIDDLE		2
#define RIGHT		1

dispatch_queue_t chunkQueue;
static int numChunks;
static ImageChunk *chunks;
static GLuint dispList;

static int wdown, adown, sdown, ddown;

void Redraw()
{
	int i;
	for(i = 0; i < numChunks; i++)
	{
		dispatch_async(chunks[i].queue, ^{ SceneRayTrace(&chunks[i]); });
	}
}

void Display()
{
	int i;
	static time_t lastTime = 0;
	static int fps = 0;
	time_t currTime = time(NULL);
	if(currTime != lastTime)
	{
		fprintf(stderr,"\r%d      ",fps);
		fps = 0;
	}
	lastTime = currTime;

	for(i = 0; i < numChunks; i++)
	{
		fps += ImageDrawChunk(&chunks[i]);
	}
	glCallList(dispList);
	glutSwapBuffers();
}

void Idle()
{
	int draw = 0;
	if (wdown) {
		CameraForward(0.04f);
		draw = 1;
	}
	if (adown) {
		CameraLeft(0.04f);
		draw = 1;
	}
	if (sdown) {
		CameraBack(0.04f);
		draw = 1;
	}
	if (ddown) {
		CameraRight(0.04f);
		draw = 1;
	}
	if (draw)
		Redraw();
    glutPostRedisplay();
}

enum foobar {
	BUTTON_LEFT = 0x01,
	BUTTON_RIGHT = 0x02,
	BUTTON_MIDDLE = 0x04
};

static int mouse_x, mouse_y;
static int activeButton = 0;

void Motion(int x, int y)
{
	int dx, dy;		// change in mouse coordinates

	dy = x - mouse_x;		// change in mouse coords
	dx = y - mouse_y;

	if (activeButton & BUTTON_LEFT)
	{
		float xfact = ANGFACT*dy;
		float yfact = ANGFACT*dx;
		// construct a coordinate system from up and viewdir
		Vector3 vRight, vUp;
		V3Cross(&vRight, cam.dir, cam.up);
		cblas_sscal(3, xfact, (float*)&vRight, 1);
		V3AddTo(&cam.dir, vRight);
		V3Normalize(&cam.dir);

		vUp = cam.up;
		cblas_sscal(3, yfact, (float*)&vUp, 1);
		V3AddTo(&cam.dir, vUp);
		V3Normalize(&cam.dir);
		CameraUpdate();
	}

	mouse_x = x;			// new current position
	mouse_y = y;

	Redraw();
	glutPostRedisplay();
}

void Mouse(int button, int state, int x, int y)
{
	int b;

	switch(button)
	{
		case GLUT_LEFT_BUTTON:
		b = BUTTON_LEFT;
		break;
		case GLUT_MIDDLE_BUTTON:
		b = BUTTON_MIDDLE;
		break;
		case GLUT_RIGHT_BUTTON:
		b = BUTTON_RIGHT;
		break;
		default:
		b = 0;
	}

	if(state == GLUT_DOWN)
	{
		mouse_x = x;
		mouse_y = y;
		activeButton |= b;		// set the proper bit
	}
	else
		activeButton &= ~b;		// clear the proper bit
}

void Keyboard(unsigned char key, int x, int y)
{
	switch (key)
	{
		case 27:
			/*
			printf("Intersects: %d\nRays: %d\n",objIntersections,rayCount);
			printf("Leaves: %d\nObjs: %d\nBSP Objs: %d\n",numLeaves,numObjs,totalObjs);
			printf("Max Objs in Leaf: %d\n",maxObjs);
			printf("Intersects/Ray: %f\n",(float)objIntersections/(float)rayCount);
			printf("Objs/Leaf: %f\n",(float)totalObjs/(float)numLeaves);
			*/
			SolExit();
			break;
		case 'w':
		case 'W':
			wdown = 1;
			break;
		case 'a':
		case 'A':
			adown = 1;
			break;
		case 's':
		case 'S':
			sdown = 1;
			break;
		case 'd':
		case 'D':
			ddown = 1;
			break;
		default:
			break;
    }
    glutPostRedisplay();
}

void KeyboardUp(unsigned char key, int x, int y)
{
	switch (key)
	{
		case 'w':
		case 'W':
			wdown = 0;
			break;
		case 'a':
		case 'A':
			adown = 0;
			break;
		case 's':
		case 'S':
			sdown = 0;
			break;
		case 'd':
		case 'D':
			ddown = 0;
			break;
		default:
			break;
    }
    glutPostRedisplay();
}

void Reshape(int w, int h)
{
    glViewport(0, 0, w, h);
    glutPostRedisplay();
}

void OpenGLInit()
{
	glutInitWindowSize(scene.width,scene.height);
	glutInitDisplayMode(GLUT_RGB | GLUT_DOUBLE);
	glutInitWindowPosition(100, 20);
	glutCreateWindow("Sol");

	glutIdleFunc(Idle);
	glutDisplayFunc(Display);
	glutKeyboardFunc(Keyboard);
	glutKeyboardUpFunc(KeyboardUp);
	//    glutReshapeFunc(Reshape);
	glutMouseFunc(Mouse);
	glutMotionFunc(Motion);

	// use the user defined clear color (defaults to black)
	/*
	glClearColor(g_pCamera->GetBGColor().x,
				 g_pCamera->GetBGColor().y,
				 g_pCamera->GetBGColor().z, 1);
	*/

	glDisable(GL_LIGHTING);
	glShadeModel(GL_FLAT);
	glDisable(GL_DEPTH_TEST);
//	glPolygonMode(GL_FRONT_AND_BACK, GL_LINE); // draw outlines only
	gluOrtho2D(0,1,0,1);

	chunks = ImageInit(scene.width,scene.height, &numChunks);
	dispList = ImageGenDisplayList();
	Redraw();
}
