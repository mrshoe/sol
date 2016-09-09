/*
 * Box.c
 */

#include "Box.h"

void FloatSwap(float *one, float *two)
{
	float temp = *one;
	*one = *two;
	*two = temp;
}

int BoxIntersect(Box *box, HitInfo *hit, Ray *ray, double tMin, double tMax)
{
	float T1, T2, Tnear, Tfar;
	// Try to bail out if the ray is paralell to the box sides
	// X Slabs:
	if ( ray->d.x == 0.0 && (ray->o.x < box->min.x || ray->o.x > box->max.x))
		return false;
	// Y Slabs:
	if ( ray->d.y == 0.0 && (ray->o.y < box->min.y || ray->o.y > box->max.y))
		return false;
	// Z Slabs:
	if ( ray->d.z == 0.0 && (ray->o.z < box->min.z || ray->o.z > box->max.z))
		return false;

	Tnear = tMin - 1.0f;
	Tfar = tMax + 1.0f;
	// X Slabs
	T1 = (box->min.x - ray->o.x) / ray->d.x;
	T2 = (box->max.x - ray->o.x) / ray->d.x;
	if ( T1 > T2 ) { FloatSwap(&T1, &T2); }
	if ( T1 > Tnear) { Tnear = T1; }
	if ( T2 < Tfar) Tfar = T2;
	if ( Tnear > Tfar ) return false;
	if ( Tfar < 0 ) return false;

	// Y Slabs
	T1 = (box->min.y - ray->o.y) / ray->d.y;
	T2 = (box->max.y - ray->o.y) / ray->d.y;
	if ( T1 > T2 ) { FloatSwap(&T1, &T2); }
	if ( T1 > Tnear) { Tnear = T1; }
	if ( T2 < Tfar) Tfar = T2;
	if ( Tnear > Tfar ) return false;
	if ( Tfar < 0 ) return false;

	// Z Slabs
	T1 = (box->min.z - ray->o.z) / ray->d.z;
	T2 = (box->max.z - ray->o.z) / ray->d.z;
	if ( T1 > T2 ) { FloatSwap(&T1, &T2); }
	if ( T1 > Tnear) { Tnear = T1; }
	if ( T2 < Tfar) Tfar = T2;
	if ( Tnear > Tfar ) return false;
	if ( Tfar < 0 ) return false;

	if ( Tnear < tMin)
		Tnear = Tfar;
	if ( Tnear < tMin || Tnear > tMax)
		return false;

	return true;
}

int BoxContainsPoint(Box *box, Vector3 p)
{
	return (p.x >= box->min.x && p.x <= box->max.x &&
			p.y >= box->min.y && p.y <= box->max.y &&
			p.z >= box->min.z && p.z <= box->max.z);
}
