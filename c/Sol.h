/*
 * Sol.h
 */

#ifndef SOL_H
#define SOL_H

#include <stdlib.h>
#include <stdio.h>
#include "Ray.h"
#include "HitInfo.h"

#define true						1
#define false						0
#ifndef NULL
#define NULL						0
#endif

//console text colors
#define TEXT_NORMAL   "\033[0m"
#define TEXT_RED   "\033[1;31m"
#define TEXT_GREEN "\033[1;32m"
#define TEXT_PINK "\033[1;35m"

void SolError();
void SolDebug();
void SolExit();

#endif			//SOL_H
