import std.file;
import std.c.stdio;
import std.c.stdlib;
import std.regexp;
private import Scene, Triangle, Vector3;

//void get_indices(char[] word, out int vindex, out int tindex, out int nindex);

struct TupleI3 {
	int x, y, z;
}

class TriangleMesh : ComplexSceneObject {
	this()
	{
		scale.Set(1,1,1);
	}
	void SetScale(Vector3 s) { scale = s; }
	void SetTranslate(Vector3 t) { trans = t;}
	bool Intersect(out HitInfo hit, Ray r, double tMin, double tMax)
	{
		return false;
	}
	void ExpandBox(inout Box box) {}
	bool InBox(Box box) { return false; }
	void Primitivize()
	{
		Triangle newTri;
		for(int i = 0; i < vertexIndices.length; i++)
		{
//			fwritef(stderr, "%d\n", i);
//			fwritef(stderr, "%d %d %d\n", normalIndices[i].x, normalIndices[i].y, normalIndices[i].z);
			newTri = new Triangle();
			newTri.SetMaterial(material);
			newTri.SetV1(vertices[vertexIndices[i].x]);
			newTri.SetV2(vertices[vertexIndices[i].y]);
			newTri.SetV3(vertices[vertexIndices[i].z]);
			newTri.SetN1(normals[normalIndices[i].x]);
			newTri.SetN2(normals[normalIndices[i].y]);
			newTri.SetN3(normals[normalIndices[i].z]);
			scene.AddObj(newTri);
		}
	}
	void AddVert(Vector3 newVert)
	{
		if(numVerts >= (vertices.length - 1))
		{
//			fwritef(stderr,"realloc\n");
			vertices.length = vertices.length * 2;
		}
		vertices[numVerts] = newVert;
		numVerts++;
	}
	void AddNormal(Vector3 newNorm)
	{
		if(numNormals >= (normals.length - 1))
			normals.length = normals.length * 2;
		normals[numNormals] = newNorm;
		numNormals++;
	}
	void AddVertIndex(TupleI3 newI3)
	{
		if(numVertIndicies >= (vertexIndices.length - 1))
			vertexIndices.length = vertexIndices.length * 2;
		vertexIndices[numVertIndicies] = newI3;
		numVertIndicies++;
	}
	void AddNormalIndex(TupleI3 newI3)
	{
		if(numNormalIndicies >= (normalIndices.length - 1))
			normalIndices.length = normalIndices.length * 2;
		normalIndices[numNormalIndicies] = newI3;
		numNormalIndicies++;
	}
	void LoadObj(char[] filename)
	{
//		fwritef(stderr,"Loading %s... ", filename);
//		RegExp vertExp = new RegExp(r"v\s+(-?\d+\.?\d*)\s(-?\d+\.?\d*)\s(-?\d+\.?\d*)","");
//		RegExp normExp = new RegExp(r"vn\s+(-?\d+\.?\d*)\s(-?\d+\.?\d*)\s(-?\d+\.?\d*)","");
		RegExp faceExp = new RegExp(r"f\s+(\d+)/(\d*)/(\d*)\s+(\d+)/(\d*)/(\d*)\s+(\d+)/(\d*)/(\d*)","");
		char[][] lines = split(cast(char[])read(filename),"\n");
//		fwritef(stderr,"split ");
		Vector3 newV3;
		TupleI3 newI3;
		normals.length = 512;
		vertices.length = 512;
		normalIndices.length = 512;
		vertexIndices.length = 512;
		int lineno = 0;
		float x,y,z;
		int v1,v2,v3, n1,n2,n3, t1,t2,t3;
		char[][] matches;
		foreach(char[] line; lines)
		{
			if((++lineno % 100) == 0)
//				fwritef(stderr,"%d\n",lineno);
			if(line.length < 2)
				continue;
			switch(line[0..2])
			{
				case "v ":
		//			sscanf(line, "v %f %f %f", &x, &y, &z);
					matches = split(line," ");
					newV3.Set(atof(cast(char*)matches[1]),atof(cast(char*)matches[2]),atof(cast(char*)matches[3]));
					AddVert(newV3);
					break;
				case "vn":
//					sscanf(line, "vn %f %f %f", &x, &y, &z);
					matches = split(line," ");
					matches = split(line," ");
					newV3.Set(atof(cast(char*)matches[1]),atof(cast(char*)matches[2]),atof(cast(char*)matches[3]));
					AddNormal(newV3);
					break;
				case "f ":
					matches = faceExp.match(line);
					newI3.x = atoi(cast(char*)matches[1])-1;
					newI3.y = atoi(cast(char*)matches[4])-1;
					newI3.z = atoi(cast(char*)matches[7])-1;
					AddVertIndex(newI3);

					if(matches[3].length == 0)		//no normals
					{
						Vector3 e1, e2;
						e1.Subtract(vertices[newI3.y],vertices[newI3.x]);
						e2.Subtract(vertices[newI3.z],vertices[newI3.x]);
						newV3.Cross(e1,e2);
						newV3.Normalize();
						newI3.x = newI3.y = newI3.z = numNormals;
						AddNormalIndex(newI3);
						AddNormal(newV3);
					}
					else
					{
						newI3.x = atoi(cast(char*)matches[3])-1;
						newI3.y = atoi(cast(char*)matches[6])-1;
						newI3.z = atoi(cast(char*)matches[9])-1;
						AddNormalIndex(newI3);
					}
					break;
				case "g ":
//					fwritef(stderr,"%s\n",line);
					break;
				default:
					break;
			}
			/*
			if(vertExp.find(line) == 0)
			{
				matches = vertExp.match(line);
				newV3.Set(atof(matches[1]),atof(matches[2]),atof(matches[3]));
				AddVert(newV3);
			}
			else if(normExp.find(line) == 0)
			{
				matches = normExp.match(line);
				newV3.Set(atof(matches[1]),atof(matches[2]),atof(matches[3]));
				newV3.Normalize();
				AddNormal(newV3);
			}
			else if(faceExp.find(line) == 0)
			{
				matches = faceExp.match(line);
				newI3.x = atoi(matches[1])-1;
				newI3.y = atoi(matches[4])-1;
				newI3.z = atoi(matches[7])-1;
				AddVertIndex(newI3);

				if(matches[3].length == 0)		//no normals
				{
					Vector3 e1, e2;
					e1.Subtract(vertices[newI3.y],vertices[newI3.x]);
					e2.Subtract(vertices[newI3.z],vertices[newI3.x]);
					newV3.Cross(e1,e2);
					newV3.Normalize();
					newI3.x = newI3.y = newI3.z = numNormals;
					AddNormalIndex(newI3);
					AddNormal(newV3);
				}
				else
				{
					newI3.x = atoi(matches[3])-1;
					newI3.y = atoi(matches[6])-1;
					newI3.z = atoi(matches[9])-1;
					AddNormalIndex(newI3);
				}
			}
			else
			{
//				fwritef(stderr, "unknown line: %s\n", line);
			}
			*/
		}
		normals.length = numNormals;
		vertices.length = numVerts;
		normalIndices.length = numNormalIndicies;
		vertexIndices.length = numVertIndicies;
//		fwritef(stderr,"done. ");
	}
	int numNormals, numVerts, numVertIndicies, numNormalIndicies;
	Vector3[] normals, vertices;
	TupleI3[] normalIndices, vertexIndices;
	Vector3 trans, scale;
}
