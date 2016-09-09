%{
#include <stdio.h>
#include <string.h>
#include "BSP.h"
#include "Camera.h"
#include "Lights.h"
#include "Scene.h"
#include "SceneObjects.h"
#include "Sphere.h"
#include "Triangle.h"

Triangle *currTri;
Sphere *currSphere;
PointLight *currPointLight;
int numMaterials;
char *matNames[SCENE_MAX_MATERIALS];
int currMaterial;
Vector3 currScale, currTrans;

extern int yyparse();
extern int yylex();
extern FILE *yyin;
extern char *yytext;
extern int yyline;

void ParseFile(FILE *sceneFile)
{
	yyin = sceneFile;
	numMaterials = 0;
	yyparse();
}

void AddMaterial(char *name)
{
	if(numMaterials == SCENE_MAX_MATERIALS)
	{
		SolError();
		fprintf(stderr,"Too many materials \"%s\", max is %d.\n",name,numMaterials);
	}
	matNames[numMaterials] = malloc(strlen(name)+1);
	strcpy(matNames[numMaterials],name);
}

int MaterialByName(char *name)
{
	int i;
	for(i = 0; i < numMaterials; i++)
		if(strcmp(matNames[i],name) == 0)
			return i;
	SolError();
	fprintf(stderr,"Unknown material name \"%s\".\n", name);
	return 0;
}

void yyerror(const char *str)
{
	printf("%s: line %d near %s\n", str, yyline, yytext);
}

int yywrap()
{
	return 1;
} 

%}

%union
{
	float fVar;
	int iVar;
	char *sVar;
}

/* strings */
%token <sVar> STRING

/* numbers */
%token <fVar> F_VAL
%token <iVar> I_VAL

/* options */
%token OPTIONS
%token WIDTH
%token HEIGHT
%token BGCOLOR
%token BSPDEPTH
%token BSPLEAF

/* materials */
%token MATERIAL
%token COLOR
%token DIFFUSE
%token SPECULAR

/* camera */
%token CAMERA
%token POS
%token LOOKAT
%token FOV
%token UP

/* lights */
%token POINTLIGHT
%token WATTAGE

/* spheres */
%token SPHERE
%token CENTER
%token RADIUS

/* triangles */
%token TRIANGLE
%token V1
%token V2
%token V3
%token N1
%token N2
%token N3

/* meshes */
%token MESH
%token LOAD
%token SCALE
%token TRANSLATE

%type <fVar> fVal
%type <iVar> iVal

%%

scene: /* empty */
	| scene section
	;

section:
	  options
	| camera
	| light
	| material
	| object
	;

options: OPTIONS '{' settings '}';

settings:	/* empty */
	| WIDTH iVal settings
		{ scene.width = $2; }
	| HEIGHT iVal settings
		{ scene.height = $2; }
	| BGCOLOR fVal ',' fVal ',' fVal settings
		{ V3Set(&(scene.bgColor), $2, $4, $6); }
	| BSPDEPTH iVal settings
		{ bspTree.maxDepth = $2; }
	| BSPLEAF iVal settings
		{ bspTree.leafObjs = $2; }
	;

camera: CAMERA '{' cameraOptions '}';

cameraOptions: /* empty */
	| POS fVal ',' fVal ',' fVal cameraOptions
		{ V3Set(&(cam.eye), $2, $4, $6); }
	| LOOKAT fVal ',' fVal ',' fVal cameraOptions
		{ V3Set(&(cam.lookAt), $2, $4, $6); }
	| FOV iVal cameraOptions
		{ cam.fov = $2; }
	| UP fVal ',' fVal ',' fVal cameraOptions
		{ V3Set(&(cam.up), $2, $4, $6); }
	;

light:
	POINTLIGHT '{'
	{
		currPointLight = PointLightNew();
		SceneAddLight((Light*)currPointLight);
	} pointLightOptions '}';

pointLightOptions: /* empty */
	| POS fVal ',' fVal ',' fVal pointLightOptions
		{ V3Set(&(currPointLight->pos), $2, $4, $6); }
	| WATTAGE iVal pointLightOptions
		{ currPointLight->wattage = $2; }
	| COLOR fVal ',' fVal ',' fVal pointLightOptions
		{ V3Set(&(currPointLight->color), $2, $4, $6); }
	;

material: MATERIAL STRING { AddMaterial($2); } '{' materialOptions '}'
			{ numMaterials++; };

materialOptions: /* empty */
	| COLOR fVal ',' fVal ',' fVal materialOptions
		{ V3Set(&(scene.materials[numMaterials].color), $2, $4, $6); }
	| DIFFUSE fVal materialOptions
		{ scene.materials[numMaterials].diffuse = $2; }
	| SPECULAR fVal materialOptions
		{ scene.materials[numMaterials].specular = $2; }
	;

object:
	  triangle
	| sphere
	| mesh
	;

sphere: SPHERE '{'
	{
		currSphere = SphereNew();
		SceneAddObj((SceneObject*)currSphere);
	} sphereOptions '}';

sphereOptions: /* empty */
	| CENTER fVal ',' fVal ',' fVal sphereOptions
		{ V3Set(&(currSphere->center), $2, $4, $6); }
	| RADIUS fVal sphereOptions
		{ currSphere->radius = $2; }
	| MATERIAL STRING
		{ currSphere->material = MaterialByName($2); } sphereOptions
	;

triangle:
	TRIANGLE '{'
	{
		/* add object to scene here */
		currTri = TriangleNew();
		SceneAddObj((SceneObject*)currTri);
	} triangleOptions '}'
	;

triangleOptions: /* empty */
	| V1 fVal ',' fVal ',' fVal
		{ V3Set(&(currTri->v1), $2, $4, $6); } triangleOptions
	| V2 fVal ',' fVal ',' fVal
		{ V3Set(&(currTri->v2), $2, $4, $6); } triangleOptions
	| V3 fVal ',' fVal ',' fVal
		{ V3Set(&(currTri->v3), $2, $4, $6); } triangleOptions
	| N1 fVal ',' fVal ',' fVal
		{ V3Set(&(currTri->n1), $2, $4, $6); } triangleOptions
	| N2 fVal ',' fVal ',' fVal
		{ V3Set(&(currTri->n2), $2, $4, $6); } triangleOptions
	| N3 fVal ',' fVal ',' fVal
		{ V3Set(&(currTri->n3), $2, $4, $6); } triangleOptions
	| MATERIAL STRING
		{ currTri->material = MaterialByName($2); } triangleOptions
	;

mesh: 
	MESH '{' { V3Set(&currScale,1,1,1); V3Set(&currTrans,0,0,0); }
		meshOptions meshLoad'}'
	;

meshOptions: /* empty */
	| MATERIAL STRING { currMaterial = MaterialByName($2); } meshOptions
	| SCALE fVal ',' fVal ',' fVal { V3Set(&currScale,$2,$4,$6); } meshOptions
	| TRANSLATE fVal ',' fVal ',' fVal { V3Set(&currTrans,$2,$4,$6); } meshOptions
	;	

meshLoad: /* empty */
	| LOAD STRING
		{ LoadObj($2, currMaterial, currScale, currTrans); }
	;

fVal:
	  F_VAL { $$ = $1; }
	| iVal { $$ = (float) $1; }
	;

iVal: I_VAL { $$ = $1; } ;
