/*
 * OpenGL.d
 */

import std.stdio;
private import Camera, Image, Scene, Sol;

const float ANGFACT =			1.0;
const int LEFT =				4;
const int MIDDLE =				2;
const int RIGHT =				1;

//OpenGL defines
const int GL_LIGHTING =				0x0850;
const int GL_FLAT =					0x1D00;
const int GL_DEPTH_TEST =			0x0871;
const int GLUT_ELAPSED_TIME =		700;
const int GLUT_LEFT_BUTTON =		0x0;
const int GLUT_DOWN =				0x0;
const int GLUT_UP =					0x1;
//for Image.d
const int GL_TEXTURE_2D = 			0x0DE1;
const int GL_TEXTURE_MAG_FILTER = 	0x2800;
const int GL_TEXTURE_MIN_FILTER =	0x2801;
const int GL_NEAREST =				0x2600;
const int GL_TEXTURE_ENV =			0x2300;
const int GL_TEXTURE_ENV_MODE =		0x2200;
const int GL_REPLACE =				0x1E01;
const int GL_COMPILE =				0x1300;
const int GL_QUADS =				0x0007;
const int GL_RGB =					0x1907;
const int GL_FLOAT =				0x1406;

extern (C) {
	void glutInitWindowPosition(int, int);
	void glutInitWindowSize(int, int);
	void glutCreateWindow(char *);
	void glutMainLoop();
	void glutInit(int*,char**);
	void glutInitDisplayMode(int);
	void glutIdleFunc(void function());
	void glutDisplayFunc(void function());
	void glutIgnoreKeyRepeat(int);
	void glutKeyboardUpFunc(void function(char, int, int));
	void glutKeyboardFunc(void function(char, int, int));
	void glutMouseFunc(void function(int, int, int, int));
	void glutMotionFunc(void function(int, int));
	void glutSwapBuffers();
	void glutPostRedisplay();
	int  glutGet(int);
	void glDisable(int);
	void glShadeModel(int);
	void gluOrtho2D(double,double,double,double);

	//for Image.d
	void glGenTextures(int,int*);
	void glBindTexture(int,int);
	void glTexParameteri(int,int,int);
	void glTexImage2D(int,int,int,int,int,int,int,int,void*);
	void glEnable(int);
	void glTexEnvf(int,int,int);
	int  glGenLists(int);
	void glNewList(int,int);
	void glBegin(int);
	void glTexCoord2f(float,float);
	void glVertex2f(float,float);
	void glEnd();
	void glEndList();
	void glTexSubImage2D(int,int,int,int,int,int,int,int,void*);
	void glCallList(int);
	void glFlush();

	void PrintCPS()
	{
		static int numChunks = 1;
		static int baseTime = 0;
		int t = glutGet(GLUT_ELAPSED_TIME);
		float cps = cast(float)numChunks/((cast(float)t-baseTime)/1000.0);
		numChunks++;
		//cps is somewhat instantaneous -- over the last 40 chunks
		if(numChunks == 40)
		{
			baseTime = t;
			numChunks = 1;
		}
		fwritef(stderr,"\rchunks per second: %f",cps);
	}
	bool firstTime = true;
	void Display()
	{
		PrintCPS();
		if(firstTime)
		{
			image.Init();
			firstTime = false;
		}
		scene.RayTrace();
		image.Draw();
		glutSwapBuffers();
	}

	static bool[256] keys;
	void MoveCamera() {
		if(keys['w'] || keys['W'])
			camera.Forward(0.3f);
		if(keys['a'] || keys['A'])
			camera.Left(0.3f);
		if(keys['s'] || keys['S'])
			camera.Back(0.3f);
		if(keys['d'] || keys['D'])
			camera.Right(0.3f);
	}
	void Idle()
	{
		MoveCamera();
		glutPostRedisplay();
	}

	int gXmouse = -1, gYmouse = -1;
	void Motion(int x, int y)
	{
		if(gXmouse < 0)
			gXmouse = x;
		if(gYmouse < 0)
			gYmouse = y;

		int dx, dy;		// change in mouse coordinates

		dx = x - gXmouse;		// change in mouse coords
		dy = y - gYmouse;

		if(dx < 0)
			camera.Rotate(-0.05f);
		else
			camera.Rotate(0.05f);
		/*
		if (gLeftButtonDown)
		{
			float xfact = -ANGFACT*dy;
			float yfact = -ANGFACT*dx;
			// construct a coordinate system from up and viewdir
			Vector3 vRight;
			vRight.Cross(camera.lookAt, camera.up);
			// now rotate everything
			camera.lookAt.Rotate(xfact*SOL_PI/180., vRight);
			camera.lookAt.Rotate(yfact*SOL_PI/180., camera.up);
			//g_pCamera->GetUp().Rotate(-xfact*SOL_PI/180., vRight);
		}
		*/

		gXmouse = x;			// new current position
		gYmouse = y;

		glutPostRedisplay();
	}

	void Mouse(int button, int state, int x, int y)
	{
		/*
		int b; // LEFT, MIDDLE, or RIGHT

		switch(button)
		{
			case GLUT_LEFT_BUTTON:
			b = LEFT;		break;
			case GLUT_MIDDLE_BUTTON:
			b = MIDDLE;		break;
			case GLUT_RIGHT_BUTTON:
			b = RIGHT;		break;
			default:
			b = 0;
		}

		if(state == GLUT_DOWN)
		{
			g_iXmouse = x;
			g_iYmouse = y;
			g_iActiveButton |= b;		// set the proper bit
		}
		else
			g_iActiveButton &= ~b;		// clear the proper bit
		*/
	}

	void Keyboard(char key, int x, int y)
	{
		keys[key] = true;
		if(cast(int)key == 27) {
			/*
			printf("Intersects: %d\nRays: %d\n",objIntersections,rayCount);
			printf("Leaves: %d\nObjs: %d\nBSP Objs: %d\n",numLeaves,numObjs,totalObjs);
			printf("Max Objs in Leaf: %d\n",maxObjs);
			printf("Intersects/Ray: %f\n",(float)objIntersections/(float)rayCount);
			printf("Objs/Leaf: %f\n",(float)totalObjs/(float)numLeaves);
			*/
			SolExit();
		}
		glutPostRedisplay();
	}
	void KeyboardUp(char key, int x, int y)
	{
		keys[key] = false;
	}

	void Reshape(int w, int h)
	{
		/*
		glViewport(0, 0, w, h);
		glutPostRedisplay();
		*/
	}
}

void OpenGLInit()
{
	glutInitWindowSize(image.width,image.height);
//	glutInitDisplayMode(GLUT_RGB | GLUT_DOUBLE);
	glutInitDisplayMode(2);			// D equiv of above C line (glut.h)
	glutInitWindowPosition(100, 20);
	glutCreateWindow("Sol");

	glutIdleFunc(&Idle);
	glutDisplayFunc(&Display);
	glutIgnoreKeyRepeat(1);
	glutKeyboardFunc(&Keyboard);
	glutKeyboardUpFunc(&KeyboardUp);
	//    glutReshapeFunc(&Reshape);
	glutMouseFunc(&Mouse);
	glutMotionFunc(&Motion);

	glDisable(GL_LIGHTING);
	glShadeModel(GL_FLAT);
	glDisable(GL_DEPTH_TEST);
//	glPolygonMode(GL_FRONT_AND_BACK, GL_LINE); // draw outlines only
	gluOrtho2D(0,1,0,1);
}
