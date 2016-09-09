/*
 * Triangle.d
 */

private import Scene, Vector3;

class Triangle : SceneObject {
	void PreCalc() { }
	bool Intersect(out HitInfo result, Ray ray, double tMin, double tMax)
	{
		//page 157 in shirleys' book explains this code
		//(see online errata for corrections)
		
		//used to interpolate normal
		Vector3 tn1, tn2, tn3;
		//barycentric coords
		float alpha, B, G;
		float a = v1.x - v2.x;
		float b = v1.y - v2.y;
		float c = v1.z - v2.z;
		float d = v1.x - v3.x;
		float e = v1.y - v3.y;
		float f = v1.z - v3.z;
		float g = ray.d.x;
		float h = ray.d.y;
		float i = ray.d.z;
		float j = v1.x - ray.o.x;
		float k = v1.y - ray.o.y;
		float l = v1.z - ray.o.z;
		float ei_hf = e*i - h*f;
		float gf_di = g*f - d*i;
		float dh_eg = d*h - e*g;
		float M = a*ei_hf + b*gf_di + c*dh_eg;

		float t = -((f*(a*k-j*b) + e*(j*c-a*l) + d*(b*l-k*c))/M);
		if(t < tMin || t > tMax)
			return false;
		B = (j*ei_hf + k*gf_di + l*dh_eg)/M;
		if(B < -0.0001f || B > 1.0001f)
			return false;
		G = (i*(a*k-j*b) + h*(j*c-a*l) + g*(b*l-k*c))/M;
		if(G < -0.0001f || G > (1.0001f-B))
			return false;

		result.t = t;
		result.P.Set(ray.o.x + ray.d.x*t, ray.o.y + ray.d.y*t, ray.o.z + ray.d.z*t);
		alpha = (1.0f-B-G);
		tn1.Set(n1.x*alpha,n1.y*alpha,n1.z*alpha);
		tn2.Set(n2.x*B,n2.y*B,n2.z*B);
		tn3.Set(n3.x*G,n3.y*G,n3.z*G);
		result.N.Set(tn1.x+tn2.x+tn3.x,tn1.y+tn2.y+tn3.y,tn1.z+tn2.z+tn3.z);
		result.N.Normalize();
		result.material = material;
		return true;
	}
	void ExpandBox(inout Box box)
	{
		int i;
		float boxCurr, triCurr;

		for(i = 0; i < 3; i++)
		{
			// check the maxes
			boxCurr = box.max.Component(i);
			triCurr = v1.Component(i);
			if(triCurr > boxCurr)
				box.max.ComponentSet(i, triCurr);
			boxCurr = box.max.Component(i);
			triCurr = v2.Component(i);
			if(triCurr > boxCurr)
				box.max.ComponentSet(i, triCurr);
			boxCurr = box.max.Component(i);
			triCurr = v3.Component(i);
			if(triCurr > boxCurr)
				box.max.ComponentSet(i, triCurr);

			// check the mins
			boxCurr = box.min.Component(i);
			triCurr = v1.Component(i);
			if(triCurr < boxCurr)
				box.min.ComponentSet(i, triCurr);
			boxCurr = box.min.Component(i);
			triCurr = v2.Component(i);
			if(triCurr < boxCurr)
				box.min.ComponentSet(i, triCurr);
			boxCurr = box.min.Component(i);
			triCurr = v3.Component(i);
			if(triCurr < boxCurr)
				box.min.ComponentSet(i, triCurr);
		}
	}
	private bool OutsideBox(Box box)
	{
		//see if all points are outside box
		if((v1.x < box.min.x) && (v2.x < box.min.x) &&
			(v3.x < box.min.x))
			return true;
		if((v1.x > box.max.x) && (v2.x > box.max.x) &&
			(v3.x > box.max.x))
			return true;
		if((v1.y < box.min.y) && (v2.y < box.min.y) &&
			(v3.y < box.min.y))
			return true;
		if((v1.y > box.max.y) && (v2.y > box.max.y) &&
			(v3.y > box.max.y))
			return true;
		if((v1.z < box.min.z) && (v2.z < box.min.z) &&
			(v3.z < box.min.z))
			return true;
		if((v1.z > box.max.z) && (v2.z > box.max.z) &&
			(v3.z > box.max.z))
			return true;
		return false;
	}
	private bool IntersectsBoxEdges(Box box)
	{
		Ray triRay;
		HitInfo hi;
		//check each edge of the triangle
		triRay.o.Set(v1);
		triRay.d.Subtract(v2, v1);
		if(box.Intersect(hi,triRay,0,1))
			return true;
		triRay.d.Subtract(v3, v1);
		if(box.Intersect(hi,triRay,0,1))
			return true;
		triRay.o.Set(v2);
		triRay.d.Subtract(v3, v2);
		if(box.Intersect(hi,triRay,0,1))
			return true;
		return false;
	}
	private bool IntersectsBoxDiagonals(Box box)
	{
		//b1 == box.m_vMin, t3 == box.m_vMax
		Vector3 b2, b3, b4, t1, t2, t4;
		Ray ray;
		HitInfo hi;

		ray.o.Set(box.min);
		ray.d.Subtract(box.max, box.min);
		if(Intersect(hi,ray,0,1))
			return true;

		b2.Set(box.max.x,box.min.y,box.min.z);
		t4.Set(box.min.x,box.max.y,box.max.z);
		ray.o.Set(b2);
		ray.d.Subtract(t4, b2);
		if(Intersect(hi,ray,0,1))
			return true;

		b3.Set(box.max.x,box.min.y,box.max.z);
		t1.Set(box.min.x,box.max.y,box.min.z);
		ray.o.Set(b3);
		ray.d.Subtract(t1, b3);
		if(Intersect(hi,ray,0,1))
			return true;

		b4.Set(box.min.x,box.min.y,box.max.z);
		t2.Set(box.max.x,box.max.y,box.min.z);
		ray.o.Set(b4);
		ray.d.Subtract(t2, b4);
		if(Intersect(hi,ray,0,1))
			return true;

		return false;
	}
	bool InBox(Box box)
	{
		if(OutsideBox(box))
			return false;
		//see if all points are inside box
		if(box.ContainsPoint(v1) && box.ContainsPoint(v2) &&
			box.ContainsPoint(v3))
			return true;
		if(IntersectsBoxEdges(box))
			return true;

		//Check box diagonals vs. triangle
		return IntersectsBoxDiagonals(box);
	}

	void SetV1(Vector3 v) { v1 = v; }
	void SetV2(Vector3 v) { v2 = v; }
	void SetV3(Vector3 v) { v3 = v; }
	void SetN1(Vector3 v) { n1 = v; }
	void SetN2(Vector3 v) { n2 = v; }
	void SetN3(Vector3 v) { n3 = v; }

	Vector3 v1, v2, v3;
	Vector3 n1, n2, n3;
	Vector3 abc, def;
}
