/*
 * Scene.h
 */

#ifndef SOL_SCENE_H
#define SOL_SCENE_H

#include "Array.h"
#include "Lights.h"
#include "Image.h"
#include "Material.h"
#include "PhotonMap.h"
#include "SceneObjects.h"
#include "Sol.h"
#include "Vector3.h"

#define SCENE_MAX_MATERIALS					32

typedef struct _Scene {
	Array objs;
	Array lights;
	Material materials[SCENE_MAX_MATERIALS];
	PhotonMap *photonMap;
	Vector3 bgColor;
	int width, height;
} Scene;
extern Scene scene;

void SceneInit();
void SceneAddObj(SceneObject *newObj);
void SceneAddLight(Light *newLight);
void ScenePhotonTrace();
void SceneRayTrace(ImageChunk *chunk);
void SceneShade(Vector3 *pixel, HitInfo *hit, Ray *ray, int depth);
int SceneBSPTrace(Ray *ray, HitInfo *minHit, double tMin, double tMax);
int SceneTrace(Ray *ray, HitInfo *minHit, double tMin, double tMax);

#endif			//SOL_SCENE_H
