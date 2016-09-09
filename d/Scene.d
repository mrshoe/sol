/*
 * Scene.d
 */

import std.math;
private import AccelStructure, Box, BSP, Camera, Image, Lights, Sol, Vector3;

struct HitInfo {
	double t;						// hit distance
	Vector3 P;						// hit point
	Vector3 N;						// hit surface normal
	char material;					// hit material
}

class Material {
	this() { diffuse = specular = 0.0f; }
	Vector3 color;
	float diffuse, specular;
}

// parent class to all primitives in the scene
class SceneObject {
	abstract bool Intersect(out HitInfo hit, Ray r, double tMin, double tMax);
	abstract void ExpandBox(inout Box box);
	abstract bool InBox(Box box);
	void PreCalc() {}
	void SetMaterial(int m) {
		material = cast(char)m;
	}
	char material;
}

abstract class ComplexSceneObject : SceneObject {
	abstract void Primitivize();
}

class Scene {
	this()
	{
		structure = new BSPTree();
		complexObjs.length = 8;
		gamma = 1.0;
		bspDepth = 10;
		bspLeafObjs = 5;
	}
	void AddObj(SceneObject newObj)
	{
		structure.AddObj(newObj);
	}
	void AddComplexObj(ComplexSceneObject newObj)
	{
		if(numComplexObjs >= (complexObjs.length - 1))
			complexObjs.length = complexObjs.length * 2;
		complexObjs[numComplexObjs] = newObj;
		numComplexObjs++;
	}
	void AddLight(Light newLight)
	{
		AddObj(newLight);
		lights.length = lights.length + 1;
		lights[length - 1] = newLight;
	}
	void Build()
	{
		complexObjs.length = numComplexObjs;
		foreach(ComplexSceneObject cObj; complexObjs)
			cObj.Primitivize();
		structure.Build();
	}
	void SetMaterials(Material ms[])
	{
		materials.length = ms.length;
		foreach(int i, Material m; ms)
			materials[i] = ms[i];
	}
	Material GetMaterial(int m)
	{
		return materials[m];
	}
	void Shade(out Vector3 pixel, HitInfo hit, Ray ray, int depth)
	{
		Vector3 toLight;
		Vector3 result;
		Vector3 tmpColor;
		HitInfo tmpHit;
		Ray tmpRay;
		if(depth > 3)
			return;
		
		foreach(Light currLight; lights)
		{
			// diffuse shader
			result.Set(GetMaterial(hit.material).color);
			toLight.Subtract(currLight.pos, hit.P);
			float lightDistSq = toLight.Mag2();
			float lightDist = sqrt(lightDistSq);
			float lightFalloff = 4*SOL_PI*lightDistSq / currLight.wattage;
			// normalize toLight
			toLight.Scale(1.0f/lightDist);
			// shadow ray
			tmpRay.o.Set(hit.P);
			tmpRay.d.Set(toLight);
			float diffuse;
			if(Trace(tmpRay,tmpHit, 0.001, lightDist))
				diffuse = 0.0f;
			else
				diffuse = hit.N.Dot(toLight);
			if(diffuse < 0.0f) diffuse = 0.0f;
			result.Scale(diffuse / lightFalloff);

			// specular shader
			if(GetMaterial(hit.material).specular > 0.0001)
			{
				tmpRay.o.Set(hit.P);
				tmpRay.d.Set(hit.N);
				tmpRay.d.Scale(-2.0f * ray.d.Dot(hit.N));
				if(Trace(tmpRay,tmpHit,0.001,SOL_TMAX))
					Shade(tmpColor,tmpHit,tmpRay,depth+1);
				else
					tmpColor.Set(bgColor);
				tmpColor.Scale(GetMaterial(hit.material).specular); 
				result.Add(tmpColor);
			}

			pixel.Add(result);
		}
	}
	bool Trace(Ray ray, out HitInfo minHit, double tMin, double tMax)
	{
		return structure.Intersect(minHit, ray, tMin, tMax);
	}
	void RayTrace()
	{
		Ray eyeRay;
		HitInfo minHit;
		int i,j;
		int pixOffs=0;
		Vector3 color;
		image.NextChunk();
		for(i = 0; i < image.h; i++)
		{
			for(j = 0; j < image.w; j++)
			{
				camera.EyeRay(eyeRay, image.x + j, image.y + i);
				if(Trace(eyeRay, minHit, 0.0, SOL_TMAX))
					Shade(color, minHit, eyeRay, 0); 
				else
					color.Set(bgColor);
				if(gamma != 1.0)
				{
					color.x = pow(color.x, gamma);
					color.y = pow(color.y, gamma);
					color.z = pow(color.z, gamma);
				}
				image.chunk[pixOffs++].Set(color);
			}
		}
	}

	void SetBGColor(Vector3 bg) { bgColor = bg; }
	void SetAccelStructure(AccelStructure s) { structure = s; }

	AccelStructure structure;
	ComplexSceneObject[] complexObjs;
	int numComplexObjs;
	Light[] lights;
	Material[] materials;
	Vector3 bgColor;
	float gamma;

	//BSP Tree config
	int bspLeafObjs, bspDepth;
}

Scene scene;
