/*
 * HitInfo.h
 */

#ifndef SOL_HITINFO_H
#define SOL_HITINFO_H

#include "Vector3.h"

typedef struct _HitInfo {
	double t;						// hit distance
	Vector3 P;						// hit point
	Vector3 N;						// hit surface normal
	char material;					// hit material
} HitInfo;

#endif			//SOL_HITINFO_H
