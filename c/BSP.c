/*
 * BSP.c
 */

#include "BSP.h"
#include "Scene.h"

int numLeaves;
int numObjs, totalObjs, maxObjs;
#define TINY 0.00001

// global bsp tree
BSPTree bspTree;

Array tmpObjs;

int BSPLeafNodeIntersect(BSPNode *node, HitInfo *minHit, Ray *ray, double tMin, double tMax)
{
	HitInfo tmpHit;
//	SceneObject *currObj;
	int i;
	int hit = false;
	minHit->t = tMax;

	// check for empty leaf node
	if(!(node->objs))
		return false;
	// intersect each obj
	for(i = 0; i < node->numObjs; i++)
	{
		if(IntersectFunc[(int)node->objs[i]->type](node->objs[i], &tmpHit, ray, tMin, tMax))
		{
			if(tmpHit.t < minHit->t)
				*minHit = tmpHit;
			hit = true;
		}
	}
	return hit;
}

int BSPInteriorNodeIntersect(BSPNode *node, HitInfo *minHit, Ray *ray, double tMin, double tMax)
{
	BSPNode *nearNode, *farNode;
	float t;
	float daxis;
	if((daxis=*V3Component(&(ray->d),node->axis)) > 0) {
		nearNode = node->left;
		farNode = node->right;
	}
	else {
		nearNode = node->right;
		farNode = node->left;
	}
	// plane intersection
	t = (node->plane_pos - *V3Component(&(ray->o),node->axis)) / daxis;
	if(t > tMax)
		return BSPNodeIntersect(nearNode,minHit,ray,tMin,tMax);
	else if(t < tMin)
		return BSPNodeIntersect(farNode,minHit,ray,tMin,tMax);
	else {
		if(BSPNodeIntersect(nearNode,minHit,ray,tMin,t))
			return true;
		else
			return BSPNodeIntersect(farNode,minHit,ray,t,tMax);
	}
}

int BSPNodeIntersect(BSPNode *node, HitInfo *minHit, Ray *ray, double tMin, double tMax)
{
	if(node->isLeaf)
		return BSPLeafNodeIntersect(node, minHit, ray, tMin, tMax);
	else
		return BSPInteriorNodeIntersect(node, minHit, ray, tMin, tMax);
}
#if 0
float BSPNode::SplitCost(Box &boundingBox, float split, int lObjs, int rObjs)
{
	Box leftBox = boundingBox, rightBox = boundingBox;
	leftBox.m_vMax[gCurrAxis] = split;
	rightBox.m_vMin[gCurrAxis] = split;
	/*
	return BSP_COST_LEAF * ((leftBox.SurfaceArea() * (float)lObjs) +
		   (rightBox.SurfaceArea() * (float)rObjs)) +
		   BSP_COST_TRAVERSAL * boundingBox.SurfaceArea();
	*/
	return ((leftBox.SurfaceArea() * (float)lObjs) +
		   (rightBox.SurfaceArea() * (float)rObjs));
}
void BSPNode::Project(Box &boundingBox, vector<ObjectProjection> &proj)
{
	ObjectProjection op;
	ObjectVector *objs = GetObjs();
	ObjectVector::iterator obj = objs->begin();
	for(int i = 0; i < objs->size(); i++)
	{
//		if(!(*obj)->GetMin(boundingBox,gCurrAxis,op.value))
			op.value = (*obj)->GetMin(gCurrAxis) - TINY;
		op.start = true;
		proj.push_back(op);
//		if(!(*obj)->GetMax(boundingBox,gCurrAxis,op.value))
			op.value = (*obj)->GetMax(gCurrAxis) + TINY;
		op.start = false;
		proj.push_back(op);
		obj++;
	}
}

int BSPNode::FindSplit(Box &boundingBox)
{
	// split down the middle
	/*
	static int res = 0;
	res = (res + 1) % 3;
	plane_pos = boundingBox.m_vMin[res] + (boundingBox.m_vMax[res] - boundingBox.m_vMin[res])/2.0f;
	*/

	vector<ObjectProjection> projObjs;
	int numLObjs, numRObjs;
	float minCost = MIRO_TMAX, cost;
//	int foo = false, foo1 = false;
	int axis = -1;//-res;
//	int finali = 0;
	for(gCurrAxis = 0; gCurrAxis < 3; gCurrAxis++)
	{
		projObjs.clear();
		Project(boundingBox,projObjs);
		sort(projObjs.begin(),projObjs.end());
		numLObjs = 0;
		numRObjs = GetObjs()->size();
		for(int i = 0; i < projObjs.size(); i++)
		{
//			foo1 = true;
			if(!(projObjs[i].start))
				numRObjs--;
			if(projObjs[i].value > boundingBox.m_vMin[gCurrAxis] &&
				projObjs[i].value < boundingBox.m_vMax[gCurrAxis])
			{
				cost = SplitCost(boundingBox,projObjs[i].value,numLObjs,numRObjs);
				if(cost < minCost)
				{
					plane_pos = projObjs[i].value;
					minCost = cost;
					axis = gCurrAxis;
//					foo = true;
//					finali = i;
				}
			}
			if(projObjs[i].start)
				numLObjs++;
		}
	}
//	if(!foo) printf("bahhh\n");
//	if(!foo1) printf("double bahhh\n");
//	printf("%d\n",finali);
	return axis;
}
#endif

int BSPNodePopulate(BSPNode *node, Box boundingBox,
		SceneObject **parentObjs, int numParentObjs)
{
	int i, numChildObjs;
	SceneObject *currObj;
	tmpObjs.length = 0;
	for(i = 0; i < numParentObjs; i++)
	{
		currObj = parentObjs[i];
		if(InBoxFunc[(int)currObj->type](currObj, boundingBox))
			ArrayInsert(&tmpObjs, (void*)currObj);
	}
	numChildObjs = tmpObjs.length;
	if(numChildObjs > 0)
		node->objs = malloc(numChildObjs*sizeof(SceneObject*));
	else
		node->objs = NULL;			// empty leaf
	for(i = 0; i < numChildObjs; i++)
		node->objs[i] = (SceneObject*)tmpObjs.data[i];
	return numChildObjs;
}

void BSPNodeSubdivide(BSPNode *node, Box boundingBox,int depth)
{
	SceneObject **parentObjs = node->objs;
	static int axis = 0;
	Box minBox, maxBox;

	node->left = calloc(1,sizeof(BSPNode));
	node->right = calloc(1,sizeof(BSPNode));

	//get axis and plane_pos
	axis++;
	axis %= 3;
	node->axis = axis;
	node->plane_pos = ((*V3Component(&(boundingBox.max),axis) -
					   *V3Component(&(boundingBox.min),axis)) / 2.0f)
					  +*V3Component(&(boundingBox.min),axis);

	minBox = maxBox = boundingBox;
	*V3Component(&(minBox.max), axis) = node->plane_pos;
	*V3Component(&(maxBox.min), axis) = node->plane_pos;

	node->left->numObjs = BSPNodePopulate(node->left, minBox, parentObjs, node->numObjs);
	node->right->numObjs = BSPNodePopulate(node->right, maxBox, parentObjs, node->numObjs);
	
	//all objects belong to children now
	free(parentObjs);

	if(node->left->numObjs > bspTree.leafObjs && depth < bspTree.maxDepth)
		BSPNodeSubdivide(node->left,minBox,depth+1);
	else
		node->left->isLeaf = 1;
	if(node->right->numObjs > bspTree.leafObjs && depth < bspTree.maxDepth)
		BSPNodeSubdivide(node->right,maxBox,depth+1);
	else
		node->right->isLeaf = 1;
}

void BSPTreeBuild()
{
	int i;
	fprintf(stderr,"Building BSP Tree... ");
	V3Set(&(bspTree.sceneBox.min),SOL_TMAX,SOL_TMAX,SOL_TMAX);
	V3Set(&(bspTree.sceneBox.max),-SOL_TMAX,-SOL_TMAX,-SOL_TMAX);
	bspTree.root = calloc(1,sizeof(BSPNode));
	bspTree.root->objs = malloc(scene.objs.length*sizeof(SceneObject*));
	for(i = 0; i < scene.objs.length; i++)
	{
		bspTree.root->objs[i] = (SceneObject*)scene.objs.data[i];
		ExpandBoxFunc[(int)bspTree.root->objs[i]->type](bspTree.root->objs[i],
														&(bspTree.sceneBox));
	}
	ArrayInit(&tmpObjs, scene.objs.length);
	bspTree.root->numObjs = numObjs = scene.objs.length;
	numLeaves = totalObjs = maxObjs = 0;
	BSPNodeSubdivide(bspTree.root, bspTree.sceneBox,0);
	fprintf(stderr,"complete!\n");
}

int BSPTreeIntersect(HitInfo *minHit, Ray *ray, double tMin, double tMax)
{
//	sceneBox.m_vMin.Print();
//	sceneBox.m_vMax.Print();
//	float tmin=tMin,tmax=tMax;
	if(!BoxIntersect(&(bspTree.sceneBox),minHit,ray,-SOL_TMAX,SOL_TMAX))
		return false;
//	tmin = minHit.t;
//	if(!sceneBox.Intersect(minHit,ray,tmin,tMax))
//		return false;
//	tmax = minHit.t;
	return BSPNodeIntersect(bspTree.root,minHit,ray,tMin,tMax);
}
