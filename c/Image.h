#ifndef SOL_IMAGE_H
#define SOL_IMAGE_H

#include "Vector3.h"
#include "OpenGL.h"
#include <dispatch/dispatch.h>

typedef struct _ImageChunk {
	int x, y;
	int width, height;
	Vector3 *pixels;
	dispatch_queue_t queue;
	int renders, draws;
} ImageChunk;

ImageChunk *ImageInit(int width, int height, int *numChunks);
GLuint ImageGenDisplayList();
int ImageDrawChunk(ImageChunk *chunk);

#endif		//SOL_IMAGE_H
