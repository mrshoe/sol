/*
 * Lights.h
 */

#ifndef SOL_LIGHTS_H
#define SOL_LIGHTS_H

#include "SceneObjects.h"
#include "Sol.h"
#include "Vector3.h"

// all light structs must start with these fields
typedef struct _Light {
	char type;			//must behave like a SceneObject
	int wattage;
	Vector3 pos;
	Vector3 color;
	void (*sample)(struct _Light*, Vector3*);
} Light;

typedef struct _PointLight {
	char type;
	int wattage;
	Vector3 pos;
	Vector3 color;
	void (*sample)(struct _PointLight*, Vector3*);
} PointLight;

PointLight *PointLightNew();
int PointLightIntersect(SceneObject *obj,HitInfo *hi,Ray *ray,double tMin,double tMax);
void PointLightExpandBox(SceneObject *obj, Box *box);
int PointLightInBox(SceneObject *obj, Box box);

#endif			//SOL_LIGHTS_H
