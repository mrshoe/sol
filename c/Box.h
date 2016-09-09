/*
 * Box.h
 */

#ifndef SOL_BOX_H
#define SOL_BOX_H

#include "Sol.h"
#include "Vector3.h"

typedef struct _Box {
	Vector3 min,max;
} Box;

int BoxIntersect(Box *box, HitInfo *hit, Ray *ray, double tMin, double tMax);
int BoxContainsPoint(Box *box, Vector3 p);

#endif			//SOL_BOX_H
