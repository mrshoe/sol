////////////////////////////////////////
// Vector3.h
////////////////////////////////////////

#ifndef SOL_VECTOR3_H
#define SOL_VECTOR3_H

////////////////////////////////////////////////////////////////////////////////

//math stuff.. maybe should go elsewhere
#ifndef M_PI
#define M_PI 			3.1415926535897932384626433832795028841972
#endif
#define MIN(x,y)		(x < y) ? x : y
#define MAX(x,y)		(x > y) ? x : y
#define SOL_TMAX		1e12

typedef struct _Vector3 {
	float x,y,z;
} Vector3;

void V3Set(Vector3 *v, float x, float y, float z);
void V3Zero(Vector3 *v);

void V3AddTo(Vector3 *v, Vector3 a);
void V3Add(Vector3 *v, Vector3 a, Vector3 b);
void V3SubtractFrom(Vector3 *v, Vector3 a);
void V3Subtract(Vector3 *v, Vector3 a, Vector3 b);

void V3Cross(Vector3 *v, Vector3 a, Vector3 b);

void V3Normalize(Vector3 *v);
void V3Negate(Vector3 *v);

float V3Mag(Vector3 v);
float V3Mag2(Vector3 v);

float V3Dist2(Vector3 v, Vector3 a);
float V3Dist(Vector3 v, Vector3 a);

//void V3Lerp(float t,const Vector3 a,const Vector3 b)	{Scale(a,1.0f-t); x+=b.x*t; y+=b.y*t; z+=b.z*t;}

// Misc functions
void V3Print(Vector3 v, char *name);

//float &operator[](int i)							{return(((float*)this)[i]);}
float *V3Component(Vector3 *v, int i);

// Global vectors
extern Vector3 XAXIS,YAXIS,ZAXIS;
extern Vector3 ORIGIN;
////////////////////////////////////////////////////////////////////////////////

#endif		//SOL_VECTOR3_H
