/*
 * Image.d
 */

private import OpenGL, Sol, Vector3;

const int IMG_CHUNK_WIDTH = 128;
const int IMG_CHUNK_HEIGHT = 128;

class Image {
	this()
	{
		chunk.length = IMG_CHUNK_WIDTH*IMG_CHUNK_HEIGHT;
	}
	void SetWidth(int w) { width = w; }
	void SetHeight(int h) { height = h; }
	void Init()
	{
		int i;
		Vector3[] pixels;
		pixels.length = width*height;
		x = -IMG_CHUNK_WIDTH;
		y = 0;
		chunk.length = IMG_CHUNK_WIDTH*IMG_CHUNK_HEIGHT;
		for(i=0; i < width*height; i++)
			pixels[i].z = 1.0f;

		glGenTextures(1,&texName);
		glBindTexture(GL_TEXTURE_2D, texName);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
		glTexImage2D(GL_TEXTURE_2D,0,GL_RGB,width,height,
						0,GL_RGB,GL_FLOAT,cast(void*)pixels);
		glEnable(GL_TEXTURE_2D);
//		glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE,GL_REPLACE);
		GenDisplayList();
	}
	private void GenDisplayList()
	{
		dispList = glGenLists(1);
		glNewList(dispList, GL_COMPILE);
		glBegin(GL_QUADS);
		glTexCoord2f(0,0);
		glVertex2f(0,0);
		glTexCoord2f(0,1);
		glVertex2f(0,1);
		glTexCoord2f(1,1);
		glVertex2f(1,1);
		glTexCoord2f(1,0);
		glVertex2f(1,0);
		glEnd();
		glEndList();
	}

	void NextChunk()
	{
		x += IMG_CHUNK_WIDTH;
		if(x > width)
		{
			x = 0;
			y += IMG_CHUNK_HEIGHT;
			if(y > height)
				y = 0;
		}
		w = MIN(IMG_CHUNK_WIDTH, width - x);
		h = MIN(IMG_CHUNK_HEIGHT, height - y);
	}

	void Draw()
	{
		glTexSubImage2D(GL_TEXTURE_2D, 0, x, y, w, h, GL_RGB, GL_FLOAT, cast(void*)chunk);
		glCallList(dispList);
//		glFlush();
	}

	Vector3[] chunk;
	int texName, dispList;
	int width,height;
	int x, y, w, h;
}

Image image;
