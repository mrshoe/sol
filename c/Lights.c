#include "Lights.h"
#include "SceneObjects.h"

void PointLightSample(PointLight *light, Vector3 *sample)
{
	*sample = light->pos;
}

PointLight *PointLightNew()
{
	PointLight *light = calloc(1,sizeof(PointLight));
	light->type = SCENE_POINT_LIGHT;
	light->sample = PointLightSample;
	return light;
}

int PointLightIntersect(SceneObject *l, HitInfo *hit, Ray *r,
							double tMin, double tMax)
{
	return false;
}

void PointLightExpandBox(SceneObject *obj, Box *box)
{
	// do lights need to expand the scene? maybe some day
	/*
	PointLight *l = (PointLight*)obj;
	int i;
	float *lCurr, *bCurr;
	for(i = 0; i < 3; i++)
	{
		lCurr = V3Component(&(l->pos), i);
		bCurr = V3Component(&(b->min), i);
		if(*lCurr < *bCurr)
			*bCurr = *lCurr;
		bCurr = V3Component(&(b->max), i);
		if(*lCurr > *bCurr)
			*bCurr = *lCurr;
	}
	*/
}

int PointLightInBox(SceneObject *obj, Box box)
{
	PointLight *l = (PointLight*)obj;
	return (l->pos.x >= box.min.x && l->pos.x <= box.max.x &&
			l->pos.y >= box.min.y && l->pos.y <= box.max.y &&
			l->pos.z >= box.min.z && l->pos.z <= box.max.z);
}
