/*
 * AccelStructure.d
 */

private import Scene, Vector3;

// parent class for all acceleration structures
class AccelStructure {
	abstract void AddObj(SceneObject newObj);
	abstract bool Intersect(out HitInfo minHit, Ray ray, double tMin, double tMax);
	abstract void Build();
}

class NoAccel : AccelStructure
{
	this()
	{
		objs.length = 16;
	}
	void Build()
	{
		objs.length = numObjs;
		foreach(SceneObject obj; objs)
			obj.PreCalc();
	}
	void AddObj(SceneObject newObj)
	{
		if(numObjs >= (objs.length - 1))
			objs.length = objs.length * 2;
		objs[numObjs] = newObj;
		numObjs++;
	}

	bool Intersect(out HitInfo minHit, Ray ray, double tMin, double tMax)
	{
		bool result = false;
		HitInfo hi;
		foreach(SceneObject obj; objs)
		{
			if(obj.Intersect(hi,ray,tMin,tMax)) 
			{
				if(!result || hi.t < minHit.t)
				{
					result = true;
					minHit = hi;
				}
			}
		}
		return result;
	}
	int numObjs;
	SceneObject[] objs;
}
