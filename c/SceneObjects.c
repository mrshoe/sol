/*
 * SceneObjects.c
 */

#include "SceneObjects.h"
#include "Triangle.h"
#include "Sphere.h"
#include "Lights.h"

int (*IntersectFunc[SCENE_OBJ_MAX])(SceneObject*,HitInfo*, Ray*, double, double) = {
	TriangleIntersect,
	SphereIntersect,
	PointLightIntersect,
};

void (*ExpandBoxFunc[SCENE_OBJ_MAX])(SceneObject*,Box*) = {
	TriangleExpandBox,
	SphereExpandBox,
	PointLightExpandBox,
};

int (*InBoxFunc[SCENE_OBJ_MAX])(SceneObject*,Box) = {
	TriangleInBox,
	SphereInBox,
	PointLightInBox,
};
