/*
 * Scene.c
 */

#include <stdlib.h>
#include <math.h>
#include <Accelerate/Accelerate.h>
#include "BSP.h"
#include "Camera.h"
#include "Image.h"
#include "PhotonMap.h"
#include "Scene.h"

//the global scene object
Scene scene;

void SceneInit()
{
	ArrayInit(&(scene.objs), 200);
	ArrayInit(&(scene.lights), 8);
	V3Set(&(scene.bgColor),0,0,0);
	scene.width = scene.height = 512;
}

void SceneAddObj(SceneObject *newObj)
{
	ArrayInsert(&(scene.objs), (void*)newObj);
}

void SceneAddLight(Light *newLight)
{
	// add the light to the scene as well so it is intersected by all rays
	ArrayInsert(&(scene.objs), (void*)newLight);
	ArrayInsert(&(scene.lights), (void*)newLight);
}

void ScenePhotonTrace()
{
	scene.photonMap = PhotonMapInit(10000);
}

void SceneShade(Vector3 *pixel, HitInfo *hit, Ray *ray, int depth)
{
	int currLight;
	float lightDistSq, lightDist, lightFalloff;
	float diffuse;
	Vector3 toLight;
	Vector3 result;
	Vector3 tmpColor;
	HitInfo tmpHit;
	Ray tmpRay;
	V3Set(pixel, 0,0,0);
	if(depth > 3)
		return;
	
	for(currLight = 0; currLight < scene.lights.length; currLight++)
	{
		// diffuse shader
		result = scene.materials[(int)(hit->material)].color;
		V3Subtract(&toLight, ((Light*)scene.lights.data[currLight])->pos, hit->P);
		lightDistSq = V3Mag2(toLight);
		lightDist = sqrtf(lightDistSq);
		lightFalloff = 4*M_PI*lightDistSq / ((Light*)scene.lights.data[currLight])->wattage;
		// normalize toLight
		cblas_sscal(3, 1.0f/lightDist, (float*)&toLight, 1);
		// shadow ray
		tmpRay.o = hit->P;
		tmpRay.d = toLight;
		if(SceneBSPTrace(&tmpRay,&tmpHit, 0.001, lightDist))
			diffuse = 0.0f;
		else
			diffuse = cblas_sdot(3, (float*)&(hit->N), 1, (float*)&(toLight), 1);
		if(diffuse < 0.0f) diffuse = 0.0f;
		cblas_sscal(3, diffuse / lightFalloff, (float*)&result, 1);

		// specular shader
		if(scene.materials[(int)hit->material].specular > 0.0001)
		{
			tmpRay.o = hit->P;
			tmpRay.d = hit->N;
			cblas_sscal(3, -2.0f * cblas_sdot(3, (float*)&(ray->d), 1, (float*)&(hit->N), 1), (float*)&(tmpRay.d), 1);
			if(SceneBSPTrace(&tmpRay,&tmpHit,0.001,SOL_TMAX))
				SceneShade(&tmpColor,&tmpHit,&tmpRay,depth+1);
			else
				tmpColor = scene.bgColor;
			cblas_sscal(3, scene.materials[(int)(hit->material)].specular, (float*)&tmpColor, 1); 
			V3AddTo(&result,tmpColor);
		}

		V3AddTo(pixel, result);
	}
}

int SceneBSPTrace(Ray *ray, HitInfo *minHit, double tMin, double tMax)
{
	return BSPTreeIntersect(minHit, ray, tMin, tMax);
}

int SceneTrace(Ray *ray, HitInfo *minHit, double tMin, double tMax)
{
	int obj;
	HitInfo hi;
	int result = false;
	SceneObject *currObj;
	for(obj = 0; obj < scene.objs.length; obj++)
	{
		currObj = (SceneObject*)scene.objs.data[obj];
		if(IntersectFunc[(int)currObj->type](currObj, &hi,
								ray, tMin, tMax))
		{
			if(!result || hi.t < minHit->t)
			{
				result = true;
				*minHit = hi;
			}
		}
	}
	return result;
}

#define ANTI_ALIAS_KERNEL_SIZE (2)
#define ANTI_ALIAS_SUBPIX_COUNT (ANTI_ALIAS_KERNEL_SIZE*ANTI_ALIAS_KERNEL_SIZE)
void SceneRayTrace(ImageChunk *chunk)
{
	Ray eyeRay;
	HitInfo minHit;
	int i,j,ii,jj;
	int pixOffs=0, subpixOffs=0;
	Vector3 pixel = {0.0f, 0.0f, 0.0f};
	Vector3 subPixels[ANTI_ALIAS_SUBPIX_COUNT];
	for(i = 0; i < chunk->height; i++)
	{
		for(j = 0; j < chunk->width; j++)
		{
			subpixOffs = 0;
			pixel.x = pixel.y = pixel.z = 0.0f;
			for(ii = 0; ii < ANTI_ALIAS_KERNEL_SIZE; ii++)
			{
				for(jj = 0; jj < ANTI_ALIAS_KERNEL_SIZE; jj++)
				{
					CameraEyeRay(&eyeRay, chunk->x + j, chunk->y + i, scene.width, scene.height, ii, jj, ANTI_ALIAS_KERNEL_SIZE);
					if(SceneBSPTrace(&eyeRay, &minHit, 0.0, SOL_TMAX))
						SceneShade(&subPixels[subpixOffs], &minHit, &eyeRay, 0); 
					else
						subPixels[subpixOffs] = scene.bgColor;
					subpixOffs++;
				}
			}
			for(subpixOffs=0; subpixOffs < ANTI_ALIAS_SUBPIX_COUNT; subpixOffs++)
				V3AddTo(&pixel, subPixels[subpixOffs]);
			cblas_sscal(3, 1.0f/ANTI_ALIAS_SUBPIX_COUNT, (float*)&pixel, 1);
			chunk->pixels[pixOffs++] = pixel;
		}
	}
	chunk->renders++;
}
