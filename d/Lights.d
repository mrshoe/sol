/*
 * Lights.d
 */

private import Scene, Vector3;

class Light : SceneObject {
	bool Intersect(out HitInfo hi,Ray ray,double tMin,double tMax) { return false; }
	abstract void ExpandBox(inout Box box);
	abstract bool InBox(Box box);
	abstract Vector3 Sample();

	void SetPos(Vector3 p) { pos = p; }
	void SetWattage(int w) { wattage = w; }
	void SetColor(Vector3 c) { color = c; }

	int wattage;
	Vector3 pos;
	Vector3 color;
}

class PointLight : Light {
	void ExpandBox(inout Box box)
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

	bool InBox(Box box)
	{
		return (pos.x >= box.min.x && pos.x <= box.max.x &&
				pos.y >= box.min.y && pos.y <= box.max.y &&
				pos.z >= box.min.z && pos.z <= box.max.z);
	}

	Vector3 Sample() { return pos; }
}
