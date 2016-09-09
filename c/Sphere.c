/*
 * Sphere.c
 */

#include <math.h>
#include <Accelerate/Accelerate.h>
#include "Sol.h"
#include "Sphere.h"
#include "SceneObjects.h"

Sphere *SphereNew()
{
	Sphere *newSphere = (Sphere*)calloc(1,sizeof(Sphere));
	newSphere->type = SCENE_OBJ_SPHERE;
	newSphere->material = 0;
	return newSphere;
}

int SphereIntersect(SceneObject *obj, HitInfo *result, Ray *ray,
						double tMin, double tMax)
{
	float discriminant;
	Vector3 toCenter;
	float dd, root, t;
	Sphere *s = (Sphere*)obj;

	//pre-calc some stuff
	V3Subtract(&toCenter, ray->o, s->center);
	dd = V3Mag2(ray->d);
	//B^2
	discriminant = cblas_sdot(3, (float*)&(ray->d), 1, (float*)&(toCenter), 1);
	discriminant *= discriminant;
	//4AC
	discriminant -= (dd)*(V3Mag2(toCenter)-(s->radius*s->radius));
	if(discriminant < 0)
		return false;

	root = sqrtf(discriminant);
	t = -cblas_sdot(3, (float*)&(ray->d), 1, (float*)&(toCenter), 1);
	if(root > t)
		t += root;
	else
		t -= root;
	t /=dd;


	if(t < tMin || t > tMax)
		return false;
	result->t = t;
	result->P = ray->d;
	cblas_sscal(3, t, (float*)&(result->P), 1);
	V3AddTo(&(result->P), ray->o);
	V3Subtract(&(result->N), result->P, s->center);
	V3Normalize(&(result->N));
	result->material = s->material;

    return true;
}

void SphereExpandBox(SceneObject *obj, Box *box)
{
	Sphere *s = (Sphere*)obj;
	if((s->center.x - s->radius) < box->min.x)
		box->min.x = (s->center.x - s->radius);
	if((s->center.y - s->radius) < box->min.y)
		box->min.y = (s->center.y - s->radius);
	if((s->center.z - s->radius) < box->min.z)
		box->min.z = (s->center.z - s->radius);

	if((s->center.x + s->radius) > box->max.x)
		box->max.x = (s->center.x + s->radius);
	if((s->center.y + s->radius) > box->max.y)
		box->max.y = (s->center.y + s->radius);
	if((s->center.z + s->radius) > box->max.z)
		box->max.z = (s->center.z + s->radius);
}

int SphereInBox(SceneObject *obj, Box box)
{
	Sphere *sp = (Sphere*)obj;
	float s, d = 0;
	int i;
	float *sCurr, *bCurr;
	//find the square of the distance
	//from the sphere to the box
	for(i=0 ; i<3 ; i++ ) 
	{
		sCurr = V3Component(&(sp->center), i);
		bCurr = V3Component(&(box.min), i);
		if( *sCurr < *bCurr)
		{

			s = *sCurr - *bCurr;
			d += s*s;
		}
		else
		{
			bCurr = V3Component(&(box.max), i);
			if( *sCurr > *bCurr)
			{
				s = *sCurr - *bCurr;
				d += s*s;
			}
		}

	}
	return d <= (sp->radius*sp->radius);
}
