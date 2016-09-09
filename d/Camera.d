/*
 * Camera.d
 */

import std.math;
private import Image, Scene, Sol, Vector3;

class Camera {
	void Init()
	{
		float FOV;
		b.z = 0.0001f;
		t.z = b.z + 1.0f;
		FOV = SOL_PI * (fov / 360.0f);
		//tan(fov) = t.y / b.z
		t.y = b.z * tan(FOV);
		//t.x / t.y = nx / ny
		t.x = (cast(float)image.width / cast(float)image.height) * t.y;
		b.x = -(t.x);
		b.y = -(t.y);
		CalcViewDir();
		Update();
	}

	private void CalcViewDir()
	{
		dir.Subtract(lookAt,eye);
		dir.Normalize();
	}

	void Update()
	{
		w = dir;

		u.Cross(up, w);
		u.Normalize();

		v.Cross(w, u);
	}

	void EyeRay(out Ray r, int x, int y)
	{
		Vector3 uprime, vprime, wprime;
		// x-flip ?
		x = image.width - x;
		// y-flip ?
	//	y = image.height - y;
		r.d.x = b.x + ((t.x - b.x) * (cast(float)x + 0.5f) / cast(float)image.width);
		r.d.y = b.y + ((t.y - b.y) * (cast(float)y + 0.5f) / cast(float)image.height);
		r.d.z = b.z;
		uprime.Set(u.x*r.d.x,u.y*r.d.x,u.z*r.d.x);
		vprime.Set(v.x*r.d.y,v.y*r.d.y,v.z*r.d.y);
		wprime.Set(w.x*r.d.z,w.y*r.d.z,w.z*r.d.z);
		//with respect to the eye
		r.d.x = uprime.x + vprime.x + wprime.x;
		r.d.y = uprime.y + vprime.y + wprime.y;
		r.d.z = uprime.z + vprime.z + wprime.z;
		r.d.Normalize();
		r.o = eye;
	}

	void Forward(float dist)
	{
		Vector3 toMove = dir;

		toMove.Scale(dist);
		eye.Add(toMove);
		Update();
	}

	void Back(float dist)
	{
		Vector3 toMove = dir;

		toMove.Scale(-dist);
		eye.Add(toMove);
		Update();
	}

	void Left(float dist)
	{
		Vector3 toMove;

		toMove.Cross(up, dir);
		toMove.Scale(dist);
		eye.Add(toMove);
		Update();
	}

	void Right(float dist)
	{
		Vector3 toMove;

		toMove.Cross(up, dir);
		toMove.Scale(-dist);
		eye.Add(toMove);
		Update();
	}
	void Rotate(float amt)
	{
		dir.x += amt;
		dir.Normalize();
		Update();
	}

	void SetPos(Vector3 p) { eye = p; }
	void SetUp(Vector3 u) { up = u; }
	void SetLookAt(Vector3 l) { lookAt = l; }
	void SetFOV(int fov) { this.fov = fov; }

	Vector3 eye, up, dir, lookAt;			//these properties can be changed
	Vector3 u, v, w, b, t;					//these properties are calculated
	int fov;
}

Camera camera;
