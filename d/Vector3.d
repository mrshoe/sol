/*
 * Vector3.d
 */

import std.math;
import std.stdio;

struct Vector3 {
	void Set(float x, float y, float z) { this.x = x; this.y = y; this.z = z; }
	void Set(Vector3 v) { x = v.x; y = v.y; z = v.z; }
	void Zero() { x = y = z = 0.0f; }
	// Algebra
	void Add(Vector3 a, Vector3 b) { x=a.x+b.x; y=a.y+b.y; z=a.z+b.z; }
	void Add(Vector3 a) { x += a.x; y += a.y; z += a.z; }
	void Subtract(Vector3 a, Vector3 b) { x=a.x-b.x; y=a.y-b.y; z=a.z-b.z; }
	void Subtract(Vector3 a) { x -= a.x; y -= a.y; z -= a.z; }
	void Scale(float s) { x *= s; y *= s; z *= s; }
	float Dot(Vector3 v) { return x*v.x + y*v.y + z*v.z; }
	void Cross(Vector3 a, Vector3 b) {
		x = a.y*b.z - a.z*b.y;
		y = a.z*b.x - a.x*b.z;
		z = a.x*b.y - a.y*b.x;
	}
	void Normalize() {
		float s = 1.0f/Mag();
		x *= s; y *= s; z *= s;
	}
	void Negate() { x = -x; y = -y; z = -z; }
	float Mag() { return sqrt(Mag2()); }
	float Mag2() { return x*x + y*y + z*z; }
	float Dist2(Vector3 v) {
		float a = x-v.x, b = y-v.y, c = z-v.z;
		return a*a + b*b + c*c;
	}
	float Dist(Vector3 v) { return sqrt(Dist(v)); }
	//void V3Lerp(float t,const Vector3 a,const Vector3 b)	{Scale(a,1.0f-t); x+=b.x*t; y+=b.y*t; z+=b.z*t;}
	// Misc functions
	void Print(char[] label) { writef("%s = { %f, %f, %f }\n",label,x,y,z); }
	float Component(int c) { return (&x)[c]; }
	void ComponentSet(int c, float v) { (&x)[c] = v; }

	float x = 0.0f, y = 0.0f, z = 0.0f;
}

struct Ray {
	Vector3 o,d;
}
