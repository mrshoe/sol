/*
 * Triangle.h
 */

#ifndef SOL_TRIANGLE_H
#define SOL_TRIANGLE_H

#include "Sol.h"
#include "SceneObjects.h"
#include "Vector3.h"

typedef struct _Triangle {
	char type, material;
	Vector3 v1, v2, v3;
	Vector3 n1, n2, n3;
} Triangle;

Triangle *TriangleNew();
int TriangleIntersect(SceneObject *obj, HitInfo *result, Ray *ray,
							double tMin, double tMax);
void TriangleExpandBox(SceneObject *obj, Box *box);
int TriangleInBox(SceneObject *obj, Box box);
void LoadObj(char *filename, int material, Vector3 scale, Vector3 trans);

#endif			//SOL_TRIANGLE_H
