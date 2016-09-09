/*
 * Material.h
 */

#ifndef SOL_MATERIAL_H
#define SOL_MATERIAL_H

#include "Vector3.h"

typedef struct _Material {
	Vector3 color;
	float diffuse, specular;
} Material;

#endif			//SOL_MATERIAL_H
