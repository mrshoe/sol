/*
 * Array.h
 */

#ifndef SOL_ARRAY_H
#define SOL_ARRAY_H

typedef struct _Array {
	int length, capacity;
	void **data;
} Array;

void ArrayInit(Array *a, int initialCapacity);
void ArrayInsert(Array *a, void *newItem);
void ArrayDelete(Array *a);

#endif			//SOL_ARRAY_H
