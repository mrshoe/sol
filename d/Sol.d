/*
 * Sol.d
 */

//console text colors
/*
#define TEXT_NORMAL   "\033[0m"
#define TEXT_RED   "\033[1;31m"
#define TEXT_GREEN "\033[1;32m"
#define TEXT_PINK "\033[1;35m"
*/

import std.stdio;
import std.c.stdlib;
private import Parser;

const double SOL_PI =			3.1415926535897932384626433832795028841972;
const double SOL_TMAX =		1e12;
float MIN(float x,float y) { return (x < y) ? x : y; }
int MIN(int x,int y) { return (x < y) ? x : y; }
float MAX(float x,float y) { return (x > y) ? x : y; }
int MAX(int x,int y) { return (x > y) ? x : y; }

void SolError()
{
//	fprintf(stderr,TEXT_RED"Error:\n\t"TEXT_NORMAL);
	fwritef(stderr,"Error:\n\t");
}

void SolDebug()
{
//	fprintf(stderr,TEXT_GREEN"Debug: "TEXT_NORMAL);
	fwritef(stderr,"Debug: ");
}

bool SolInit(char[][] args)
{
	if(args.length < 2)
	{
		fwritef(stderr,"Usage:\n\t%s scenefile\n",args[0]);
		return false;
	}
	Parser p = new Parser();
	p.ParseFile(args[1]);
	return true;
}

void SolExit()
{
	fwritef(stderr,"\n");
	exit(0);
}
