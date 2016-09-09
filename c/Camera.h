/*
 * Camera.h
 */

#ifndef SOL_CAMERA_H
#define SOL_CAMERA_H

#include "Vector3.h"
#include "Ray.h"

typedef struct _Camera {
	Vector3 eye, up, dir, lookAt;			//these properties can be changed
	Vector3 u, v, w, b, t;					//these properties are calculated
	int fov;
} Camera;

extern Camera cam;

void CameraInit(int width, int height);
void CameraUpdate();
void CameraEyeRay(Ray *r, int x, int y, int width, int height, int subx, int suby, int antiAliasKernelSize);

void CameraForward(float dist);
void CameraBack(float dist);
void CameraLeft(float dist);
void CameraRight(float dist);

#endif			//SOL_CAMERA_H
