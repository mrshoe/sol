/*
 * Sphere.h
 */

#ifndef SOL_SPHERE_H
#define SOL_SPHERE_H

#include "SceneObjects.h"
#include "Sol.h"
#include "Vector3.h"

typedef struct _Sphere {
	char type, material;
	Vector3 center;
	float radius;
} Sphere;

Sphere *SphereNew();
int SphereIntersect(SceneObject *obj, HitInfo *result, Ray *ray,
						double tMin, double tMax);
void SphereExpandBox(SceneObject *obj, Box *box);
int SphereInBox(SceneObject *obj, Box box);

#endif			//SOL_SPHERE_H
