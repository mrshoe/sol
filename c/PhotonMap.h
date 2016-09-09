#ifndef _PHOTON_MAP_H
#define _PHOTON_MAP_H
//----------------------------------------------------------------------------
// photonmap.h
// An example implementation of the photon map data structure
//
// Henrik Wann Jensen - February 2001
//----------------------------------------------------------------------------

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

/* This is the photon
 * The power is not compressed so the
 * size is 28 bytes
 */
//**********************
typedef struct Photon {
//**********************
	float pos[3];                 // photon position
	short plane;                  // splitting plane for kd-tree
	unsigned char theta, phi;     // incoming direction
	float power[3];               // photon power (uncompressed)
} Photon;


/* This structure is used only to locate the
 * nearest photons
 */
//******************************
typedef struct NearestPhotons {
//******************************
	int max;
	int found;
	int got_heap;
	float pos[3];
	float *dist2;
	const Photon **index;
} NearestPhotons;


/* This is the PhotonMap class
 */
//*****************
typedef struct _PhotonMap {
//*****************

	Photon *photons;

	int stored_photons;
	int half_stored_photons;
	int max_photons;
	int prev_scale;

	float costheta[256];
	float sintheta[256];
	float cosphi[256];
	float sinphi[256];
	  
	float bbox_min[3];		// use bbox_min;
	float bbox_max[3];		// use bbox_max;
} PhotonMap;

PhotonMap *PhotonMapInit( const int max_phot ) ;

void store(
	PhotonMap *map,
	const float power[3],          // photon power
	const float pos[3],            // photon position
	const float dir[3] );          // photon direction

void scale_photon_power(
	PhotonMap *map,
	const float scale );           // 1/(number of emitted photons)

void balance(
	PhotonMap *map );

void irradiance_estimate(
	PhotonMap *map,
	float irrad[3],                // returned irradiance
	const float pos[3],            // surface position
	const float normal[3],         // surface normal at pos
	const float max_dist,          // max distance to look for photons
	const int nphotons );    // number of photons to use

void locate_photons(
	PhotonMap *map,
	NearestPhotons *const np,      // np is used to locate the photons
	const int index );       // call with index = 1

void photon_dir(
	PhotonMap *map,
	float *dir,                    // direction of photon (returned)
	const Photon *p );       // the photon
#endif			//_PHOTON_MAP_H
