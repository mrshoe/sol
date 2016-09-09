import Sol;
import std.math;
/*
 * PhotonMap.d is a D port of Henrik Wan Jensen's C++ Photon Map implementation
 */
//----------------------------------------------------------------------------
// photonmap.h
// An example implementation of the photon map data structure
//
// Henrik Wann Jensen - February 2001
//----------------------------------------------------------------------------

/* This is the photon
 * The power is not compressed so the
 * size is 28 bytes
 */
//**********************
struct Photon {
//**********************
	float pos[3];                 // photon position
	short plane;                  // splitting plane for kd-tree
	char theta, phi;     // incoming direction
	float power[3];               // photon power (uncompressed)
}


/* This structure is used only to locate the
 * nearest photons
 */
//******************************
struct NearestPhotons {
//******************************
	int max;
	int found;
	int got_heap;
	float pos[3];
	float[] dist2;
	Photon*[] index;
}


/* This is the Photon_map class
 */
//*****************
class PhotonMap {
//*****************
	this( int max_phot ) {
		stored_photons = 0;
		prev_scale = 1;
		max_photons = max_phot;

		photons.length = max_photons+1;

		/*
		if (photons is null) {
		fprintf(stderr,"Out of memory initializing photon map\n");
		exit(-1);
		}
		*/

		bbox_min[0] = bbox_min[1] = bbox_min[2] = 1e8f;
		bbox_max[0] = bbox_max[1] = bbox_max[2] = -1e8f;

		//----------------------------------------
		// initialize direction conversion tables
		//----------------------------------------

		for (int i=0; i<256; i++) {
			double angle = cast(double)i*(1.0/256.0)*SOL_PI;
			costheta[i] = cos( angle );
			sintheta[i] = sin( angle );
			cosphi[i]   = cos( 2.0*angle );
			sinphi[i]   = sin( 2.0*angle );
		}
	}
	~this() {
		photons.length=0;
	}

	void store(
		float[3] power,          // photon power
		float[3] pos,            // photon position
		float[3] dir )          // photon direction
	{
		if (stored_photons>=max_photons)
			return;

		stored_photons++;
		Photon *node = &photons[stored_photons];

		for (int i=0; i<3; i++) {
			node.pos[i] = pos[i];

			if (node.pos[i] < bbox_min[i])
				bbox_min[i] = node.pos[i];
			if (node.pos[i] > bbox_max[i])
				bbox_max[i] = node.pos[i];

			node.power[i] = power[i];
		}

		int theta = cast(int)( acos(dir[2])*(256.0/SOL_PI) );
		if (theta>255)
			node.theta = 255;
		else
		 node.theta = cast(char)theta;

		int phi = cast(int)( atan2(dir[1],dir[0])*(256.0/(2.0*SOL_PI)) );
		if (phi>255)
			node.phi = 255;
		else if (phi<0)
			node.phi = cast(char)(phi+256);
		else
			node.phi = cast(char)phi;
	}

	void scale_photon_power(
		float scale )           // 1/(number of emitted photons)
	{
		for (int i=prev_scale; i<=stored_photons; i++) {
			photons[i].power[0] *= scale;
			photons[i].power[1] *= scale;
			photons[i].power[2] *= scale;
		}
		prev_scale = stored_photons;
	}

	void balance()              // balance the kd-tree (before use!)
	{
		if (stored_photons>1) {
			// allocate two temporary arrays for the balancing procedure
			Photon*[] pa1;
			Photon*[] pa2;
			pa1.length = stored_photons+1;
			pa2.length = stored_photons+1;

			for (int i=0; i<=stored_photons; i++)
				pa2[i] = &photons[i];

			balance_segment( pa1, pa2, 1, 1, stored_photons );
			pa2.length = 0;

			// reorganize balanced kd-tree (make a heap)
			int d, j=1, foo=1;
			Photon foo_photon = photons[j];

			for (int i=1; i<=stored_photons; i++) {
				d=cast(int)pa1[j]-cast(int)photons.ptr;
				pa1[j] = null;
				if (d != foo) {
					writefln("%d", d);
					photons[j] = photons[d];
				}
				else {
					photons[j] = foo_photon;

					if (i<stored_photons) {
						for (;foo<=stored_photons; foo++)
							if (pa1[foo] != null)
								break;
						foo_photon = photons[foo];
						j = foo;
					}
					continue;
				}
				j = d;
			}
			pa1.length = 0;
		}

		half_stored_photons = (stored_photons>>1)-1;
	}

	void swap(Photon*[] ph, int a, int b) {
		Photon *ph2 = ph[a];
		ph[a] = ph[b];
		ph[b] = ph2;
	}

	void irradiance_estimate(
		float[3] irrad,                // returned irradiance
		float[3] pos,            // surface position
		float[3] normal,         // surface normal at pos
		float max_dist,          // max distance to look for photons
		int nphotons )    // number of photons to use
	{
		irrad[0] = irrad[1] = irrad[2] = 0.0;

		NearestPhotons np;
		np.dist2.length = nphotons+1;
		np.index.length = nphotons+1;

		np.pos[0] = pos[0]; np.pos[1] = pos[1]; np.pos[2] = pos[2];
		np.max = nphotons;
		np.found = 0;
		np.got_heap = 0;
		np.dist2[0] = max_dist*max_dist;

		// locate the nearest photons
		locate_photons( &np, 1 );

		// if less than 8 photons return
		if (np.found<8)
			return;

		float pdir[3];

		// sum irradiance from all photons
		for (int i=1; i<=np.found; i++) {
			Photon *p = np.index[i];
			// the photon_dir call and following if can be omitted (for speed)
			// if the scene does not have any thin surfaces
		//	photon_dir( pdir, p );
		//	if ( (pdir[0]*normal[0]+pdir[1]*normal[1]+pdir[2]*normal[2]) < 0.0f ) {
			irrad[0] += p.power[0];
			irrad[1] += p.power[1];
			irrad[2] += p.power[2];
		//	}
		}

		float tmp=(1.0f/SOL_PI)/(np.dist2[0]);	// estimate of density

		irrad[0] *= tmp;
		irrad[1] *= tmp;
		irrad[2] *= tmp;
	}

	void locate_photons(
		NearestPhotons *np,      // np is used to locate the photons
		int index )       // call with index = 1
	{
		Photon *p = &photons[index];
		float dist1;

		if (index<half_stored_photons) {
			dist1 = np.pos[ p.plane ] - p.pos[ p.plane ];

			if (dist1>0.0) { // if dist1 is positive search right plane
				locate_photons( np, 2*index+1 );
				if ( dist1*dist1 < np.dist2[0] )
					locate_photons( np, 2*index );
			} else {				 // dist1 is negative search left first
				locate_photons( np, 2*index );
				if ( dist1*dist1 < np.dist2[0] )
					locate_photons( np, 2*index+1 );
			}
		}

		// compute squared distance between current photon and np.pos

		dist1 = p.pos[0] - np.pos[0];
		float dist2 = dist1*dist1;
		dist1 = p.pos[1] - np.pos[1];
		dist2 += dist1*dist1;
		dist1 = p.pos[2] - np.pos[2];
		dist2 += dist1*dist1;
		
		if ( dist2 < np.dist2[0] ) {
			// we found a photon :) Insert it in the candidate list

			if ( np.found < np.max ) {
				// heap is not full; use array
				np.found++;
				np.dist2[np.found] = dist2;
				np.index[np.found] = p;
			} else {
				int j,parent;

				if (np.got_heap==0) { // Do we need to build the heap?
					// Build heap
					float dst2;
					Photon *phot;
					int half_found = np.found>>1;
					for ( int k=half_found; k>=1; k--) {
						parent=k;
						phot = np.index[k];
						dst2 = np.dist2[k];
						while ( parent <= half_found ) {
							j = parent+parent;
							if (j<np.found && np.dist2[j]<np.dist2[j+1])
								j++;
							if (dst2>=np.dist2[j])
								break;
							np.dist2[parent] = np.dist2[j];
							np.index[parent] = np.index[j];
							parent=j;
						}
						np.dist2[parent] = dst2;
						np.index[parent] = phot;
					}
					np.got_heap = 1;
				}

				// insert new photon into max heap
				// delete largest element, insert new and reorder the heap

				parent=1;
				j = 2;
				while ( j <= np.found ) {
					if ( j < np.found && np.dist2[j] < np.dist2[j+1] )
						j++;
					if ( dist2 > np.dist2[j] )
						break;
					np.dist2[parent] = np.dist2[j];
					np.index[parent] = np.index[j];
					parent = j;
					j += j;
				}
				np.index[parent] = p;
				np.dist2[parent] = dist2;

				np.dist2[0] = np.dist2[1];
			}
		}
	}

	void photon_dir(
		float *dir,                    // direction of photon (returned)
		Photon *p )       // the photon
	{
		dir[0] = sintheta[p.theta]*cosphi[p.phi];
		dir[1] = sintheta[p.theta]*sinphi[p.phi];
		dir[2] = costheta[p.theta];
	}

	void balance_segment(
		Photon*[] pbal,
		Photon*[] porg,
		int index,
		int start,
		int end )
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
		if ((bbox_max[0]-bbox_min[0])>(bbox_max[1]-bbox_min[1]) &&
				(bbox_max[0]-bbox_min[0])>(bbox_max[2]-bbox_min[2]))
			axis=0;
		else if ((bbox_max[1]-bbox_min[1])>(bbox_max[2]-bbox_min[2]))
			axis=1;

		//------------------------------------------
		// partition photon block around the median
		//------------------------------------------

		median_split( porg, start, end, median, axis );

		pbal[ index ] = porg[ median ];
		pbal[ index ].plane = axis;

		//----------------------------------------------
		// recursively balance the left and right block
		//----------------------------------------------

		if ( median > start ) {
			// balance left segment
			if ( start < median-1 ) {
				float tmp=bbox_max[axis];
				bbox_max[axis] = pbal[index].pos[axis];
				balance_segment( pbal, porg, 2*index, start, median-1 );
				bbox_max[axis] = tmp;
			} else {
				pbal[ 2*index ] = porg[start];
			}
		}

		if ( median < end ) {
			// balance right segment
			if ( median+1 < end ) {
				float tmp = bbox_min[axis];		
				bbox_min[axis] = pbal[index].pos[axis];
				balance_segment( pbal, porg, 2*index+1, median+1, end );
				bbox_min[axis] = tmp;
			} else {
				pbal[ 2*index+1 ] = porg[end];
			}
		}	
	}

	void median_split(
		Photon*[] p,
		int start,
		int end,
		int median,
		int axis )
	{
		int left = start;
		int right = end;

		while ( right > left ) {
			float v = p[right].pos[axis];
			int i=left-1;
			int j=right;
			for (;;) {
				while ( p[++i].pos[axis] < v ) {}
				while ( p[--j].pos[axis] > v && j>left ) {}
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
								  
	Photon[] photons;

	int stored_photons;
	int half_stored_photons;
	int max_photons;
	int prev_scale;

	float[256] costheta;
	float[256] sintheta;
	float[256] cosphi;
	float[256] sinphi;
	  
	float[3] bbox_min;		// use bbox_min;
	float[3] bbox_max;		// use bbox_max;

	/*
	unittest {
		float[3] power;
		float[3] pos;
		float[3] dir;
		PhotonMap pm = new PhotonMap(1000);
		for(int i=0;i<1000;i++) {
			power[0] = power[1] = power[2] = cast(float)i;
			pos[0] = pos[1] = pos[2] = cast(float)i + 1.0f;
			dir[0] = dir[1] = dir[2] = cast(float)i + 2.0f;
			pm.store(power, pos, dir);
		}
		writefln("%f %f %f", pm.photons[999].power[0],
			pm.photons[999].power[1],pm.photons[999].power[2]);
		pm.balance();
		writefln("%f %f %f", pm.photons[999].power[0],
			pm.photons[999].power[1],pm.photons[999].power[2]);
		pm = new PhotonMap(1000);
		writefln("foo");
		writefln("%f %f %f", pm.photons[999].power[0],
			pm.photons[999].power[1],pm.photons[999].power[2]);
		pm.balance();
		writefln("%f %f %f", pm.photons[999].power[0],
			pm.photons[999].power[1],pm.photons[999].power[2]);
	}
	*/
}
