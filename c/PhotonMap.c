//----------------------------------------------------------------------------
// photonmap.cpp
// An example implementation of the photon map data structure
//
// Henrik Wann Jensen - February 2001
//----------------------------------------------------------------------------

#include "PhotonMap.h"

#define swap(ph,a,b) { Photon *ph2=ph[a]; ph[a]=ph[b]; ph[b]=ph2; }

// median_split splits the photon array into two separate
// pieces around the median with all photons below the
// the median in the lower half and all photons above
// than the median in the upper half. The comparison
// criteria is the axis (indicated by the axis parameter)
// (inspired by routine in "Algorithms in C++" by Sedgewick)
//*****************************************************************
void median_split(
//  PhotonMap *map,
  Photon **p,
  const int start,               // start of photon block in array
  const int end,                 // end of photon block in array
  const int median,              // desired median number
  const int axis )               // axis to split along
//*****************************************************************
{
  int left = start;
  int right = end;

  while ( right > left ) {
    const float v = p[right]->pos[axis];
    int i=left-1;
    int j=right;
    for (;;) {
      while ( p[++i]->pos[axis] < v )
        ;
      while ( p[--j]->pos[axis] > v && j>left )
        ;
      if ( i >= j )
        break;
      swap(p,i,j);
    }

    swap(p,i,right);
    if ( i >= median )
      right=i-1;
    if ( i <= median )
      left=i+1;
  }
}

  
// See "Realistic image synthesis using Photon Mapping" chapter 6
// for an explanation of this function
//****************************
void balance_segment(
  PhotonMap *map,
  Photon **pbal,
  Photon **porg,
  const int index,
  const int start,
  const int end )
//****************************
{
  //--------------------
  // compute new median
  //--------------------

  int median=1;
  while ((4*median) <= (end-start+1))
    median += median;

  if ((3*median) <= (end-start+1)) {
    median += median;
    median += start-1;
  } else	
    median = end-median+1;

  //--------------------------
  // find axis to split along
  //--------------------------

  int axis=2;
  if ((map->bbox_max[0]-map->bbox_min[0])>(map->bbox_max[1]-map->bbox_min[1]) &&
      (map->bbox_max[0]-map->bbox_min[0])>(map->bbox_max[2]-map->bbox_min[2]))
    axis=0;
  else if ((map->bbox_max[1]-map->bbox_min[1])>(map->bbox_max[2]-map->bbox_min[2]))
    axis=1;

  //------------------------------------------
  // partition photon block around the median
  //------------------------------------------

  median_split( porg, start, end, median, axis );

  pbal[ index ] = porg[ median ];
  pbal[ index ]->plane = axis;

  //----------------------------------------------
  // recursively balance the left and right block
  //----------------------------------------------

  if ( median > start ) {
    // balance left segment
    if ( start < median-1 ) {
      const float tmp=map->bbox_max[axis];
      map->bbox_max[axis] = pbal[index]->pos[axis];
      balance_segment( map, pbal, porg, 2*index, start, median-1 );
      map->bbox_max[axis] = tmp;
    } else {
      pbal[ 2*index ] = porg[start];
    }
  }

  if ( median < end ) {
    // balance right segment
    if ( median+1 < end ) {
      const float tmp = map->bbox_min[axis];		
      map->bbox_min[axis] = pbal[index]->pos[axis];
      balance_segment( map, pbal, porg, 2*index+1, median+1, end );
      map->bbox_min[axis] = tmp;
    } else {
      pbal[ 2*index+1 ] = porg[end];
    }
  }	
}


/* This is the constructor for the photon map.
 * To create the photon map it is necessary to specify the
 * maximum number of photons that will be stored
*/
//************************************************
PhotonMap *PhotonMapInit( const int max_phot )
//************************************************
{
  int i;
  double angle;
  PhotonMap *map = (PhotonMap*)malloc( sizeof( PhotonMap ) );
  map->stored_photons = 0;
  map->prev_scale = 1;
  map->max_photons = max_phot;

  map->photons = (Photon*)malloc( sizeof( Photon ) * ( map->max_photons+1 ) );

  if (map->photons == NULL) {
    fprintf(stderr,"Out of memory initializing photon map\n");
    exit(-1);
  }

  map->bbox_min[0] = map->bbox_min[1] = map->bbox_min[2] = 1e8f;
  map->bbox_max[0] = map->bbox_max[1] = map->bbox_max[2] = -1e8f;
  
  //----------------------------------------
  // initialize direction conversion tables
  //----------------------------------------

  for (i=0; i<256; i++) {
    angle = (double)i*(1.0/256.0)*M_PI;
    map->costheta[i] = cos( angle );
    map->sintheta[i] = sin( angle );
    map->cosphi[i]   = cos( 2.0*angle );
    map->sinphi[i]   = sin( 2.0*angle );
  }
  return map;
}


/* photon_dir returns the direction of a photon
 */
//*****************************************************************
void photon_dir( PhotonMap *map, float *dir, const Photon *p )
//*****************************************************************
{
  dir[0] = map->sintheta[p->theta]*map->cosphi[p->phi];
  dir[1] = map->sintheta[p->theta]*map->sinphi[p->phi];
  dir[2] = map->costheta[p->theta];
}


/* irradiance_estimate computes an irradiance estimate
 * at a given surface position
*/
//**********************************************
void irradiance_estimate(
  PhotonMap *map,
  float irrad[3],                // returned irradiance
  const float pos[3],            // surface position
  const float normal[3],         // surface normal at pos
  const float max_dist,          // max distance to look for photons
  const int nphotons )           // number of photons to use
//**********************************************
{
  const Photon *p;
  float tmp;
  float pdir[3];
  int i;
  NearestPhotons np;
  irrad[0] = irrad[1] = irrad[2] = 0.0;

  np.dist2 = (float*)alloca( sizeof(float)*(nphotons+1) );
  np.index = (const Photon**)alloca( sizeof(Photon*)*(nphotons+1) );

  np.pos[0] = pos[0]; np.pos[1] = pos[1]; np.pos[2] = pos[2];
  np.max = nphotons;
  np.found = 0;
  np.got_heap = 0;
  np.dist2[0] = max_dist*max_dist;

  // locate the nearest photons
  locate_photons( map, &np, 1 );

  // if less than 8 photons return
  if (np.found<8)
    return;

  // sum irradiance from all photons
  for (i=1; i<=np.found; i++) {
    p = np.index[i];
    // the photon_dir call and following if can be omitted (for speed)
    // if the scene does not have any thin surfaces
    photon_dir( map, pdir, p );
    if ( (pdir[0]*normal[0]+pdir[1]*normal[1]+pdir[2]*normal[2]) < 0.0f ) {
      irrad[0] += p->power[0];
      irrad[1] += p->power[1];
      irrad[2] += p->power[2];
    }
  }

  tmp=(1.0f/M_PI)/(np.dist2[0]);	// estimate of density

  irrad[0] *= tmp;
  irrad[1] *= tmp;
  irrad[2] *= tmp;
}


/* locate_photons finds the nearest photons in the
 * photon map given the parameters in np
*/
//******************************************
void locate_photons(
  PhotonMap *map,
  NearestPhotons *const np,
  const int index )
//******************************************
{
  const Photon *p = &map->photons[index];
  float dist1;

  if (index<map->half_stored_photons) {
    dist1 = np->pos[ p->plane ] - p->pos[ p->plane ];

    if (dist1>0.0) { // if dist1 is positive search right plane
      locate_photons( map, np, 2*index+1 );
      if ( dist1*dist1 < np->dist2[0] )
        locate_photons( map, np, 2*index );
    } else {         // dist1 is negative search left first
      locate_photons( map, np, 2*index );
      if ( dist1*dist1 < np->dist2[0] )
        locate_photons( map, np, 2*index+1 );
    }
  }

  // compute squared distance between current photon and np->pos

  dist1 = p->pos[0] - np->pos[0];
  float dist2 = dist1*dist1;
  dist1 = p->pos[1] - np->pos[1];
  dist2 += dist1*dist1;
  dist1 = p->pos[2] - np->pos[2];
  dist2 += dist1*dist1;
  
  if ( dist2 < np->dist2[0] ) {
    // we found a photon :) Insert it in the candidate list

    if ( np->found < np->max ) {
      // heap is not full; use array
      np->found++;
      np->dist2[np->found] = dist2;
      np->index[np->found] = p;
    } else {
      int j,parent,k;

      if (np->got_heap==0) { // Do we need to build the heap?
        // Build heap
        float dst2;
        const Photon *phot;
        int half_found = np->found>>1;
        for ( k=half_found; k>=1; k--) {
          parent=k;
          phot = np->index[k];
          dst2 = np->dist2[k];
          while ( parent <= half_found ) {
            j = parent+parent;
            if (j<np->found && np->dist2[j]<np->dist2[j+1])
              j++;
            if (dst2>=np->dist2[j])
              break;
            np->dist2[parent] = np->dist2[j];
            np->index[parent] = np->index[j];
            parent=j;
          }
          np->dist2[parent] = dst2;
          np->index[parent] = phot;
        }
        np->got_heap = 1;
      }

      // insert new photon into max heap
      // delete largest element, insert new and reorder the heap

      parent=1;
      j = 2;
      while ( j <= np->found ) {
        if ( j < np->found && np->dist2[j] < np->dist2[j+1] )
          j++;
        if ( dist2 > np->dist2[j] )
          break;
        np->dist2[parent] = np->dist2[j];
        np->index[parent] = np->index[j];
        parent = j;
        j += j;
      }
      np->index[parent] = p;
      np->dist2[parent] = dist2;

      np->dist2[0] = np->dist2[1];
    }
  }
}


/* store puts a photon into the flat array that will form
 * the final kd-tree.
 *
 * Call this function to store a photon.
*/
//***************************
void store(
  PhotonMap *map,
  const float power[3],
  const float pos[3],
  const float dir[3] )
//***************************
{
  int i, theta, phi;
  if (map->stored_photons>=map->max_photons)
    return;

  (map->stored_photons)++;
  Photon *const node = &map->photons[map->stored_photons];

  for (i=0; i<3; i++) {
    node->pos[i] = pos[i];

    if (node->pos[i] < map->bbox_min[i])
      map->bbox_min[i] = node->pos[i];
    if (node->pos[i] > map->bbox_max[i])
      map->bbox_max[i] = node->pos[i];

    node->power[i] = power[i];
  }

  theta = (int)( acos(dir[2])*(256.0/M_PI) );
  if (theta>255)
    node->theta = 255;
  else
   node->theta = (unsigned char)theta;

  phi = (int)( atan2(dir[1],dir[0])*(256.0/(2.0*M_PI)) );
  if (phi>255)
    node->phi = 255;
  else if (phi<0)
    node->phi = (unsigned char)(phi+256);
  else
    node->phi = (unsigned char)phi;
}


/* scale_photon_power is used to scale the power of all
 * photons once they have been emitted from the light
 * source. scale = 1/(#emitted photons).
 * Call this function after each light source is processed.
*/
//********************************************************
void scale_photon_power( PhotonMap *map, const float scale )
//********************************************************
{
  int i;
  for (i=map->prev_scale; i<=map->stored_photons; i++) {
    map->photons[i].power[0] *= scale;
    map->photons[i].power[1] *= scale;
    map->photons[i].power[2] *= scale;
  }
  map->prev_scale = map->stored_photons;
}


/* balance creates a left balanced kd-tree from the flat photon array.
 * This function should be called before the photon map
 * is used for rendering.
 */
//******************************
void balance(PhotonMap *map)
//******************************
{
  int i;
  if (map->stored_photons>1) {
    int d, j=1, foo=1;
    Photon foo_photon = map->photons[j];
    // allocate two temporary arrays for the balancing procedure
    Photon **pa1 = (Photon**)malloc(sizeof(Photon*)*(map->stored_photons+1));
    Photon **pa2 = (Photon**)malloc(sizeof(Photon*)*(map->stored_photons+1));

    for (i=0; i<=map->stored_photons; i++)
      pa2[i] = &map->photons[i];

    balance_segment( map, pa1, pa2, 1, 1, map->stored_photons );
    free(pa2);

    // reorganize balanced kd-tree (make a heap)
    foo_photon = map->photons[j];

    for (i=1; i<=map->stored_photons; i++) {
      d=pa1[j]-map->photons;
      pa1[j] = NULL;
      if (d != foo)
        map->photons[j] = map->photons[d];
      else {
        map->photons[j] = foo_photon;

        if (i<map->stored_photons) {
          for (;foo<=map->stored_photons; foo++)
            if (pa1[foo] != NULL)
              break;
          foo_photon = map->photons[foo];
          j = foo;
        }
        continue;
      }
      j = d;
    }
    free(pa1);
  }

  map->half_stored_photons = map->stored_photons/2-1;
}
