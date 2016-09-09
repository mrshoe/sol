%{
#include <stdio.h>
#include <string.h>
#include "y.tab.h"

int yyline = 1;
%}

%option nounput
%option noyywrap
%option never-interactive

WS [ \t\r]*

%%
"#".*	{ /* eat comments */ }
{WS}	{ /* eat whitespace */ }

	/* strings */
\"[0-9A-Za-z_\.]+\" { yytext[strlen(yytext)-1]='\0'; yytext++; yylval.sVar=yytext; return STRING; }

	/* numbers */
"-"?[0-9]+ {  yylval.iVar=atoi(yytext); return I_VAL; }
"-"?[0-9]*("."[0-9]*)? {  yylval.fVar=atof(yytext); return F_VAL; }

	/* options */
options{WS} { return OPTIONS; }
width{WS} { return WIDTH; }
height{WS} { return HEIGHT; }
bgcolor{WS} { return BGCOLOR; }
bspdepth{WS} { return BSPDEPTH; }
bspleafobjs{WS} { return BSPLEAF; }

	/* materials */
material{WS} { return MATERIAL; }
color{WS} { return COLOR; }
diffuse{WS} { return DIFFUSE; }
specular{WS} { return SPECULAR; }

	/* camera */
camera{WS} { return CAMERA; }
pos{WS} { return POS; }
lookat{WS} { return LOOKAT; }
fov{WS} { return FOV; }
up{WS} { return UP; }

	/* lights */
pointlight{WS} { return POINTLIGHT; }
wattage{WS} { return WATTAGE; }

	/* spheres */
sphere{WS} { return SPHERE; }
center{WS} { return CENTER; }
radius{WS} { return RADIUS; }

	/* triangles */
triangle{WS} { return TRIANGLE; }
v1{WS} { return V1; }
v2{WS} { return V2; }
v3{WS} { return V3; }
n1{WS} { return N1; }
n2{WS} { return N2; }
n3{WS} { return N3; }

	/* meshes */
mesh{WS} { return MESH; }
load{WS} { return LOAD; }
scale{WS} { return SCALE; }
translate{WS} {return TRANSLATE; }

	/* other characters */
"\n" { yyline++; }
[\{\,\}]  { return (int)yytext[0]; }
.	{ printf("\nSyntax error line %d near: %s\n", yyline, yytext); }
%%
