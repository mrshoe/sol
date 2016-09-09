////////////////////////////////////////
// Vector3.c
////////////////////////////////////////
#include "Vector3.h"
#include <stdio.h>
#include <math.h>

void V3Set(Vector3 *v, float x, float y, float z)
			{ v->x = x; v->y = y; v->z = z; }
void V3Zero(Vector3 *v)
			{ v->x = v->y = v->z = 0.0f; }
// Algebra
void V3AddTo(Vector3 *v, Vector3 a)
			{v->x+=a.x; v->y+=a.y; v->z+=a.z;}
void V3Add(Vector3 *v, Vector3 a, Vector3 b)
			{v->x=a.x+b.x; v->y=a.y+b.y; v->z=a.z+b.z;}
void V3SubtractFrom(Vector3 *v, Vector3 a)
			{v->x-=a.x; v->y-=a.y; v->z-=a.z;}
void V3Subtract(Vector3 *v, Vector3 a, Vector3 b)
			{v->x=a.x-b.x; v->y=a.y-b.y; v->z=a.z-b.z;}

void V3Cross(Vector3 *v, Vector3 a, Vector3 b)
			{v->x=a.y*b.z-a.z*b.y; v->y=a.z*b.x-a.x*b.z; v->z=a.x*b.y-a.y*b.x;}

void V3Normalize(Vector3 *v)
			{float s=1.0f/sqrtf(v->x*v->x+v->y*v->y+v->z*v->z);
			 v->x*=s; v->y*=s; v->z*=s;}
void V3Negate(Vector3 *v)
			{v->x=-v->x; v->y=-v->y; v->z=-v->z;}

float V3Mag(Vector3 v)
			{return sqrtf(v.x*v.x+v.y*v.y+v.z*v.z);}
float V3Mag2(Vector3 v)
			{return v.x*v.x+v.y*v.y+v.z*v.z;}

float V3Dist2(Vector3 v, Vector3 a)
			{return (v.x-a.x)*(v.x-a.x)+(v.y-a.y)*(v.y-a.y)+
					(v.z-a.z)*(v.z-a.z);}
float V3Dist(Vector3 v, Vector3 a)
			{return sqrtf(V3Dist2(v,a));}

//void V3Lerp(float t,const Vector3 a,const Vector3 b)	{Scale(a,1.0f-t); x+=b.x*t; y+=b.y*t; z+=b.z*t;}

// Misc functions
void V3Print(Vector3 v, char *name)
		{if(name) printf("%s=",name); printf("{%f,%f,%f}\n",v.x,v.y,v.z);}

//float &operator[](int i)							{return(((float*)this)[i]);}
float *V3Component(Vector3 *v, int i)
		{return &(((float*)v)[i]);}	

// Global vectors
Vector3 XAXIS = {1,0,0}, YAXIS = {0,1,0}, ZAXIS = {0,0,1};
Vector3 ORIGIN = {0,0,0};
