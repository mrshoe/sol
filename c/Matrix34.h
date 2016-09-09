////////////////////////////////////////
// Matrix34.h
////////////////////////////////////////

#ifndef SOL_MATRIX34_H
#define SOL_MATRIX34_H

#include "Vector3.h"

////////////////////////////////////////////////////////////////////////////////

typedef struct _Matrix34 {
	Vector3 a,b,c,d;
} Matrix34;

void M34Identity(Matrix34 *m);

// Dot
void M34Dot(Matrix34 *m, Matrix34 *a, Matrix34 *b);	// m = a (dot) b

// Transform
//void M34Transform(const Vector3 &in,Vector3 &out);
//void M34Transform3x3(const Vector3 &in,Vector3 &out) const;

// MakeRotate (NOTE: t is an angle in RADIANS)
void M34MakeRotateX(float t);
void M34MakeRotateY(float t);
void M34MakeRotateZ(float t);
void M34MakeRotateUnitAxis(const Vector3 &v,float t);	// v must be normalized

	// Scale
	void M34MakeScale(float x,float y,float z);
	void M34MakeScale(const Vector3 &v)				{MakeScale(v.x,v.y,v.z);}
	void M34MakeScale(float s)							{MakeScale(s,s,s);}

	// Translate
	void M34MakeTranslate(float x,float y,float z)		{Identity(); d.Set(x,y,z);}
	void M34MakeTranslate(const Vector3 &v)			{Identity(); d=v;}

	//Quaternions
//	void FromQuaternion(float q0, float q1, float q2, float q3);

	// Euler angles
//	enum {EULER_XYZ,EULER_XZY,EULER_YXZ,EULER_YZX,EULER_ZXY,EULER_ZYX};
//	void FromEulers(const Vector3 &euler,int order);
//	void ToEulers(Vector3 &euler,int order);

// Inversion
bool M34Inverse();									// Full inverse (expensive)
void M34FastInverse();								// Only works on ORTHONORMAL matrices
void M34Transpose();								// Only modifies 3x3 portion (doesn't change d)

// Viewing
void M34LookAt(const Vector3 &from,const Vector3 &to);
//void PolarView(float dist,float azm,float inc,float twst=0);

// Misc functions
float M34Determinant3x3() const;
void M34Print(const char *s=0) const;
//Vector3 &operator[](int i)						{return *((Vector3*)&(((float*)this)[i*4]));}	// yuck!
//operator float*()								{return (float*)this;}

// Static matrices
extern Matrix34 IDENTITY;


////////////////////////////////////////////////////////////////////////////////

/*
The Matrix34 is a more optimized version of a 4x4 matrix. In memory, it sits
like a 4x4 matrix due to the 4 pad variables which are set to 0,0,0,1.

There are 4 vectors which can be useful for geometric operations. Think of the
'a' vector as pointing to the object's right, 'b' pointing to the object's top,
and 'c' pointing to the objects back. Usually 'a', 'b', and 'c' will be unit
length and perpendicular to each other. 'd' represents the object's position.

There are various functions for creating standard matrices (rotation, translation,
scale...) as well as some other algebra functions (inverse, transpose...).

Because the Matrix34 sits in memory the same way as a 4x4 matrix, it can be
passed directly to OpenGL with the glMultMatrixf(mtx) or glLoadMatrixf(mtx)
commands. The Matrix34 specifies an implicit float* cast operation to make
this work.
*/

#endif		//SOL_MATRIX34_H
