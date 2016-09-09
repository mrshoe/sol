/*
 * SceneObjects.h
 */

#ifndef SOL_SCENEOBJECTS_H
#define SOL_SCENEOBJECTS_H

#include "Box.h"
#include "Sol.h"

typedef struct _SceneObject {
	char type, material;
} SceneObject;

typedef enum {
	SCENE_OBJ_TRIANGLE,
	SCENE_OBJ_SPHERE,
	SCENE_POINT_LIGHT,
	SCENE_OBJ_MAX,
} SceneObjType;

extern int (*IntersectFunc[SCENE_OBJ_MAX])(SceneObject*,HitInfo*, Ray*,
					double, double);
extern void (*ExpandBoxFunc[SCENE_OBJ_MAX])(SceneObject*,Box*);
extern int (*InBoxFunc[SCENE_OBJ_MAX])(SceneObject*,Box);

#endif			//SOL_SCENEOBJECTS_H
