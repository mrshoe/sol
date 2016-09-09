/*
 * BSP.d
 */

private import Scene, Sol, Vector3;

const float TINY = 						0.00001;

class BSPNode {
	this(int startObjs)
	{
		objs.length = startObjs;
		numObjs = 0;
	}
	bool LeafIntersect(out HitInfo minHit, Ray ray, double tMin, double tMax)
	{
		HitInfo tmpHit;
		int i;
		bool hit = false;
		minHit.t = tMax;

		// check for empty leaf node
		if(objs.length == 0)
			return false;
		// intersect each obj
		foreach(SceneObject obj; objs)
		{
			if(obj.Intersect(tmpHit,ray,tMin,tMax))
			{
				if(!hit || tmpHit.t < minHit.t)
					minHit = tmpHit;
				hit = true;
			}
		}
		return hit;
	}
	bool InteriorIntersect(out HitInfo minHit, Ray ray, double tMin, double tMax)
	{
		BSPNode nearNode, farNode;
		float t;
		float daxis;
		if((daxis=ray.d.Component(axis)) > 0) {
			nearNode = left;
			farNode = right;
		}
		else {
			nearNode = right;
			farNode = left;
		}
		// plane intersection
		t = (plane_pos - ray.o.Component(axis)) / daxis;
		if(t > tMax)
			return nearNode.Intersect(minHit,ray,tMin,tMax);
		else if(t < tMin)
			return farNode.Intersect(minHit,ray,tMin,tMax);
		else {
			if(nearNode.Intersect(minHit,ray,tMin,t))
				return true;
			else
				return farNode.Intersect(minHit,ray,t,tMax);
		}
	}
	bool Intersect(out HitInfo minHit, Ray ray, double tMin, double tMax)
	{
		if(isLeaf)
			return LeafIntersect(minHit, ray, tMin, tMax);
		else
			return InteriorIntersect(minHit, ray, tMin, tMax);
	}
	void AddObj(SceneObject obj)
	{
		if(numObjs >= (objs.length - 1))
			objs.length = objs.length * 2;
		objs[numObjs] = obj;
		numObjs++;
	}
	void Populate(Box boundingBox, SceneObject[] parentObjs)
	{
		int i;
		foreach(SceneObject obj; parentObjs)
		{
			if(obj.InBox(boundingBox))
				AddObj(obj);
		}
		objs.length = numObjs;
	}
	void Subdivide(Box boundingBox,int depth)
	{
		static int currAxis = 0;
		Box minBox, maxBox;

		left = new BSPNode(objs.length);
		right = new BSPNode(objs.length);

		//get axis and plane_pos
		currAxis++;
		currAxis %= 3;
		axis = currAxis;
		plane_pos = ((boundingBox.max.Component(axis) -
						   boundingBox.min.Component(axis)) / 2.0f)
						  + boundingBox.min.Component(axis);

		minBox = maxBox = boundingBox;
		minBox.max.ComponentSet(axis, plane_pos);
		maxBox.min.ComponentSet(axis, plane_pos);

		left.Populate(minBox, objs);
		right.Populate(maxBox, objs);

		//all your object belong to children now
		objs.length = 0;

		if(left.objs.length > scene.bspLeafObjs && depth < scene.bspDepth)
			left.Subdivide(minBox,depth+1);
		else
			left.isLeaf = true;
		if(right.objs.length > scene.bspLeafObjs && depth < scene.bspDepth)
			right.Subdivide(maxBox,depth+1);
		else
			right.isLeaf = true;
	}
	int axis;
	int numObjs;
	float plane_pos;
	bool isLeaf;
	BSPNode left, right;
	SceneObject[] objs;
}

class BSPTree : AccelStructure
{
	this()
	{
		root = new BSPNode(512);
		sceneBox.min.Set(SOL_TMAX, SOL_TMAX, SOL_TMAX);
		sceneBox.max.Set(-SOL_TMAX, -SOL_TMAX, -SOL_TMAX);
//		fwritef(stderr,"Using BSP Tree\n");
	}
	void AddObj(SceneObject obj)
	{
		obj.ExpandBox(sceneBox);
		root.AddObj(obj);
	}
	void Build()
	{
		int i;
//		fwritef(stderr,"Building BSP Tree (%d objects)... ", root.numObjs);
		root.objs.length = root.numObjs;
		foreach(SceneObject obj; root.objs)
			obj.PreCalc();
		root.Subdivide(sceneBox,0);
//		fprintf(stderr,"complete!\n");
	}
	bool Intersect(out HitInfo minHit, Ray ray, double tMin, double tMax)
	{
//		if(!sceneBox.Intersect(minHit,ray,-SOL_TMAX,SOL_TMAX))
//			return false;
		return root.Intersect(minHit,ray,tMin,tMax);
	}
	Box sceneBox;
	BSPNode root;
}
