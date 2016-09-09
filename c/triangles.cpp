#include "miro.h"
#include "Camera.h"
#include "Image.h"
#include "Scene.h"
#include "Subsurface.h"
#include "BSP.h"

#ifndef max
#define max(a,b) ((a>b)?a:b)
#endif

#define MAX_PHOTONS		200

void Triangle::RenderGL()
{
    // Mike Bailey's simple way to fake "lighting" to make triangles more visible
    Vector3 m_vE1 = m_vV2 - m_vV1;
    Vector3 m_vE2 = m_vV3 - m_vV1;
    Vector3 color = m_vE1*m_vE2;
    color.Normalize();
    color.y = fabs(color.y);
    color.y += .25;
    if(color.y > 1.)
        color.y = 1.;
    color = Vector3(color.y, color.y, color.y);
    glColor3f(color.y, color.y, color.y);
    glBegin(GL_TRIANGLES);
    glVertex3fv(&(m_vV1.x));
    glVertex3fv(&(m_vV2.x));
    glVertex3fv(&(m_vV3.x));
    glEnd();
}

void TriangleMesh::RenderGL()
{
    glColor3f(1, 1, 1);
    // use vertex buffers
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(3, GL_FLOAT, 0, m_pVertices);
    glDrawElements(GL_TRIANGLES, 3*m_iNumTris, GL_UNSIGNED_INT,
                   m_pVertexIndices);
    glDisableClientState(GL_VERTEX_ARRAY);
}

void Triangle::Rasterize(Camera *cam, Image *img)
{
    // TODO, your code from assignment 1 goes here
}

void TriangleMesh::Rasterize(Camera *cam, Image *img)
{
    // TODO, your code from assignment 1 goes here
}

/********************** begin - New for Assignment 2 **********************/
bool Triangle::Intersect(HitInfo& result, const Ray& ray,
                         double tMin/* = 0.0*/, double tMax/* = MIRO_TMAX*/)
{
    // TODO, write triangle intersection code here
    // Using the provided ray, calculate the closest intersection point 
    // such that tMin <= t <= tMax. Fill in the result HitInfo with the
    // hit distance, hit location and surface normal at the hit location. 
    // This, along with TriangleMesh::Intersect, implements Task 3 and 4
	//page 157 in the book explains this code (see online errata for corrections)
	
	//mailboxing first
	if(ray.id == lastRay)
	{
		if(lastResult)
			result = lastHit;
		return lastResult;
	}
	objIntersections++;
	lastRay = ray.id;
	float a = m_vV1.x - m_vV2.x;
	float b = m_vV1.y - m_vV2.y;
	float c = m_vV1.z - m_vV2.z;
	float d = m_vV1.x - m_vV3.x;
	float e = m_vV1.y - m_vV3.y;
	float f = m_vV1.z - m_vV3.z;
	float g = ray.d.x;
	float h = ray.d.y;
	float i = ray.d.z;
	float j = m_vV1.x - ray.o.x;
	float k = m_vV1.y - ray.o.y;
	float l = m_vV1.z - ray.o.z;
	float ei_hf = e*i - h*f;
	float gf_di = g*f - d*i;
	float dh_eg = d*h - e*g;
	float M = a*ei_hf + b*gf_di + c*dh_eg;

	float t = -((f*(a*k-j*b) + e*(j*c-a*l) + d*(b*l-k*c))/M);
	if(t < tMin || t > tMax)
		return lastResult = false;
	float B = (j*ei_hf + k*gf_di + l*dh_eg)/M;
	if(B < 0.0f || B > 1.0f)
		return lastResult = false;
	float G = (i*(a*k-j*b) + h*(j*c-a*l) + g*(b*l-k*c))/M;
	if(G < 0.0f || G > (1.0f-B))
		return lastResult = false;

//	result.color.Set(0.0f,0.0f,1.0f);
	result.t = t;
	result.P = ray.d;
	result.P *= t;
	result.P += ray.o;
	float alpha = (1.0f-B-G);
	result.N = (alpha*m_vN1) + (B*m_vN2) + (G*m_vN3);
	result.N.Normalize();
	result.mat = material;
	if(GetTextured())
	{
		result.mat.color.x = (alpha*GetT1().x) + (B*GetT2().x) + (G*GetT3().x);
		result.mat.color.y = (alpha*GetT1().y) + (B*GetT2().y) + (G*GetT3().y);
		result.mat.color.z = (alpha*GetT1().z) + (B*GetT2().z) + (G*GetT3().z);
	}
	lastHit = result;
    return lastResult = true;
}

void Triangle::ExpandBox(Box &box)
{
	for(int i = 0; i < 3; i++)
	{
		if(m_vV1[i] < box.m_vMin[i])
			box.m_vMin[i] = m_vV1[i];
		if(m_vV2[i] < box.m_vMin[i])
			box.m_vMin[i] = m_vV2[i];
		if(m_vV3[i] < box.m_vMin[i])
			box.m_vMin[i] = m_vV3[i];

		if(m_vV1[i] > box.m_vMax[i])
			box.m_vMax[i] = m_vV1[i];
		if(m_vV2[i] > box.m_vMax[i])
			box.m_vMax[i] = m_vV2[i];
		if(m_vV3[i] > box.m_vMax[i])
			box.m_vMax[i] = m_vV3[i];
	}
}

bool Triangle::IsInBox(Box &box)
{
	//see if all points are outside box
	if((GetV1().x < box.GetMin().x) && (GetV2().x < box.GetMin().x) &&
		(GetV3().x < box.GetMin().x))
		return false;
	if((GetV1().x > box.GetMax().x) && (GetV2().x > box.GetMax().x) &&
		(GetV3().x > box.GetMax().x))
		return false;
	if((GetV1().y < box.GetMin().y) && (GetV2().y < box.GetMin().y) &&
		(GetV3().y < box.GetMin().y))
		return false;
	if((GetV1().y > box.GetMax().y) && (GetV2().y > box.GetMax().y) &&
		(GetV3().y > box.GetMax().y))
		return false;
	if((GetV1().z < box.GetMin().z) && (GetV2().z < box.GetMin().z) &&
		(GetV3().z < box.GetMin().z))
		return false;
	if((GetV1().z > box.GetMax().z) && (GetV2().z > box.GetMax().z) &&
		(GetV3().z > box.GetMax().z))
		return false;
	//see if all points are inside box
	if(box.ContainsPoint(GetV1()) && box.ContainsPoint(GetV2()) &&
		box.ContainsPoint(GetV3()))
		return true;

	//check each edge of the triangle
	Ray triRay;
	HitInfo hi;
	triRay.o = GetV1();
	triRay.d = GetV2() - GetV1();
	triRay.id = g_pScene->GetNextRayID();
	if(box.Intersect(hi,triRay,0,1))
		return true;
	triRay.d = GetV3() - GetV1();
	triRay.id = g_pScene->GetNextRayID();
	if(box.Intersect(hi,triRay,0,1))
		return true;
	triRay.o = GetV2();
	triRay.d = GetV3() - GetV2();
	triRay.id = g_pScene->GetNextRayID();
	if(box.Intersect(hi,triRay,0,1))
		return true;
	//Check box diagonals vs. triangle
	return IntersectsDiagonals(box);
}

bool Triangle::IntersectsDiagonals(Box &box)
{
	//b1 == box.m_vMin, t3 == box.m_vMax
	Vector3 b2, b3, b4, t1, t2, t4;
	Ray ray;
	HitInfo hi;

	ray.o = box.m_vMin;
	ray.d = box.m_vMax - box.m_vMin;
	ray.id = g_pScene->GetNextRayID();
	if(Intersect(hi,ray,0,1))
		return true;

	b2.Set(box.m_vMax.x,box.m_vMin.y,box.m_vMin.z);
	t4.Set(box.m_vMin.x,box.m_vMax.y,box.m_vMax.z);
	ray.o = b2;
	ray.d = t4 - b2;
	ray.id = g_pScene->GetNextRayID();
	if(Intersect(hi,ray,0,1))
		return true;

	b3.Set(box.m_vMax.x,box.m_vMin.y,box.m_vMax.z);
	t1.Set(box.m_vMin.x,box.m_vMax.y,box.m_vMin.z);
	ray.o = b3;
	ray.d = t1 - b3;
	ray.id = g_pScene->GetNextRayID();
	if(Intersect(hi,ray,0,1))
		return true;

	b4.Set(box.m_vMin.x,box.m_vMin.y,box.m_vMax.z);
	t2.Set(box.m_vMax.x,box.m_vMax.y,box.m_vMin.z);
	ray.o = b4;
	ray.d = t2 - b4;
	ray.id = g_pScene->GetNextRayID();
	if(Intersect(hi,ray,0,1))
		return true;

	return false;
}

bool Triangle::GetMin(Box &bound, int axis, float &result)
{
	bool resultExists = false;
	Vector3 boundMin = bound.GetMin(), boundMax = bound.GetMax();
	Ray ray;
	int currAxis;
	float t, temp;
	//first see if the object has an edge inside the bound
	temp = GetMin(axis);
	if(temp > boundMin[axis] && temp < boundMax[axis])
	{
		result = temp;
		return true;
	}
	// check the other two axes
	for(int i = 1; i < 3; i++)
	{
		currAxis = (axis + i) % 3;
		// check the three edges against max and min planes of this axis
		ray.o = m_vV1;
		ray.d = m_vV2 - m_vV1;
		for(int edge = 0; edge < 3; edge++)
		{
			if(edge == 1) ray.d = m_vV3 - m_vV1;
			if(edge == 2) { ray.o = m_vV2; ray.d = m_vV3 - m_vV2; }
			t = (boundMin[currAxis] - ray.o[currAxis]) / ray.d[currAxis];
			for(int j = 0; j < 2; j++)
			{
				if(t > 0.0f && t < 1.0f)
				{
					temp = ray.d[axis];
					temp *= t;
					temp += ray.o[axis];
					if((!resultExists || temp < result ) &&
						(temp > boundMin[axis] && temp < boundMax[axis]))
					{
						result = temp;
						resultExists = true;
					}
				}
				t = (boundMax[currAxis] - ray.o[currAxis]) / ray.d[currAxis];
			}
		}
	}
	return resultExists;
}
bool Triangle::GetMax(Box &bound, int axis, float &result)
{
	bool resultExists = false;
	Vector3 boundMin = bound.GetMin(), boundMax = bound.GetMax();
	Ray ray;
	int currAxis;
	float t, temp;
	//first see if the object has an edge inside the bound
	temp = GetMax(axis);
	if(temp > boundMin[axis] && temp < boundMax[axis])
	{
		result = temp;
		return true;
	}
	// check the other two axes
	for(int i = 1; i < 3; i++)
	{
		currAxis = (axis + i) % 3;
		// check the three edges against max and min planes of this axis
		ray.o = m_vV1;
		ray.d = m_vV2 - m_vV1;
		for(int edge = 0; edge < 3; edge++)
		{
			if(edge == 1) ray.d = m_vV3 - m_vV1;
			if(edge == 2) { ray.o = m_vV2; ray.d = m_vV3 - m_vV2; }
			t = (boundMin[currAxis] - ray.o[currAxis]) / ray.d[currAxis];
			for(int j = 0; j < 2; j++)
			{
				if(t > 0.0f && t < 1.0f)
				{
					temp = ray.d[axis];
					temp *= t;
					temp += ray.o[axis];
					if((!resultExists || temp > result ) &&
						(temp > boundMin[axis] && temp < boundMax[axis]))
					{
						result = temp;
						resultExists = true;
					}
				}
				t = (boundMax[currAxis] - ray.o[currAxis]) / ray.d[currAxis];
			}
		}
	}
	return resultExists;
}
float Triangle::GetMin(int axis)
{
	float result = m_vV1[axis];
	if(m_vV2[axis] < result) result = m_vV2[axis];
	if(m_vV3[axis] < result) result = m_vV3[axis];
	return result;
}
float Triangle::GetMax(int axis)
{
	float result = m_vV1[axis];
	if(m_vV2[axis] > result) result = m_vV2[axis];
	if(m_vV3[axis] > result) result = m_vV3[axis];
	return result;
}

bool TriangleMesh::Intersect(HitInfo& result, const Ray& ray,
                             double tMin/* = 0.0*/, double tMax/* = MIRO_TMAX*/)
{
    // TODO, write triangle mesh intersection code here
    // Using the provided ray, calculate the closest intersection point 
    // such that tMin <= t <= tMax. Fill in the result HitInfo with the
    // hit distance, hit location and surface normal at the hit location. 
    // This, along with Triangle::Intersect, implements Task 3 and 4
	HitInfo hi;
	Triangle currTriangle;
	int triIndex;
	float red, green, blue;
	bool hit = false;
	result.t = tMax + 1.0f;
	TupleI3 *triVerts, *triNorms;

	printf("you should never see this!\n");
	for(triIndex = 0; triIndex < (m_iNumTris); triIndex++)
	{
		triVerts = &(m_pVertexIndices[triIndex]);
		triNorms = &(m_pNormalIndices[triIndex]);
		currTriangle.SetV1(m_pVertices[triVerts->x]);
		currTriangle.SetV2(m_pVertices[triVerts->y]);
		currTriangle.SetV3(m_pVertices[triVerts->z]);
		currTriangle.SetN1(m_pNormals[triNorms->x]);
		currTriangle.SetN2(m_pNormals[triNorms->y]);
		currTriangle.SetN3(m_pNormals[triNorms->z]);
		if(currTriangle.Intersect(hi,ray,tMin,tMax) && hi.t < result.t)
		{
			hit = true;
			result = hi;
		}
	}
//	result.color.Set(0.0f,1.0f,0.0f);
	result.mat = material;
    return hit;
}
/********************** end - New for Assignment 2 **********************/

TriangleMesh::TriangleMesh()
{
    m_pNormals = 0;
    m_pVertices = 0;
    m_pTexCoords = 0;
    m_pNormalIndices = 0;
    m_pVertexIndices = 0;
    m_pTexCoordIndices = 0;
}

TriangleMesh::~TriangleMesh()
{
    delete [] m_pNormals;
    delete [] m_pVertices;
    delete [] m_pTexCoords;
    delete [] m_pNormalIndices;
    delete [] m_pVertexIndices;
    delete [] m_pTexCoordIndices;
}

void TriangleMesh::Trianglify(ObjectVector *objs)
{
	Triangle *newTri;
	if(material.subsurfaceSD > 0.0f)
		m_pTexCoords = new Vector3[m_iNumVerts];
	for(int i = 0; i < m_iNumTris; i++)
	{
		newTri = new Triangle();
		newTri->SetV1(m_pVertices[m_pVertexIndices[i].x]);
		newTri->SetV2(m_pVertices[m_pVertexIndices[i].y]);
		newTri->SetV3(m_pVertices[m_pVertexIndices[i].z]);
		newTri->SetN1(m_pNormals[m_pNormalIndices[i].x]);
		newTri->SetN2(m_pNormals[m_pNormalIndices[i].y]);
		newTri->SetN3(m_pNormals[m_pNormalIndices[i].z]);
		newTri->SetTextured(false);
		if(material.subsurfaceSD > 0.0f)
		{
			newTri->SetT1(m_pTexCoords[m_pVertexIndices[i].x]);
			newTri->SetT2(m_pTexCoords[m_pVertexIndices[i].y]);
			newTri->SetT3(m_pTexCoords[m_pVertexIndices[i].z]);
			newTri->SetTextured(true);
		}
		else if(m_pTexCoords) {
			newTri->SetT1(m_pTexCoords[m_pTexCoordIndices[i].x]);
			newTri->SetT2(m_pTexCoords[m_pTexCoordIndices[i].y]);
			newTri->SetT3(m_pTexCoords[m_pTexCoordIndices[i].z]);
			newTri->SetTextured(true);
		}
		newTri->SetColor(material.color);
		newTri->SetDiffuse(material.diffuse);
		newTri->SetSpecular(material.specular);
		newTri->SetShininess(material.shininess);
		newTri->SetSubsurfaceSD(material.subsurfaceSD);
		objs->push_back(newTri);
	}
}

void TriangleMesh::ExpandBox(Box &box)
{
	for(int vertIndex = 0; vertIndex < (m_iNumVerts); vertIndex++)
	{
		if(m_pVertices[vertIndex].x < box.m_vMin.x)
			box.m_vMin.x = m_pVertices[vertIndex].x;
		if(m_pVertices[vertIndex].y < box.m_vMin.y)
			box.m_vMin.y = m_pVertices[vertIndex].y;
		if(m_pVertices[vertIndex].z < box.m_vMin.z)
			box.m_vMin.z = m_pVertices[vertIndex].z;

		if(m_pVertices[vertIndex].x > box.m_vMax.x)
			box.m_vMax.x = m_pVertices[vertIndex].x;
		if(m_pVertices[vertIndex].y > box.m_vMax.y)
			box.m_vMax.y = m_pVertices[vertIndex].y;
		if(m_pVertices[vertIndex].z > box.m_vMax.z)
			box.m_vMax.z = m_pVertices[vertIndex].z;
	}
}
bool TriangleMesh::Load(char* file, const Matrix4x4& ctm)
{
    FILE *fp = fopen( file, "rb" );
    if (!fp)
    {
        Error("Cannot open \"%s\" for reading\n",file);
        return false;
    }
    Debug("Loading \"%s\"...\n", file);

    LoadObj(fp, ctm);
    Debug("Loaded \"%s\" with %d triangles\n",file,m_iNumTris);
    fclose(fp);

    return true;
}

//build the photon map used for subsurface scattering estimate
void TriangleMesh::BuildSSPhotonMap()
{
	//turn off specularness, but we'll restore it later
	bool old_spec_hilights = g_pScene->spec_hilights;
	bool old_spec_reflection = g_pScene->spec_reflection;
	g_pScene->spec_hilights = false;
	g_pScene->spec_reflection = false;
	int i;
	//i don't think photon direction matters here
	Vector3 dir(0.0f,1.0f,0.0f);
	Vector3 pos, power;
	//Scene::Shade doesn't need any ray info for diffuse calculations
	Ray fakeRay;
	//Scene::Shade needs hit.P, hit.N, hit.mat for diffuse calculations
	HitInfo fakeHit;
	fakeHit.mat = material;
	//we just want a diffuse shader
	fakeHit.mat.subsurfaceSD = -1.0f;

	//keep track of which verts have already been shaded
	bool *shaded = (bool*)calloc(m_iNumVerts,sizeof(bool));
	//make the photon map
	photonMap = new Photon_map(m_iNumVerts);
	//for each vert
	for(i = 0; i < m_iNumTris; i++)
	{
		int *currVerts = (int*)&(m_pVertexIndices[i].x);
		int *currNorms = (int*)&(m_pNormalIndices[i].x);
		for(int j = 0; j < 3; j++)
		{
			if(shaded[currVerts[j]])
				continue;
			shaded[currVerts[j]] = true;
			//calculate photon radiance by shading this point
			fakeHit.P = m_pVertices[currVerts[j]];
			fakeHit.N = m_pNormals[currNorms[j]];
			pos = m_pVertices[currVerts[j]];
			power = g_pScene->Shade(fakeRay,fakeHit,0);
			//insert photon into map
			photonMap->store((const float*)power.p(),(const float*)pos.p(),(const float*)dir.p());
		}
	}
	free(shaded);
	//restore old specular settings
	g_pScene->spec_hilights = old_spec_hilights;
	g_pScene->spec_reflection = old_spec_reflection;

	photonMap->balance();
}

//cheap hack: cache these values
float lastSSD = 0.0f;
float dist2, gaussianExpDenominator, gaussianDenominator;
void TriangleMesh::GaussianRadianceBlur(BSPNode *bspNode)
{
	if(!bspNode->IsLeaf())
	{
		GaussianRadianceBlur(bspNode->GetLeft());
		GaussianRadianceBlur(bspNode->GetRight());
		return;
	}
	//setup the NearestPhotons structure
	NearestPhotons np;
	np.dist2 = (float*)alloca(sizeof(float)*(MAX_PHOTONS+1));
	np.index = (const Photon**)alloca(sizeof(Photon*)*(MAX_PHOTONS+1));
	np.max = MAX_PHOTONS;

	//use tex coords as radiance
	//for each object
	ObjectVector::iterator it;
	for (it = bspNode->GetObjs()->begin(); it != bspNode->GetObjs()->end(); it++)
	{
		Object* pObject = *it;
		//i use blurred to keep track of if this object has been blurred
		if(!pObject->IsTriangle() || pObject->blurred|| pObject->material.subsurfaceSD <= 0.0f)
			continue;
		pObject->blurred = true;
		Triangle *tri = (Triangle*)pObject;
		//some pre-calculations
		if(tri->material.subsurfaceSD != lastSSD)
		{
			dist2 = 4.0f*tri->material.subsurfaceSD*tri->material.subsurfaceSD;
			gaussianExpDenominator = 2.0f*tri->material.subsurfaceSD*tri->material.subsurfaceSD;
			gaussianDenominator = tri->material.subsurfaceSD*SQRT_2_PI;
			lastSSD = tri->material.subsurfaceSD;
		}
		Vector3 *currVert=&(tri->m_vV1), *currTex=&(tri->m_vT1);
		for(int i = 0; i < 3; i++)
		{
			if(i==1) { currVert=&(tri->m_vV2); currTex=&(tri->m_vT2); }
			if(i==2) { currVert=&(tri->m_vV3); currTex=&(tri->m_vT3); }
			float totalGaussian = 0.0f;
			currTex->SetZero();
			np.found = 0;
			np.got_heap = 0;
			np.pos[0] = currVert->x; np.pos[1] = currVert->y; np.pos[2] = currVert->z;
			np.dist2[0] = dist2;
			//find all photons within 2*sd
			photonMap->locate_photons(&np, 1);
			//set radiance to sum of all photons' radiance
			//scaled by the gaussian function factor
			Vector3 radiance,loc;
			for(int j = 1; j <= np.found; j++)
			{
				const Photon *p = np.index[j];
				radiance.Set(p->power[0],p->power[1],p->power[2]);
				loc.Set(p->pos[0],p->pos[1],p->pos[2]);
				float dist;
				if(loc == *currVert)
					dist = 0.0f;
				else
				{
					loc -= *currVert;
					dist = loc.NormSq();
				}
				float gaussianFactor = expf(-dist/gaussianExpDenominator) /
											gaussianDenominator;
				totalGaussian += gaussianFactor;
				radiance *= gaussianFactor;
				*currTex += radiance;
			}
			*currTex /= totalGaussian;
		}
	}
}
void TriangleMesh::SubsurfaceScatter(BSPTree &bsp)
{
	//all we're doing here is subsurface scattering stuff
	if(material.subsurfaceSD == 0.0f)
		return;
	BuildSSPhotonMap();
	GaussianRadianceBlur(bsp.GetRoot());
}
void TriangleMesh::PreCalc()
{
	if(material.subsurfaceSD > 0.0f)
	{
		//no support for textures and ss
		if(m_pTexCoords)
			delete [] m_pTexCoords;
		m_pTexCoords = new Vector3[m_iNumVerts];
	}
}

//************************************************************************
// You probably don't want to modify the following functions
// They are for loading .obj files
//************************************************************************

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


void TriangleMesh::LoadObj(FILE* fp, const Matrix4x4& ctm)
{
    int nv=0, nt=0, nn=0, nf=0;
    char line[81];
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


    m_pNormals = new Vector3[max(nv,nf)];
    m_pVertices = new Vector3[nv];
	m_iNumVerts = nv;

    if (nt)
    { // got texture coordinates
        m_pTexCoords = new Vector3[nt];
        m_pTexCoordIndices = new TupleI3[nf];
    }
    m_pNormalIndices = new TupleI3[nf]; // always make normals
    m_pVertexIndices = new TupleI3[nf]; // always have vertices

    m_iNumTris = 0;
    int nvertices = 0;
    int nnormals = 0;
    int ntextures = 0;

    Matrix4x4 nctm = ctm;
    nctm.Invert();
    nctm.MakeTranspose();
    nctm.Invert();

    while ( fgets( line, 80, fp ) != NULL )
    {
        if (line[0] == 'v')
        {
            if (line[1] == 'n')
            {
                float x, y, z;
                sscanf( &line[2], "%f %f %f\n", &x, &y, &z);
                /********************** begin - Changed for Assignment 2 **********************/
                Vector3 n(x, y, z);
                m_pNormals[nnormals] = nctm*n;
                //m_pNormals[nnormals].Set(x, y, z); // old line
                /********************** end - Changed for Assignment 2 **********************/
                m_pNormals[nnormals].Normalize();
                nnormals++;
            }
            else if (line[1] == 't')
            {
                float x, y;
                sscanf( &line[2], "%f %f\n", &x, &y);
                m_pTexCoords[ntextures].x = x;
                m_pTexCoords[ntextures].y = y;
                ntextures++;
            }
            else
            {
                float x, y, z;
                sscanf( &line[1], "%f %f %f\n", &x, &y, &z);
                /********************** begin - Changed for Assignment 2 **********************/
                Vector3 v(x, y, z);
                m_pVertices[nvertices] = ctm*v;
                m_pVertices[nvertices] *= m_fScale;
                // m_pVertices[nvertices].Set(x, y, z); // old line
                /********************** end - Changed for Assignment 2 **********************/
                nvertices++;
            }
        }
        else if (line[0] == 'f')
        {
            char s1[32], s2[32], s3[32];
            int v, t, n;
            sscanf( &line[1], "%s %s %s\n", s1, s2, s3);

            get_indices(s1, &v, &t, &n);
            m_pVertexIndices[m_iNumTris].x = v-1;
            if (n)
                m_pNormalIndices[m_iNumTris].x = n-1;
            if (t)
                m_pTexCoordIndices[m_iNumTris].x = t-1;
            get_indices(s2, &v, &t, &n);
            m_pVertexIndices[m_iNumTris].y = v-1;
            if (n)
                m_pNormalIndices[m_iNumTris].y = n-1;
            if (t)
                m_pTexCoordIndices[m_iNumTris].y = t-1;
            get_indices(s3, &v, &t, &n);
            m_pVertexIndices[m_iNumTris].z = v-1;
            if (n)
                m_pNormalIndices[m_iNumTris].z = n-1;
            if (t)
                m_pTexCoordIndices[m_iNumTris].z = t-1;

            if (!n)
            {   // if no normal was supplied
                Vector3 e1 = m_pVertices[m_pVertexIndices[m_iNumTris].y] -
                             m_pVertices[m_pVertexIndices[m_iNumTris].x];
                Vector3 e2 = m_pVertices[m_pVertexIndices[m_iNumTris].z] -
                             m_pVertices[m_pVertexIndices[m_iNumTris].x];

                m_pNormals[nn] = -(e2*e1);
                m_pNormals[nn].Normalize();
                m_pNormalIndices[nn].x = nn;
                m_pNormalIndices[nn].y = nn;
                m_pNormalIndices[nn].z = nn;
                nn++;
            }

            m_iNumTris++;
        } //  else ignore line
    }
}

