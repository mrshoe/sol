/*
 * Camera.c
 */

#include "Camera.h"
#include "Image.h"
#include <math.h>
#include <Accelerate/Accelerate.h>

Camera cam;

void CameraCalcViewDir()
{
	V3Subtract(&(cam.dir),cam.lookAt,cam.eye);
	V3Normalize(&(cam.dir));
}

void CameraInit(int width, int height)
{
	float fov;
	cam.b.z = 0.0001f;
	cam.t.z = cam.b.z + 1.0f;
	fov = M_PI * (cam.fov / 360.0f);
	//tan(fov) = t.y / b.z
	cam.t.y = cam.b.z * tanf(fov);
	//t.x / t.y = nx / ny
	cam.t.x = ((float)width / (float)height) * cam.t.y;
	cam.b.x = -(cam.t.x);
	cam.b.y = -(cam.t.y);
	CameraCalcViewDir();
	CameraUpdate();
}

void CameraUpdate()
{
	cam.w = cam.dir;

	V3Cross(&(cam.u), cam.up, cam.w);
	V3Normalize(&(cam.u));

	V3Cross(&(cam.v), cam.w, cam.u);
}

void CameraEyeRay(Ray *r, int x, int y, int width, int height, int subx, int suby, int antiAliasKernelSize)
{
	Vector3 result,uprime,vprime,wprime;
	// x-flip ?
	x = width - x;
	// y-flip ?
//	y = height - y;
	result.x = cam.b.x + ((cam.t.x - cam.b.x) * ((float)x + ((float)(subx+1)/(antiAliasKernelSize+1))) / (float)width);
	result.y = cam.b.y + ((cam.t.y - cam.b.y) * ((float)y + ((float)(suby+1)/(antiAliasKernelSize+1))) / (float)height);
	result.z = cam.b.z;
	uprime = cam.u;
	cblas_sscal(3, result.x, (float*)&uprime, 1);
	vprime = cam.v;
	cblas_sscal(3, result.y, (float*)&vprime, 1);
	wprime = cam.w;
	cblas_sscal(3, result.z, (float*)&wprime, 1);
	//with respect to the eye
	result.x = uprime.x + vprime.x + wprime.x;
	result.y = uprime.y + vprime.y + wprime.y;
	result.z = uprime.z + vprime.z + wprime.z;
	V3Normalize(&result);
    r->o = cam.eye;
	r->d = result;
}

void CameraForward(float dist)
{
	Vector3 toMove = cam.dir;

	cblas_sscal(3, dist, (float*)&toMove, 1);
	V3AddTo(&(cam.eye), toMove);
	CameraUpdate();
}

void CameraBack(float dist)
{
	Vector3 toMove = cam.dir;

	cblas_sscal(3, -dist, (float*)&toMove, 1);
	V3AddTo(&(cam.eye), toMove);
	CameraUpdate();
}

void CameraLeft(float dist)
{
	Vector3 toMove;

	V3Cross(&toMove, cam.up, cam.dir);
	cblas_sscal(3, dist, (float*)&toMove, 1);
	V3AddTo(&(cam.eye), toMove);
	CameraUpdate();
}

void CameraRight(float dist)
{
	Vector3 toMove;

	V3Cross(&toMove, cam.up, cam.dir);
	cblas_sscal(3, -dist, (float*)&toMove, 1);
	V3AddTo(&(cam.eye), toMove);
	CameraUpdate();
}


