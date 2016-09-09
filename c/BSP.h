/*
 * BSP.h
 */

#ifndef SOL_BSP_H
#define SOL_BSP_H

#include "Box.h"
#include "SceneObjects.h"
#include "Sol.h"

#define BSP_IS_LEAF(flags)			(((flags) & 0x3) == 0)
#define BSP_AXIS(flags)				(((flags) & 0x3) - 1)
#define BSP_SET_AXIS(flags,axis)	((flags) |= axis)
#define BSP_LAST_OBJ(obj)			(((int)obj) & 0x1)
#define BSP_X_AXIS					1
#define BSP_Y_AXIS					2
#define BSP_Z_AXIS					3
#define BSP_NUM_TRIAL_PLANES		9
#define BSP_COST_TRAVERSAL			1
#define BSP_COST_LEAF				8

typedef struct _BSPNode {
	float plane_pos;
	union {
		struct _BSPNode *left;
		SceneObject **objs;
	};
	struct _BSPNode *right;
	int numObjs;
	char isLeaf, axis;
} BSPNode;

void BSPNodeSubdivide(BSPNode *node, Box boundingBox,int depth);
int BSPNodeIntersect(BSPNode *node, HitInfo *minHit, Ray *ray, double tMin, double tMax);

/*
class BSPNode {
	public:
		BSPNode() {}
		~BSPNode() {}
		float SplitCost(Box &boundingBox, float split, int lObjs, int rObjs);
		void Subdivide(Box &boundingBox,int depth);
		void Project(Box &boundingBox,vector<ObjectProjection> &proj);
		int FindSplit(Box &boundingBox);
		int Intersect(HitInfo& minHit, const Ray& ray, double tMin, double tMax = MIRO_TMAX);
//		inline void PutObject(Object *o, int pos) { left[pos] = (BSPNode*)o; }
//		void ReallocObjs(int newLen) { left = realloc(newLen*sizeof(BSPNode*)); }
		//for root node only
		void AllocObjs() { left = (BSPNode*)new ObjectVector(); }

		inline float GetPos() { return plane_pos; }
		inline int IsLeaf() { return (((int)left & 3) == 0); }
		inline int GetAxis() { return ((int)left & 3); }
		inline BSPNode *GetLeft() const { return (BSPNode*)((int)left & (~3)); }
		inline BSPNode *GetRight() const { return &(GetLeft()[1]); }
		inline ObjectVector *GetObjs() const { return (ObjectVector*)(left); }
	private:
		float plane_pos;
		BSPNode *left;
};
*/

typedef struct _BSPTree {
	BSPNode *root;
	Box sceneBox;
	int maxDepth, leafObjs;
} BSPTree;

extern BSPTree bspTree;

void BSPTreeBuild();
int BSPTreeIntersect(HitInfo *minHit, Ray *ray, double tMin, double tMax);

#endif			//SOL_BSP_H
