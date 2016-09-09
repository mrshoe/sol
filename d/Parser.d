/*
 * Parser.d
 */

import std.regexp;
import std.c.stdlib;
import std.file;
import std.stdio;
private import BSP, Camera, Image, Lights, Scene, Sphere, Triangle, TriangleMesh, Vector3;

enum TokenType {
	OPTIONS,		//options section
	WIDTH,
	HEIGHT,
	BGCOLOR,
	GAMMA,
	BSPTREE,
	DEPTH,
	LEAFOBJS,
	MATERIAL,		//material section
	NAME,
	COLOR,
	DIFFUSE,
	SPECULAR,
	CAMERA,			//camera section
	POS,
	LOOKAT,
	FOV,
	UP,
	POINTLIGHT,		//point light section
	WATTAGE,
	SPHERE,			//sphere section
	CENTER,
	RADIUS,
	TRIANGLE,		//triangle section
	V1, V2, V3, N1, N2, N3,
	MESH,			//mesh section
	LOAD,
	SCALE,
	TRANSLATE,
	LCURLY,
	RCURLY,
	STRING,
	FLOAT,
	INT,
}

class Token {
	char[] sVal;
	int iVal;
	float fVal;
	TokenType type;
}

// extend this with 'special' match tokens
class MatchToken {
	this(TokenType type, char[] regexp)
	{
		this.type = type;
		exp = new RegExp(regexp,"i");
	}
	bool Match(Token t)
	{
		if(exp.match(t.sVal))
		{
			t.type = type;
			return true;
		}
		return false;
	}
	RegExp exp;
	TokenType type;
}

class IntMatchToken : MatchToken {
	this(TokenType type, char[] regexp) { super(type,regexp); }
	bool Match(Token t)
	{
		if(super.Match(t))
		{
			t.iVal = atoi(cast(char*)t.sVal);
			t.fVal = cast(float)t.iVal;
			return true;
		}
		return false;
	}
}

class FloatMatchToken : MatchToken {
	this(TokenType type, char[] regexp) { super(type,regexp); }
	bool Match(Token t)
	{
		if(super.Match(t))
		{
			t.fVal = atof(cast(char*)t.sVal);
			return true;
		}
		return false;
	}
}

class Lexer {
	this(char[] filename)
	{
		//split on whitespace and comments
		//RegExp whiteSpace = new RegExp(r"[ \t\v\r\n\f]+(#[^\n]*\n)*[ \t\v\r\n\f]*","");
		RegExp whiteSpace = new RegExp(r"[ \t\v\r\n\f,]+","");
		tokenStrings = whiteSpace.split(sub(cast(char[])read(filename),r"#[^\n]*\n","","ig"));
		tokenStrings.length = tokenStrings.length - 1;
		// TODO: new match tokens here
		matchTokens[TokenType.STRING] = new MatchToken(TokenType.STRING, "\".+\"");
		matchTokens[TokenType.FLOAT] = new FloatMatchToken(TokenType.FLOAT, r"-?\d*\.\d*");
		matchTokens[TokenType.INT] = new IntMatchToken(TokenType.INT, r"-?\d+");
		matchTokens[TokenType.OPTIONS] = new MatchToken(TokenType.OPTIONS, "options");
		matchTokens[TokenType.WIDTH] = new MatchToken(TokenType.WIDTH, "width");
		matchTokens[TokenType.HEIGHT] = new MatchToken(TokenType.HEIGHT, "height");
		matchTokens[TokenType.BGCOLOR] = new MatchToken(TokenType.BGCOLOR, "bgcolor");
		matchTokens[TokenType.GAMMA] = new MatchToken(TokenType.GAMMA, "gamma");
		matchTokens[TokenType.BSPTREE] = new MatchToken(TokenType.BSPTREE, "bsptree");
		matchTokens[TokenType.DEPTH] = new MatchToken(TokenType.DEPTH, "depth");
		matchTokens[TokenType.LEAFOBJS] = new MatchToken(TokenType.LEAFOBJS, "leafobjs");
		matchTokens[TokenType.MATERIAL] = new MatchToken(TokenType.MATERIAL, "material");
		matchTokens[TokenType.NAME] = new MatchToken(TokenType.NAME, "name");
		matchTokens[TokenType.COLOR] = new MatchToken(TokenType.COLOR, "color");
		matchTokens[TokenType.DIFFUSE] = new MatchToken(TokenType.DIFFUSE, "diffuse");
		matchTokens[TokenType.SPECULAR] = new MatchToken(TokenType.SPECULAR, "specular");
		matchTokens[TokenType.CAMERA] = new MatchToken(TokenType.CAMERA, "camera");
		matchTokens[TokenType.POS] = new MatchToken(TokenType.POS, "pos");
		matchTokens[TokenType.LOOKAT] = new MatchToken(TokenType.LOOKAT, "lookat");
		matchTokens[TokenType.FOV] = new MatchToken(TokenType.FOV, "fov");
		matchTokens[TokenType.UP] = new MatchToken(TokenType.UP, "up");
		matchTokens[TokenType.POINTLIGHT] = new MatchToken(TokenType.POINTLIGHT, "pointlight");
		matchTokens[TokenType.WATTAGE] = new MatchToken(TokenType.WATTAGE, "wattage");
		matchTokens[TokenType.SPHERE] = new MatchToken(TokenType.SPHERE, "sphere");
		matchTokens[TokenType.CENTER] = new MatchToken(TokenType.CENTER, "center");
		matchTokens[TokenType.RADIUS] = new MatchToken(TokenType.RADIUS, "radius");
		matchTokens[TokenType.TRIANGLE] = new MatchToken(TokenType.TRIANGLE, "triangle");
		matchTokens[TokenType.V1] = new MatchToken(TokenType.V1, "v1");
		matchTokens[TokenType.V2] = new MatchToken(TokenType.V2, "v2");
		matchTokens[TokenType.V3] = new MatchToken(TokenType.V3, "v3");
		matchTokens[TokenType.N1] = new MatchToken(TokenType.N1, "n1");
		matchTokens[TokenType.N2] = new MatchToken(TokenType.N2, "n2");
		matchTokens[TokenType.N3] = new MatchToken(TokenType.N3, "n3");
		matchTokens[TokenType.MESH] = new MatchToken(TokenType.MESH, "mesh");
		matchTokens[TokenType.LOAD] = new MatchToken(TokenType.LOAD, "load");
		matchTokens[TokenType.SCALE] = new MatchToken(TokenType.SCALE, "scale");
		matchTokens[TokenType.TRANSLATE] = new MatchToken(TokenType.TRANSLATE, "translate");
		matchTokens[TokenType.LCURLY] = new MatchToken(TokenType.LCURLY, "{");
		matchTokens[TokenType.RCURLY] = new MatchToken(TokenType.RCURLY, "}");
	}
	Token NextToken()
	{
		token = new Token();
		if(currToken == tokenStrings.length)
			return null;
		token.sVal = tokenStrings[currToken++];
		//fwritef(stderr,"%s\n",token.sVal);
		for(int i = 0; i <= TokenType.max; i++)
			if(matchTokens[i].Match(token))
				return token;
		throw new Error("Invalid token \""~token.sVal~"\"");
		return null;		//should never be reached
	}
	Token PreviousToken()
	{
		return token;
	}
	MatchToken[TokenType.max+1] matchTokens;
	char[][] tokenStrings;
	int currToken;
	Token token;
}

class SectionHandler {
	void Init() {}
	abstract bool ParseSection(Lexer lex);
	Vector3 ParseVector3(Lexer lex)
	{
		Vector3 result;
		Token tmp;
		if(!((tmp = lex.NextToken()) is null) &&
			  (tmp.type == TokenType.FLOAT || tmp.type == TokenType.INT))
			result.x = tmp.fVal;
		if(!((tmp = lex.NextToken()) is null) &&
			  (tmp.type == TokenType.FLOAT || tmp.type == TokenType.INT))
			result.y = tmp.fVal;
		if(!((tmp = lex.NextToken()) is null) &&
			  (tmp.type == TokenType.FLOAT || tmp.type == TokenType.INT))
			result.z = tmp.fVal;
		return result;
	}
//	this can be used to make sure required params are specified
//	bool Exit() {}
}

class OptionsHandler : SectionHandler {
	bool ParseSection(Lexer lex)
	{
		Token currToken, tmp;
		while(!((currToken = lex.NextToken()) is null) && currToken.sVal != "}")
		{
			switch(currToken.type)
			{
				case TokenType.WIDTH:
					if(((tmp = lex.NextToken()) is null) ||
						  tmp.type != TokenType.INT)
						return false;
					image.SetWidth(tmp.iVal);
					break;
				case TokenType.HEIGHT:
					if(((tmp = lex.NextToken()) is null) ||
						  tmp.type != TokenType.INT)
						return false;
					image.SetHeight(tmp.iVal);
					break;
				case TokenType.BGCOLOR:
					Vector3 bg = ParseVector3(lex);
					scene.SetBGColor(bg);
					break;
				case TokenType.GAMMA:
					if(((tmp = lex.NextToken()) is null) ||
						  (tmp.type != TokenType.INT && tmp.type != TokenType.FLOAT))
						return false;
					scene.gamma = 1.0/tmp.fVal;
					break;
				default:
					return false;
			}
		}
		return true;
	}
}

class BSPTreeHandler : SectionHandler {
	bool ParseSection(Lexer lex)
	{
		scene.structure = new BSPTree();
		Token currToken, tmp;
		while(!((currToken = lex.NextToken()) is null) && currToken.sVal != "}")
		{
			switch(currToken.type)
			{
				case TokenType.DEPTH:
					if((tmp = lex.NextToken()) is null ||
						tmp.type != TokenType.INT)
						return false;
					scene.bspDepth = tmp.iVal;
					break;
				case TokenType.LEAFOBJS:
					if((tmp = lex.NextToken()) is null ||
						tmp.type != TokenType.INT)
						return false;
					scene.bspLeafObjs = tmp.iVal;
					break;
			}
		}
		return true;
	}
}
class CameraHandler : SectionHandler {
	bool ParseSection(Lexer lex)
	{
		Token currToken, tmp;
		while(!((currToken = lex.NextToken()) is null) && currToken.sVal != "}")
		{
			switch(currToken.type)
			{
				case TokenType.POS:
					Vector3 pos = ParseVector3(lex);
					camera.SetPos(pos);
					break;
				case TokenType.LOOKAT:
					Vector3 lookat = ParseVector3(lex);
					camera.SetLookAt(lookat);
					break;
				case TokenType.UP:
					Vector3 up = ParseVector3(lex);
					camera.SetUp(up);
					break;
				case TokenType.FOV:
					if((tmp = lex.NextToken()) is null ||
						tmp.type != TokenType.INT)
						return false;
					camera.SetFOV(tmp.iVal);
					break;
			}
		}
		return true;
	}
}

// global material stuff for parser
Material[char[]] materials;
int GetMaterialIndex(char[] name)
{
	foreach(int i, char[] s; materials.keys)
	{
		if(name == s)
			return i;
	}
	throw new Error("Unknown material: "~name);
}
void SaveMaterials()
{
	scene.SetMaterials(materials.values);
}

class MaterialHandler : SectionHandler {
	bool ParseSection(Lexer lex)
	{
		Material newMat = new Material();
		Token currToken, tmp;
		while(!((currToken = lex.NextToken()) is null) && currToken.sVal != "}")
		{
			switch(currToken.type)
			{
				case TokenType.NAME:
					if((tmp = lex.NextToken()) is null ||
						tmp.type != TokenType.STRING)
						return false;
					materials[tmp.sVal] = newMat;
					break;
				case TokenType.DIFFUSE:
					if((tmp = lex.NextToken()) is null ||
						(tmp.type != TokenType.FLOAT && tmp.type != TokenType.INT))
						return false;
					newMat.diffuse = tmp.fVal;
					break;
				case TokenType.SPECULAR:
					if((tmp = lex.NextToken()) is null ||
						(tmp.type != TokenType.FLOAT && tmp.type != TokenType.INT))
						return false;
					newMat.specular = tmp.fVal;
					break;
				case TokenType.COLOR:
					Vector3 color = ParseVector3(lex);
					newMat.color = color;
					break;
			}
		}
		return true;
	}
}

class PointLightHandler : SectionHandler {
	bool ParseSection(Lexer lex)
	{
		PointLight newLight = new PointLight();
		Token currToken, tmp;
		while(!((currToken = lex.NextToken()) is null) && currToken.sVal != "}")
		{
			switch(currToken.type)
			{
				case TokenType.WATTAGE:
					if((tmp = lex.NextToken()) is null ||
						tmp.type != TokenType.INT)
						return false;
					newLight.SetWattage(tmp.iVal);
					break;
				case TokenType.COLOR:
					Vector3 color = ParseVector3(lex);
					newLight.SetColor(color);
					break;
				case TokenType.POS:
					Vector3 pos = ParseVector3(lex);
					newLight.SetPos(pos);
					break;
			}
		}
		scene.AddLight(newLight);
		return true;
	}
}

class SphereHandler : SectionHandler {
	bool ParseSection(Lexer lex)
	{
		Sphere newSphere = new Sphere();
		Token currToken, tmp;
		while(!((currToken = lex.NextToken()) is null) && currToken.sVal != "}")
		{
			switch(currToken.type)
			{
				case TokenType.RADIUS:
					if((tmp = lex.NextToken()) is null ||
						(tmp.type != TokenType.FLOAT && tmp.type != TokenType.INT))
						return false;
					newSphere.SetRadius(tmp.fVal);
					break;
				case TokenType.CENTER:
					Vector3 center = ParseVector3(lex);
					newSphere.SetCenter(center);
					break;
				case TokenType.MATERIAL:
					if((tmp = lex.NextToken()) is null ||
						tmp.type != TokenType.STRING)
						return false;
					newSphere.SetMaterial(GetMaterialIndex(tmp.sVal));
					break;
			}
		}
		scene.AddObj(newSphere);
		return true;
	}
}

class TriangleHandler : SectionHandler {
	bool ParseSection(Lexer lex)
	{
		Triangle newTri = new Triangle();
		Token currToken, tmp;
		while(!((currToken = lex.NextToken()) is null) && currToken.sVal != "}")
		{
			switch(currToken.type)
			{
				case TokenType.V1:
					Vector3 v = ParseVector3(lex);
					newTri.SetV1(v);
					break;
				case TokenType.V2:
					Vector3 v = ParseVector3(lex);
					newTri.SetV2(v);
					break;
				case TokenType.V3:
					Vector3 v = ParseVector3(lex);
					newTri.SetV3(v);
					break;
				case TokenType.N1:
					Vector3 v = ParseVector3(lex);
					newTri.SetN1(v);
					break;
				case TokenType.N2:
					Vector3 v = ParseVector3(lex);
					newTri.SetN2(v);
					break;
				case TokenType.N3:
					Vector3 v = ParseVector3(lex);
					newTri.SetN3(v);
					break;
				case TokenType.MATERIAL:
					if((tmp = lex.NextToken()) is null ||
						tmp.type != TokenType.STRING)
						return false;
					newTri.SetMaterial(GetMaterialIndex(tmp.sVal));
					break;
				default:
					return false;
			}
		}
		scene.AddObj(newTri);
		return true;
	}
}

class MeshHandler : SectionHandler {
	bool ParseSection(Lexer lex)
	{
		TriangleMesh newMesh = new TriangleMesh();
		scene.AddComplexObj(newMesh);
		Token currToken, tmp;
		while(!((currToken = lex.NextToken()) is null) && currToken.sVal != "}")
		{
			switch(currToken.type)
			{
				case TokenType.SCALE:
					Vector3 v = ParseVector3(lex);
					newMesh.SetScale(v);
					break;
				case TokenType.TRANSLATE:
					Vector3 v = ParseVector3(lex);
					newMesh.SetTranslate(v);
					break;
				case TokenType.LOAD:
					if((tmp = lex.NextToken()) is null ||
						tmp.type != TokenType.STRING)
						return false;
					newMesh.LoadObj(tmp.sVal[1..length-1]);
					break;
				case TokenType.MATERIAL:
					if((tmp = lex.NextToken()) is null ||
						tmp.type != TokenType.STRING)
						return false;
					newMesh.SetMaterial(GetMaterialIndex(tmp.sVal));
					break;
				default:
					return false;
			}
		}
		return true;
	}
}

class Parser {
	this()
	{
		sectionHandlers[TokenType.OPTIONS] = new OptionsHandler();
		sectionHandlers[TokenType.BSPTREE] = new BSPTreeHandler();
		sectionHandlers[TokenType.CAMERA] = new CameraHandler();
		sectionHandlers[TokenType.MATERIAL] = new MaterialHandler();
		sectionHandlers[TokenType.POINTLIGHT] = new PointLightHandler();
		sectionHandlers[TokenType.TRIANGLE] = new TriangleHandler();
		sectionHandlers[TokenType.SPHERE] = new SphereHandler();
		sectionHandlers[TokenType.MESH] = new MeshHandler();
	}
	void ParseFile(char[] filename)
	{
		Lexer lex = new Lexer(filename);
		Token currToken,tmp;
		while(!((currToken = lex.NextToken()) is null) &&
			  !((tmp = lex.NextToken()) is null))
		{
			if(tmp.type != TokenType.LCURLY)
				throw new Error("Missing '{' near "~currToken.sVal);
			if((currToken.type in sectionHandlers) != null)
			{
				if(!sectionHandlers[currToken.type].ParseSection(lex))
					throw new Error("Parse error near "~lex.PreviousToken().sVal~" in "~currToken.sVal~" section.\n");
			}
			else
				throw new Error("Unkown section: "~currToken.sVal);
		}
		SaveMaterials();
	}
	SectionHandler[int] sectionHandlers;
}
