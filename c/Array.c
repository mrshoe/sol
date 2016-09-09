/*
 * Array.c
 */

#include <stdlib.h>
#include "Array.h"

void ArrayInit(Array *a, int initialCapacity)
{
	a->data = malloc(initialCapacity*sizeof(void*));
	a->length = 0;
	a->capacity = initialCapacity;
}

void ArrayInsert(Array *a, void *newItem)
{
	if(a->length == a->capacity)
	{
		a->capacity *= 2; 
		a->data = realloc(a->data, a->capacity*sizeof(void*));
	}
	a->data[a->length] = newItem;
	(a->length)++;
}

void ArrayDelete(Array *a)
{
	free(a->data);
}
