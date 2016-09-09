/*
 * Triangle.c
 */

#include <stdlib.h>
#include <Accelerate/Accelerate.h>
#include "SceneObjects.h"
#include "Scene.h"
#include "Triangle.h"
#include "Sol.h"

Triangle *TriangleNew()
{
	Triangle *newTri = malloc(sizeof(Triangle));
	newTri->type = SCENE_OBJ_TRIANGLE;
	newTri->material = 0;
	return newTri;
}

int TriangleIntersect(SceneObject *obj, HitInfo *result, Ray *ray,
							double tMin, double tMax)
{
	Triangle *tri = (Triangle*)obj;
	//page 157 in shirleys' book explains this code
	//(see online errata for corrections)
	
	//used to interpolate normal
	Vector3 n1, n2, n3;
	//barycentric coords
	float alpha, B, G;
	float a = tri->v1.x - tri->v2.x;
	float b = tri->v1.y - tri->v2.y;
	float c = tri->v1.z - tri->v2.z;
	float d = tri->v1.x - tri->v3.x;
	float e = tri->v1.y - tri->v3.y;
	float f = tri->v1.z - tri->v3.z;
	float g = ray->d.x;
	float h = ray->d.y;
	float i = ray->d.z;
	float j = tri->v1.x - ray->o.x;
	float k = tri->v1.y - ray->o.y;
	float l = tri->v1.z - ray->o.z;
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

	result->t = t;
	result->P = ray->d;
	cblas_sscal(3, t, (float*)&(result->P), 1);
	V3AddTo(&(result->P), ray->o);
	alpha = (1.0f-B-G);
	n1 = tri->n1;
	n2 = tri->n2;
	n3 = tri->n3;
	cblas_sscal(3, alpha, (float*)&n1, 1);
	cblas_sscal(3, B, (float*)&n2, 1);
	cblas_sscal(3, G, (float*)&n3, 1);
	result->N = n1;
	V3AddTo(&(result->N), n2);
	V3AddTo(&(result->N), n3);
	V3Normalize(&(result->N));
	result->material = tri->material;
    return true;
}

void TriangleExpandBox(SceneObject *obj, Box *box)
{
	Triangle *tri = (Triangle*)obj;
	int i;
	float *boxCurr, *triCurr;

	for(i = 0; i < 3; i++)
	{
		// check the maxes
		boxCurr = V3Component(&(box->max), i);
		triCurr = V3Component(&(tri->v1), i);
		if(*triCurr > *boxCurr)
			*boxCurr = *triCurr;
		boxCurr = V3Component(&(box->max), i);
		triCurr = V3Component(&(tri->v2), i);
		if(*triCurr > *boxCurr)
			*boxCurr = *triCurr;
		boxCurr = V3Component(&(box->max), i);
		triCurr = V3Component(&(tri->v3), i);
		if(*triCurr > *boxCurr)
			*boxCurr = *triCurr;

		// check the mins
		boxCurr = V3Component(&(box->min), i);
		triCurr = V3Component(&(tri->v1), i);
		if(*triCurr < *boxCurr)
			*boxCurr = *triCurr;
		boxCurr = V3Component(&(box->min), i);
		triCurr = V3Component(&(tri->v2), i);
		if(*triCurr < *boxCurr)
			*boxCurr = *triCurr;
		boxCurr = V3Component(&(box->min), i);
		triCurr = V3Component(&(tri->v3), i);
		if(*triCurr < *boxCurr)
			*boxCurr = *triCurr;
	}
}

int TriangleOutsideBox(Triangle *tri, Box box)
{
	//see if all points are outside box
	if((tri->v1.x < box.min.x) && (tri->v2.x < box.min.x) &&
		(tri->v3.x < box.min.x))
		return true;
	if((tri->v1.x > box.max.x) && (tri->v2.x > box.max.x) &&
		(tri->v3.x > box.max.x))
		return true;
	if((tri->v1.y < box.min.y) && (tri->v2.y < box.min.y) &&
		(tri->v3.y < box.min.y))
		return true;
	if((tri->v1.y > box.max.y) && (tri->v2.y > box.max.y) &&
		(tri->v3.y > box.max.y))
		return true;
	if((tri->v1.z < box.min.z) && (tri->v2.z < box.min.z) &&
		(tri->v3.z < box.min.z))
		return true;
	if((tri->v1.z > box.max.z) && (tri->v2.z > box.max.z) &&
		(tri->v3.z > box.max.z))
		return true;
	return false;
}

int TriangleIntersectsBoxEdges(Triangle *tri, Box box)
{
	Ray triRay;
	HitInfo hi;
	//check each edge of the triangle
	triRay.o = tri->v1;
	V3Subtract(&(triRay.d), tri->v2, tri->v1);
	if(BoxIntersect(&box, &hi,&triRay,0,1))
		return true;
	V3Subtract(&(triRay.d), tri->v3, tri->v1);
	if(BoxIntersect(&box, &hi,&triRay,0,1))
		return true;
	triRay.o = tri->v2;
	V3Subtract(&(triRay.d), tri->v3, tri->v2);
	if(BoxIntersect(&box, &hi,&triRay,0,1))
		return true;
	return false;
}

int TriangleIntersectsBoxDiagonals(Triangle *tri, Box box)
{
	//b1 == box.m_vMin, t3 == box.m_vMax
	Vector3 b2, b3, b4, t1, t2, t4;
	Ray ray;
	HitInfo hi;

	ray.o = box.min;
	V3Subtract(&(ray.d), box.max, box.min);
	if(TriangleIntersect((SceneObject*)tri, &hi,&ray,0,1))
		return true;

	V3Set(&b2, box.max.x,box.min.y,box.min.z);
	V3Set(&t4, box.min.x,box.max.y,box.max.z);
	ray.o = b2;
	V3Subtract(&(ray.d), t4, b2);
	if(TriangleIntersect((SceneObject*)tri,&hi,&ray,0,1))
		return true;

	V3Set(&b3, box.max.x,box.min.y,box.max.z);
	V3Set(&t1, box.min.x,box.max.y,box.min.z);
	ray.o = b3;
	V3Subtract(&(ray.d), t1, b3);
	if(TriangleIntersect((SceneObject*)tri,&hi,&ray,0,1))
		return true;

	V3Set(&b4, box.min.x,box.min.y,box.max.z);
	V3Set(&t2, box.max.x,box.max.y,box.min.z);
	ray.o = b4;
	V3Subtract(&(ray.d), t2, b4);
	if(TriangleIntersect((SceneObject*)tri,&hi,&ray,0,1))
		return true;

	return false;
}

int TriangleInBox(SceneObject *obj, Box box)
{
	Triangle *tri = (Triangle*)obj;
	if(TriangleOutsideBox(tri, box))
		return false;
	//see if all points are inside box
	if(BoxContainsPoint(&box, tri->v1) && BoxContainsPoint(&box, tri->v2) &&
		BoxContainsPoint(&box, tri->v3))
		return true;
	if(TriangleIntersectsBoxEdges(tri, box))
		return true;

	//Check box diagonals vs. triangle
	return TriangleIntersectsBoxDiagonals(tri,box);
}

typedef struct {
	int x, y, z;
} TupleI3;

void get_indices(char *word, int *vindex, int *tindex, int *nindex)
{
    char *null = " ";
    char *ptr;
    char *tp;
    char *np;

    /* by default, the texture and normal pointers are set to the null string */

    tp = null;
    np = null;

    /* replace slashes with null characters and cause tp and np to point */
    /* to character immediately following the first or second slash */

    for (ptr = word; *ptr != '\0'; ptr++)
    {
        if (*ptr == '/')
        {
            if (tp == null)
                tp = ptr + 1;
            else
                np = ptr + 1;

            *ptr = '\0';
        }
    }

    *vindex = atoi (word);
    *tindex = atoi (tp);
    *nindex = atoi (np);
}
void LoadObj(char *filename, int material, Vector3 scale, Vector3 trans)
{
	FILE *fp = fopen(filename,"r");
    int nv=0, nt=0, nn=0, nf=0;
    char line[81];
    Vector3 *normals, *vertices, *texCoords = NULL, *texCoordIndices = NULL;
    TupleI3 *normalIndices, *vertexIndices;
	int numVerts, numTris;
    int nvertices = 0;
    int nnormals = 0;
    int ntextures = 0;
	char s1[32], s2[32], s3[32];
	int v, t, n, i;
	float x,y,z;
	Triangle *newTri;
    while ( fgets( line, 80, fp ) != NULL )
    {
        if (line[0] == 'v')
        {
            if (line[1] == 'n')
                nn++;
            else if (line[1] == 't')
                nt++;
            else
                nv++;
        }
        else if (line[0] == 'f')
        {
            nf++;
        }
    }
    fseek(fp, 0, 0);


    normals = (Vector3*)malloc(MAX(nv,nf) * sizeof(Vector3));
    vertices = (Vector3*)malloc(nv * sizeof(Vector3));
	numVerts = nv;

    if (nt)
    { // got texture coordinates
        texCoords = (Vector3*)malloc(nt*sizeof(Vector3));
        texCoordIndices = (Vector3*)malloc(nf*sizeof(Vector3));
    }
    normalIndices = (TupleI3*)malloc(nf*sizeof(TupleI3));
    vertexIndices = (TupleI3*)malloc(nf*sizeof(TupleI3));

    numTris = 0;

    while ( fgets( line, 80, fp ) != NULL )
    {
        if (line[0] == 'v')
        {
            if (line[1] == 'n')
            {
                sscanf( &line[2], "%f %f %f\n", &x, &y, &z);
                /********************** begin - Changed for Assignment 2 **********************/
                V3Set(&(normals[nnormals]),x,y,z);
                //m_pNormals[nnormals].Set(x, y, z); // old line
                /********************** end - Changed for Assignment 2 **********************/
                V3Normalize(&(normals[nnormals]));
                nnormals++;
            }
            else if (line[1] == 't')
            {
                sscanf( &line[2], "%f %f\n", &x, &y);
                texCoords[ntextures].x = x;
                texCoords[ntextures].y = y;
                ntextures++;
            }
            else
            {
                sscanf( &line[1], "%f %f %f\n", &x, &y, &z);
                /********************** begin - Changed for Assignment 2 **********************/
                V3Set(&(vertices[nvertices]),x,y,z);
				vertices[nvertices].x *= scale.x;
				vertices[nvertices].y *= scale.y;
				vertices[nvertices].z *= scale.z;
				V3AddTo(&(vertices[nvertices]), trans);
                // m_pVertices[nvertices].Set(x, y, z); // old line
                /********************** end - Changed for Assignment 2 **********************/
                nvertices++;
            }
        }
        else if (line[0] == 'f')
        {
            sscanf( &line[1], "%s %s %s\n", s1, s2, s3);

            get_indices(s1, &v, &t, &n);
            vertexIndices[numTris].x = v-1;
            if (n)
                normalIndices[numTris].x = n-1;
            if (t)
                texCoordIndices[numTris].x = t-1;
            get_indices(s2, &v, &t, &n);
            vertexIndices[numTris].y = v-1;
            if (n)
                normalIndices[numTris].y = n-1;
            if (t)
                texCoordIndices[numTris].y = t-1;
            get_indices(s3, &v, &t, &n);
            vertexIndices[numTris].z = v-1;
            if (n)
                normalIndices[numTris].z = n-1;
            if (t)
                texCoordIndices[numTris].z = t-1;

            if (!n)
            {   // if no normal was supplied
				Vector3 e1, e2;
				V3Subtract(&e1, vertices[vertexIndices[numTris].y],
								vertices[vertexIndices[numTris].x]);
				V3Subtract(&e2, vertices[vertexIndices[numTris].z],
								vertices[vertexIndices[numTris].x]);

                V3Cross(&(normals[nn]),e2,e1);
				cblas_sscal(3, -1, (float*)&(normals[nn]), 1);
                V3Normalize(&(normals[nn]));
                normalIndices[nn].x = nn;
                normalIndices[nn].y = nn;
                normalIndices[nn].z = nn;
                nn++;
            }

            numTris++;
        } //  else ignore line
    }
	//trianglify
	for(i = 0; i < numTris; i++)
	{
		newTri = (Triangle*)malloc(sizeof(Triangle));
		newTri->v1 = (vertices[vertexIndices[i].x]);
		newTri->v2 = (vertices[vertexIndices[i].y]);
		newTri->v3 = (vertices[vertexIndices[i].z]);
		newTri->n1 = (normals[normalIndices[i].x]);
		newTri->n2 = (normals[normalIndices[i].y]);
		newTri->n3 = (normals[normalIndices[i].z]);
		newTri->material = material;
		SceneAddObj((SceneObject*)newTri);
	}
}
