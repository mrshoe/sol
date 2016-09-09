/*
 * Image.c
 */

#include "Image.h"
#include <stdlib.h>
#include <stdio.h>
#include "OpenGL.h"


GLuint ImageGenDisplayList()
{
	GLuint dispList;
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
	return dispList;
}

ImageChunk *ImageInit(int width, int height, int *numChunks)
{
	ImageChunk *result = NULL;
	int widthInChunks, heightInChunks;
	int i = 0, x = 0, y = 0;
	GLuint texName;
	int chunkWidth = 50;
	int chunkHeight = 50;

	widthInChunks = ((width - 1) / chunkWidth) + 1;
	heightInChunks = ((height - 1) / chunkHeight) + 1;
	*numChunks = widthInChunks * heightInChunks;
	result = calloc(*numChunks, sizeof(ImageChunk));
	for(i = 0; i < *numChunks; i++)
	{
		result[i].x = x;
		result[i].y = y;
		result[i].width = MIN(chunkWidth, (width - x));
		result[i].height = MIN(chunkHeight, (height - y));
		result[i].pixels = calloc(result[i].width*result[i].height, sizeof(Vector3));
		result[i].queue = dispatch_queue_create("chunks", DISPATCH_QUEUE_SERIAL);
		result[i].renders = result[i].draws = 0;
		x += chunkWidth;
		if (x > width)
		{
			x = 0;
			y += chunkHeight;
		}
	}

	glGenTextures(1,&texName);
	glBindTexture(GL_TEXTURE_2D, texName);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height,
					0, GL_RGB,GL_FLOAT, NULL);
	glEnable(GL_TEXTURE_2D);
	glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE,GL_REPLACE);
	ImageGenDisplayList();
	return result;
}

int ImageDrawChunk(ImageChunk *chunk)
{
	if (chunk->renders > chunk->draws)
	{
		glTexSubImage2D(GL_TEXTURE_2D, 0, chunk->x, chunk->y,
							chunk->width, chunk->height,
							GL_RGB, GL_FLOAT, chunk->pixels);
		chunk->draws = chunk->renders;
		return 1;
	}
	return 0;
}
