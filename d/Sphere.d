/*
 * Sphere.d
 */

import std.math;
private import Scene, Vector3;


class Sphere : SceneObject {
	bool Intersect(out HitInfo result, Ray ray, double tMin, double tMax)
	{
		float discriminant;
		float dd, root, t;
		Vector3 toCenter;

		//pre-calc some stuff
		toCenter.Subtract(ray.o, center);
		dd = ray.d.Mag2();
		//B^2
		discriminant = ray.d.Dot(toCenter);
		discriminant *= discriminant;
		//4AC
		discriminant -= dd*(toCenter.Mag2()-(radius*radius));
		if(discriminant < 0)
			return false;

		root = sqrt(discriminant);
		t = -ray.d.Dot(toCenter);
		if(root > t)
			t += root;
		else
			t -= root;
		t /=dd;


		if(t < tMin || t > tMax)
			return false;
		result.t = t;
		result.P.Set(ray.d);
		result.P.Scale(t);
		result.P.Add(ray.o);
		result.N.Subtract(result.P, center);
		result.N.Normalize();
		result.material = material;

		return true;
	}
	void ExpandBox(inout Box box)
	{
		if((center.x - radius) < box.min.x)
			box.min.x = (center.x - radius);
		if((center.y - radius) < box.min.y)
			box.min.y = (center.y - radius);
		if((center.z - radius) < box.min.z)
			box.min.z = (center.z - radius);

		if((center.x + radius) > box.max.x)
			box.max.x = (center.x + radius);
		if((center.y + radius) > box.max.y)
			box.max.y = (center.y + radius);
		if((center.z + radius) > box.max.z)
			box.max.z = (center.z + radius);
	}
	bool InBox(Box box)
	{
		float s, d = 0;
		int i;
		float sCurr, bCurr;
		//find the square of the distance
		//from the sphere to the box
		for(i=0 ; i<3 ; i++ ) 
		{
			sCurr = center.Component(i);
			bCurr = box.min.Component(i);
			if( sCurr < bCurr)
			{
				s = sCurr - bCurr;
				d += s*s;
			}
			else
			{
				bCurr = box.max.Component(i);
				if( sCurr > bCurr)
				{
					s = sCurr - bCurr;
					d += s*s;
				}
			}
		}
		return d <= (radius*radius);
	}

	void SetRadius(float r) { radius = r; }
	void SetCenter(Vector3 c) { center = c; }
	Vector3 center;
	float radius;
}
