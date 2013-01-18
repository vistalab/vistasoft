// Gray.cpp: implementation of the CGray class.

//

//////////////////////////////////////////////////////////////////////



//#include "stdafx.h"

//#include "mrGray.h"

#include <string.h>

#include "gray.h"



//////////////////////////////////////////////////////////////////////

// Construction/Destruction

//////////////////////////////////////////////////////////////////////



CGray::CGray()

{

	/* Entry i in this table (i=0..5) represents the presence of white

	 * matter in neighbor i+1 of A.  The bit pattern describes which

	* neighbors of B are 26-nb of this neighbor of A. */

	type_I_26nb[0]  =  0x31;  /* 0011 0001 */

	type_I_26nb[1]  =  0x00;  /* 0000 0000 */

	type_I_26nb[2]  =  0x34;  /* 0011 0100 */

	type_I_26nb[3]  =  0x00;  /* 0000 0000 */

	type_I_26nb[4]  =  0x15;  /* 0001 0101 */

	type_I_26nb[5]  =  0x25;  /* 0010 0101 */



	/* Entry i in this table (i=0..5) represents the presence of white

	* matter in neighbor i+1 of A.  The bit pattern describes which

	* neighbors of B are 26-nb of this neighbor of A. */

	type_II_26nb[0]  =  0x29;

	type_II_26nb[1]  =  0x27; 

	type_II_26nb[2]  =  0x2C;

	type_II_26nb[3]  =  0x08;

	type_II_26nb[4]  =  0x1D;

	type_II_26nb[5]  =  0x20;



	/* Entry i in this table (i=0..5) represents the presence of white

	* matter in neighbor i+1 of A.  The bit pattern describes which

	* neighbors of B are 26-nb of this neighbor of A. */

	type_III_26nb[0]  =  0x29;

	type_III_26nb[1]  =  0x26; 

	type_III_26nb[2]  =  0x04;

	type_III_26nb[3]  =  0x08;

	type_III_26nb[4]  =  0x1C;

	type_III_26nb[5]  =  0x20;



	// If any of these fail, funcs won't be usable

	m_Ok=build_rotation_tables();

	if (m_Ok) m_Ok=build_type_I_table();

	if (m_Ok) m_Ok=build_type_II_table();

	if (m_Ok) m_Ok=build_type_III_table();



	m_ContendWhite=m_ContendGray=true;

}



CGray::~CGray()

{

	if (ROTTAB_XCW) delete ROTTAB_XCW;

	if (ROTTAB_XCCW) delete ROTTAB_XCCW;

	if (ROTTAB_YCW) delete ROTTAB_YCW;

	if (ROTTAB_YCCW) delete ROTTAB_YCCW;

	if (ROTTAB_ZCW) delete ROTTAB_ZCW;

	if (ROTTAB_ZCCW) delete ROTTAB_ZCCW;

	if (TYPE_I_TAB) delete TYPE_I_TAB;

	if (TYPE_II_TAB) delete TYPE_II_TAB;

	if (TYPE_III_TAB) delete TYPE_III_TAB;

}



bool CGray::Ok(void)

{

	return m_Ok;

}



/*

 * gray.cpp

 *

 * Routines to grow the gray matter and to compute the connectivity.

 *

 * Incorporated from Unix version by Robert Taylor Jan 1998

 *

 * Public Functions:

 *	GrayMatter 	*init_gray_matter(MRVol *mrvol)

 *	void 		free_gray_matter(GrayMatter *gm)

 *	void 		grow_gray_layers(GrayMatter *gm,

 *					 int voi_xmin, int voi_xmax,

 *					 int voi_ymin, int voi_ymax,

 *					 int voi_zmin, int voi_zmax,

 *					 int num_layers)

 *	void 		select_gray_matter_comp(GrayMatter *gm,

 *			     int startx, int starty, int startz)

 *

 * Private Functions:

 *	alloc_gray_matter

 *

 *	build_rotation_tables

 *	build_type_I_table

 *	build_type_II_table

 *	build_type_III_table

 *	build_tables

 *	compute_wm_nbhd_code

 *

 *	white_grow_contendp

 *	grow_from_white_boundary

 *	first_gray_layer_connectivity

 *

 *	is_connectedp

 *	gray_grow_contendp

 *	grow_from_gray_boundary

 *	is_connected2p

 *	gray_layer_connectivity

 *

 *	add_new_gray_matter

 *

 *	gray_matter_set_flag

 *	gray_matter_flood_fill

 */



#define CONNECT_XPLUS		0

#define CONNECT_XMINUS		1

#define CONNECT_YPLUS		2

#define CONNECT_YMINUS		3

#define CONNECT_ZPLUS		4

#define CONNECT_ZMINUS		5



#define BIT_SWAP(c,New,Old) (((c>>(Old-1))&0x01)<<(New-1))



/**********************************************************************/



/*

 * Initialize GrayMatter structure.

 */

GrayMatter * CGray::init_gray_matter(MRVol * mrvol)

{

	if (!m_Ok) return NULL;



     GrayMatter	*gm = new GrayMatter;

	if (!gm) return NULL;



     gm->mrvol = mrvol;

     gm->gm_array = NULL;

     gm->gm_size = 0;

     gm->inv_gm_table = NULL;

     gm->num_connex = 0;

     gm->connex = NULL;

     return gm;

}



/*

 * Allocate space for GrayMatter voxels.

 */

GrayMatter * CGray::alloc_gray_matter(GrayMatter * gm, int inc_size)

{

	if (gm->gm_size==0) {

		gm->gm_array = new GrayVoxel[gm->gm_size = inc_size];

		if (!gm->gm_array) return NULL;

#ifdef DYNAMIC_NEIGHBOURS

		ZeroMemory(gm->gm_array,gm->gm_size*sizeof(*(gm->gm_array)));

#endif

     } else {

		GrayVoxel *tmp = new GrayVoxel[gm->gm_size + inc_size];

		if (!tmp) return NULL;

#ifdef DYNAMIC_NEIGHBOURS

		ZeroMemory(tmp+gm->gm_size,sizeof(*tmp)*inc_size);

#endif

		memcpy(tmp,gm->gm_array,sizeof(*tmp)*gm->gm_size);

		delete gm->gm_array;

		gm->gm_array = tmp;

		gm->gm_size += inc_size;

     }

     return gm;

}



/*

 * Frees the space allocated for GrayMatter structure.

 */

void CGray::free_gray_matter(GrayMatter *gm)

{

	if (!m_Ok) return;



	if (gm) {

		if (gm->gm_array) {

#ifdef DYNAMIC_NEIGHBOURS

			for (int i=0;i<gm->gm_size;i++) 

				if (gm->gm_array[i].gm_nbhrs) 

					delete gm->gm_array[i].gm_nbhrs;

#endif

			delete gm->gm_array;

		}

		if (gm->inv_gm_table) delete gm->inv_gm_table;

		delete gm;

	}

}



/**********************************************************************/



/*

 * Compute 6-nbhd code rotation tables.

 */

bool CGray::build_rotation_tables()

{

     int	c;



     /* Clockwise rotation about X-axis.

      * 1=6, 2=2, 3=5, 4=4, 5=1, 6=3. */

     ROTTAB_XCW = (unsigned char *) new unsigned char[1<<6];

     if (!ROTTAB_XCW) return false;

     for (c=0; c<(1<<6); c++) {

	  ROTTAB_XCW[c] = (unsigned char)

	       BIT_SWAP(c,1,6) | BIT_SWAP(c,2,2) |

	       BIT_SWAP(c,3,5) | BIT_SWAP(c,4,4) |

	       BIT_SWAP(c,5,1) | BIT_SWAP(c,6,3);

     }



     /* Counter-clockwise rotation about X-axis.

      * 1=5, 2=2, 3=6, 4=4, 5=3, 6=1. */

     ROTTAB_XCCW = (unsigned char *) new unsigned char[1<<6];

     if (!ROTTAB_XCCW) {

		delete ROTTAB_XCW;

		return false;

	 }

     for (c=0; c<(1<<6); c++) {

	  ROTTAB_XCCW[c] = (unsigned char)

	       BIT_SWAP(c,1,5) | BIT_SWAP(c,2,2) |

	       BIT_SWAP(c,3,6) | BIT_SWAP(c,4,4) |

	       BIT_SWAP(c,5,3) | BIT_SWAP(c,6,1);

     }



     /* Clockwise rotation about Y-axis.

      * 1=1, 2=5, 3=3, 4=6, 5=4, 6=2. */

     ROTTAB_YCW = (unsigned char *) new unsigned char[1<<6];

     if (!ROTTAB_YCW) {

		delete ROTTAB_XCCW;

		delete ROTTAB_XCW;

		return false;

	 }

     for (c=0; c<(1<<6); c++) {

	  ROTTAB_YCW[c] = (unsigned char)

	       BIT_SWAP(c,1,1) | BIT_SWAP(c,2,5) |

	       BIT_SWAP(c,3,3) | BIT_SWAP(c,4,6) |

	       BIT_SWAP(c,5,4) | BIT_SWAP(c,6,2);

     }



     /* Counter-clockwise rotation about Y-axis.

      * 1=1, 2=6, 3=3, 4=5, 5=2, 6=4. */

     ROTTAB_YCCW = (unsigned char *) new unsigned char[1<<6];

	 if (!ROTTAB_YCCW) {

		delete ROTTAB_YCW;

		delete ROTTAB_XCCW;

		delete ROTTAB_XCW;

		return false;

	 }

     for (c=0; c<(1<<6); c++) {

	  ROTTAB_YCCW[c] = (unsigned char)

	       BIT_SWAP(c,1,1) | BIT_SWAP(c,2,6) |

	       BIT_SWAP(c,3,3) | BIT_SWAP(c,4,5) |

	       BIT_SWAP(c,5,2) | BIT_SWAP(c,6,4);

     }



     /* Clockwise rotation about Z-axis.

      * 1=2, 2=3, 3=4, 4=1, 5=5, 6=6. */

     ROTTAB_ZCW = (unsigned char *) new unsigned char[1<<6];

	 if (!ROTTAB_ZCW) {

		delete ROTTAB_YCCW;

		delete ROTTAB_YCW;

		delete ROTTAB_XCCW;

		delete ROTTAB_XCW;

		return false;

	 }

     for (c=0; c<(1<<6); c++) {

	  ROTTAB_ZCW[c] = (unsigned char)

	       BIT_SWAP(c,1,2) | BIT_SWAP(c,2,3) |

	       BIT_SWAP(c,3,4) | BIT_SWAP(c,4,1) |

	       BIT_SWAP(c,5,5) | BIT_SWAP(c,6,6);

     }



     /* Counter-clockwise rotation about Z-axis.

      * 1=4, 2=1, 3=2, 4=3, 5=5, 6=6. */

     ROTTAB_ZCCW = (unsigned char *) new unsigned char[1<<6];

	 if (!ROTTAB_ZCCW) {

		delete ROTTAB_ZCW;

		delete ROTTAB_YCCW;

		delete ROTTAB_YCW;

		delete ROTTAB_XCCW;

		delete ROTTAB_XCW;

		return false;

	 }

     for (c=0; c<(1<<6); c++) {

	  ROTTAB_ZCCW[c] = (unsigned char)

	       BIT_SWAP(c,1,4) | BIT_SWAP(c,2,1) |

	       BIT_SWAP(c,3,2) | BIT_SWAP(c,4,3) |

	       BIT_SWAP(c,5,5) | BIT_SWAP(c,6,6);

     }

	 return true;

}



/**********************************************************************/



bool CGray::build_type_I_table()

{

     unsigned char	nbp;

     int	a, b, i, aa;



     TYPE_I_TAB = (unsigned char *) new unsigned char[1<<12];

	if (!TYPE_I_TAB) return false;



     /* Loop over all possibilities of A and B. */

     for (a=0, i=0; a<(1<<6); a++)

	  for (b=0; b<(1<<6); b++, i++) {

	       

	       /* For each white-voxel neighbor of A, check

		* if there are any white-voxel neighbors of B

		* that are 26-nb adjacent. */

	       for (aa=0, nbp=0; (aa<6) && (nbp==0); aa++) {

		    if (a&(1<<aa)) {

			 nbp = ((((int)type_I_26nb[aa])&b)!=0);

		    }

	       }

	       TYPE_I_TAB[i] = nbp;

	  }

	  return true;

}



/**********************************************************************/



bool CGray::build_type_II_table()

{

     unsigned char	nbp;

     int	a, b, i, aa;



     TYPE_II_TAB = (unsigned char *) new unsigned char[1<<12];

	if (!TYPE_II_TAB) return false;



     /* Loop over all possibilities of A and B. */

     for (a=0, i=0; a<(1<<6); a++)

	  for (b=0; b<(1<<6); b++, i++) {

	       

	       /* A=5-1, B=2-1, is not a feasible combination. */

	       if ((a&(1<<4)) && (b&(1<<1)))

		    nbp = 0;

	       else {

		    /* For each white-voxel neighbor of A, check

		     * if there are any white-voxel neighbors of B

		     * that are 26-nb adjacent or overlapping. */

		    nbp = 0;

		    for (aa=0; (aa<6) && (nbp==0); aa++) {

			 if (a&(1<<aa)) {

			      nbp = ((type_II_26nb[aa] & b)!=0);

			 }

		    }

	       }

	       TYPE_II_TAB[i] = nbp;

	  }

	  return true;

}

     

/**********************************************************************/



bool CGray::build_type_III_table()

{

     unsigned char	nbp;

     int	a, b, i, aa;



     TYPE_III_TAB = (unsigned char *) new unsigned char[1<<12];

	if (!TYPE_III_TAB) return false;



     /* Loop over all possibilities of A and B. */

     for (a=0, i=0; a<(1<<6); a++)

	  for (b=0; b<(1<<6); b++, i++) {



	       /* (A+1,B+1) = {(1,3), (2,4), (5,6)} are not

		* feasible combinations. */

	       if (((a&0x1) && (b&(1<<2))) ||

		   ((a&(1<<1)) && (b&(1<<3))) ||

		   ((a&(1<<4)) && (b&(1<<5))))

		    nbp = 0;

	       else {

		    /* For each white-voxel neighbor of A, check

		     * if there are any white-voxel neighbors of B

		     * that are 26-nb adjacent or overlapping. */

		    for (aa=0, nbp=0; (aa<6) && (nbp==0); aa++) {

			 if (a&(1<<aa)) {

			      nbp = ((type_III_26nb[aa] & b)!=0);

			 }

		    }

	       }

	       TYPE_III_TAB[i] = nbp;

	  }

	  return true;

}



/**********************************************************************/



/*

 * Computes the 6-nb code.  This is used in determining the 

 * connectivity of the first gray matter layer.  The 6 neighbors

 * of each gray matter voxel is checked to see if there is a

 * white matter voxel.  A 6-bit code is generated indicating

 * which of the 6 neighbors are white matter voxels.

 *

 * Feb 24th 1998 Robert Taylor

 * Added wm_mask parameter so selected white matter may be treated the same 

 * as unselected white matter

 */

int CGray::compute_wm_nbhd_code(unsigned char *class_vol, 

		     int xsize, int ysize, int zsize, 

		     int yskip, int zskip, 

		     int x, int y, int z, 

		     unsigned char wm_label,unsigned char wm_mask)

{

     unsigned char *classp;

     int	nbhd;



     classp = class_vol + z*zskip + y*yskip + x;

     nbhd = 0;



     if (x>0) {	     		/* Position 4 */

	  if ( ((*(classp-1))&wm_mask)==wm_label) {

	       nbhd |= (1<<3);

	  }

     }

     if (x<xsize-1) {	     	/* Position 2 */

	  if (((*(classp+1))&wm_mask)==wm_label) {

	       nbhd |= (1<<1);

	  }

     }

     if (y>0) {			/* Position 3 */

	  if (((*(classp-yskip))&wm_mask)==wm_label) {

	       nbhd |= (1<<2);

	  }

     }

     if (y<ysize-1) {		/* Position 1 */

	  if (((*(classp+yskip))&wm_mask)==wm_label) {

	       nbhd |= 1;

	  }

     }

     if (z>0) {			/* Position 6 */

	  if (((*(classp-zskip))&wm_mask)==wm_label) {

	       nbhd |= (1<<5);

	  }

     }

     if (z<zsize-1) {		/* Position 5 */

	  if (((*(classp+zskip))&wm_mask)==wm_label) {

	       nbhd |= (1<<4);

	  }

     }



     return( nbhd );

}



/**********************************************************************/

/*	These macros establish new links between gray matter voxels.



// The DYNAMIC_NEIGHBOURS alternative uses less memory with

// some performance overhead



*/

#ifdef DYNAMIC_NEIGHBOURS



// Note - since we get at least 16 bytes when we allocate, go in multiples of 4

#define ADD_NEIGHBOUR(gm,val) {\
	int a = ++(gm->num_gm_nbhrs);\
	if ((a%4)==1) {/* Broke a new set of 4? */\
		int *tmp = new int[a+3];/* Allocate new set */\
		if (!tmp) MemoryOK=false;\
		else {\
			if (--a) { /* Some to copy */\
				CopyMemory(tmp,gm->gm_nbhrs,a*sizeof(*tmp));\
				delete gm->gm_nbhrs;\
			}\
			gm->gm_nbhrs=tmp;\
		}\
	} else a--;\
	if (MemoryOK) gm->gm_nbhrs[a]=val;\

}



#define LINK_VOXELS {\
	ADD_NEIGHBOUR(gmA,bindex);\
	ADD_NEIGHBOUR(gmB,aindex);\

}



#define CHECK_INDEX(index,type_tab)	\
	if (type_tab[index]) {\
		LINK_VOXELS;\
		links++;\
     }



#else // traditional way...



#define LINK_VOXELS				\
	  gmA->gm_nbhrs[gmA->num_gm_nbhrs]	\
	       = bindex;			\
	  gmA->num_gm_nbhrs++;			\
	  gmB->gm_nbhrs[gmB->num_gm_nbhrs]	\
	       = aindex;			\
	  gmB->num_gm_nbhrs++;



#define CHECK_INDEX(index,type_tab) 		\
     if (type_tab[index]) {			\
	  gmA->gm_nbhrs[gmA->num_gm_nbhrs]	\
	       = bindex;			\
	  gmA->num_gm_nbhrs++;			\
	  gmB->gm_nbhrs[gmB->num_gm_nbhrs]	\
	       = aindex;			\
	  gmB->num_gm_nbhrs++;			\
	  links++;				\
     }

#endif

/*

 * Computes all the gray matter neighbors within the first 

 * gray matter layer.  Two 26-nb adjacent gray matter voxels

 * are considered to be connected if either (a) they have a

 * common 6-nb white matter parent or (b) they have 6-nb white 

 * matter parents that are 26-nb adjacent.  In addition,

 * connecting the two gray matter voxels cannot introduce

 * an intersection with an exisiting white matter surface.

 * The problem in 2D is:

 *

 *		G W

 *		W G

 *

 * Connected the two G voxels will result in a G digital line that

 * intersects with a W digital line.  The problem in 3D arise from the

 * three different possibilites of constructing diagonals.  Since the

 * total number of different white matter configurations around two

 * gray matter voxels is 2^6*2^6=2^12.  All possible configurations

 * are precomputed and checked.  On-line checking simply involves

 * looking up a boolean table of 2^12 entries. 

 */



bool CGray::first_gray_layer_connectivity(GrayMatter *gm)

{

	// For the allocation error trap

	bool MemoryOK=true;



	int	i, x, y, z, xsize, ysize, zsize, yskip, zskip;

	int	index, aindex, bindex;

	int	voi_xmin, voi_ymin, voi_zmin;

	int	*inv_gm_table;

	GrayVoxel	*gm_array, *gmA, *gmB;

	int	links=0;



	/* Initialize. */

	gm_array = gm->gm_array;

	inv_gm_table = gm->inv_gm_table;

	voi_xmin = gm->voi_xmin;

	voi_ymin = gm->voi_ymin;

	voi_zmin = gm->voi_zmin;

	xsize = gm->voi_xmax-voi_xmin+1;

	ysize = gm->voi_ymax-voi_ymin+1;

	zsize = gm->voi_zmax-voi_zmin+1;

	yskip = xsize;

	zskip = xsize*ysize;



	/* Argh!  All this bounds checking should be removed by

	* introducing a one-layer boundary of sentinels in

	* inv_gm_table! */



	/* Loop over all gray matter voxels. */

	for (i=0; i<gm->gm_size; i++)

		if (gm_array[i].layer==1) {



			aindex = i;

			gmA = &gm_array[i];

			x = gmA->x-voi_xmin; 

			y = gmA->y-voi_ymin; 

			z = gmA->z-voi_zmin;



			/* TYPE I: Position x+1,y,z */

			if (x<xsize-1) {

				bindex = inv_gm_table[z*zskip+y*yskip+(x+1)];

				if ((bindex>=0) && (gm_array[bindex].layer==1)) {

					gmB = &gm_array[bindex];



					index = (int) gmA->nbhd_code;

					index <<= 6;

					index |= (int) gmB->nbhd_code;

					/* ASSERT((index>=0)&&(index<(1<<12)));*/



					CHECK_INDEX(index,TYPE_I_TAB);

					if (!MemoryOK) return false;

				}

			}



			/* TYPE I: Position x,y+1,z */

			if (y<ysize-1) {

				bindex = inv_gm_table[z*zskip+(y+1)*yskip+x];

				if ((bindex>=0) && (gm_array[bindex].layer==1)) {

					gmB = &gm_array[bindex];



					index = (int) ROTTAB_ZCCW[gmA->nbhd_code];

					index <<= 6;

					index |= (int) ROTTAB_ZCCW[gmB->nbhd_code];

					/* ASSERT((index>=0)&&(index<(1<<12)));*/



					if (!MemoryOK) return false;

					CHECK_INDEX(index,TYPE_I_TAB);

				}

			}



			/* TYPE I: Position x,y,z+1 */

			if (z<zsize-1) {

				bindex = inv_gm_table[(z+1)*zskip+y*yskip+x];

				if ((bindex>=0) && (gm_array[bindex].layer==1)) {

					gmB = &gm_array[bindex];



					index = (int) ROTTAB_YCW[gmA->nbhd_code];

					index <<= 6;

					index |= (int) ROTTAB_YCW[gmB->nbhd_code];

					/* ASSERT((index>=0)&&(index<(1<<12)));*/



					CHECK_INDEX(index,TYPE_I_TAB);

					if (!MemoryOK) return false;

				}

			}



			/* TYPE II: Position x+1,y,z+1 */

			if ((x<xsize-1) && (z<zsize-1)) {

				bindex = inv_gm_table[(z+1)*zskip+y*yskip+(x+1)];

				if ((bindex>=0) && (gm_array[bindex].layer==1)) {

					gmB = &gm_array[bindex];



					index = (int) gmA->nbhd_code;

					index <<= 6;

					index |= (int) gmB->nbhd_code;

					/* ASSERT((index>=0)&&(index<(1<<12)));*/



					CHECK_INDEX(index,TYPE_II_TAB);

					if (!MemoryOK) return false;

				}

			}



			/* TYPE II: Position x-1,y,z+1 */

			if ((x>0) && (z<zsize-1)) {

				bindex = inv_gm_table[(z+1)*zskip+y*yskip+(x-1)];

				if ((bindex>=0) && (gm_array[bindex].layer==1)) {

					gmB = &gm_array[bindex];



					index = (int) ROTTAB_YCW[gmA->nbhd_code];

					index <<= 6;

					index |= (int) ROTTAB_YCW[gmB->nbhd_code];

					/* ASSERT((index>=0)&&(index<(1<<12)));*/



					CHECK_INDEX(index,TYPE_II_TAB);

					if (!MemoryOK) return false;

				}

			}



			/* TYPE II: Position x,y-1,z+1 */

			if ((y>0) && (z<zsize-1)) {

				bindex = inv_gm_table[(z+1)*zskip+(y-1)*yskip+x];

				if ((bindex>=0) && (gm_array[bindex].layer==1)) {

					gmB = &gm_array[bindex];



					index = (int) ROTTAB_ZCW[gmA->nbhd_code];

					index <<= 6;

					index |= (int) ROTTAB_ZCW[gmB->nbhd_code];

					/* ASSERT((index>=0)&&(index<(1<<12)));*/



					CHECK_INDEX(index,TYPE_II_TAB);

					if (!MemoryOK) return false;

				}

			}



			/* TYPE II: Position x,y+1,z+1 */

			if ((y<ysize-1) && (z<zsize-1)) {

				bindex = inv_gm_table[(z+1)*zskip+(y+1)*yskip+x];

				if ((bindex>=0) && (gm_array[bindex].layer==1)) {

					gmB = &gm_array[bindex];



					index = (int) ROTTAB_ZCCW[gmA->nbhd_code];

					index <<= 6;

					index |= (int) ROTTAB_ZCCW[gmB->nbhd_code];

					/* ASSERT((index>=0)&&(index<(1<<12)));*/



					CHECK_INDEX(index,TYPE_II_TAB);

					if (!MemoryOK) return false;

				}

			}



			/* TYPE II: Position x-1,y+1,z */

			if ((x>0) && (y<ysize-1)) {

				bindex = inv_gm_table[z*zskip+(y+1)*yskip+(x-1)];

				if ((bindex>=0) &&	(gm_array[bindex].layer==1)) {

					gmB = &gm_array[bindex];



					/* Swap Aindex and Bindex. */

					index = (int) ROTTAB_XCCW[gmB->nbhd_code];

					index <<= 6;

					index |= (int) ROTTAB_XCCW[gmA->nbhd_code];

					/* ASSERT((index>=0)&&(index<(1<<12)));*/



					CHECK_INDEX(index,TYPE_II_TAB);

					if (!MemoryOK) return false;

				}

			}



			/* TYPE II: Position x+1,y+1,z */

			if ((x<xsize-1) && (y<ysize-1)) {

				bindex = inv_gm_table[z*zskip+(y+1)*yskip+(x+1)];

				if ((bindex>=0) && (gm_array[bindex].layer==1)) {

					gmB = &gm_array[bindex];



					index = (int) ROTTAB_XCW[gmA->nbhd_code];

					index <<= 6;

					index |= (int) ROTTAB_XCW[gmB->nbhd_code];

					/* ASSERT((index>=0)&&(index<(1<<12)));*/



					CHECK_INDEX(index,TYPE_II_TAB);

					if (!MemoryOK) return false;

				}

			}



			/* TYPE III: Position x+1,y+1,z+1 */

			if ((x<xsize-1) && (y<ysize-1) && (z<zsize-1)) {

				bindex = inv_gm_table[(z+1)*zskip+(y+1)*yskip+(x+1)];

				if ((bindex>=0) && (gm_array[bindex].layer==1)) {

					gmB = &gm_array[bindex];



					index = (int) gmA->nbhd_code;

					index <<= 6;

					index |= (int) gmB->nbhd_code;

					/* ASSERT((index>=0)&&(index<(1<<12)));*/



					CHECK_INDEX(index,TYPE_III_TAB);

					if (!MemoryOK) return false;

				}

			}



			/* TYPE III: Position x-1,y-1,z+1 */

			if ((x>0) && (y>0) && (z<zsize-1)) {

				bindex = inv_gm_table[(z+1)*zskip+(y-1)*yskip+(x-1)];

				if ((bindex>=0) && (gm_array[bindex].layer==1)) {

					gmB = &gm_array[bindex];



					/* Swap Aindex and Bindex. */

					index = (int) ROTTAB_XCW[gmB->nbhd_code];

					index <<= 6;

					index |= (int) ROTTAB_XCW[gmA->nbhd_code];

					/* ASSERT((index>=0)&&(index<(1<<12)));*/



					CHECK_INDEX(index,TYPE_III_TAB);

					if (!MemoryOK) return false;

				}

			}



			/* TYPE III: Position x+1,y-1,z+1 */

			if ((x<xsize-1) && (y>0) && (z<zsize-1)) {

				bindex = inv_gm_table[(z+1)*zskip+(y-1)*yskip+(x+1)];

				if ((bindex>=0) && (gm_array[bindex].layer==1)) {

					gmB = &gm_array[bindex];



					index = (int) ROTTAB_ZCW[gmA->nbhd_code];

					index <<= 6;

					index |= (int) ROTTAB_ZCW[gmB->nbhd_code];

					/* ASSERT((index>=0)&&(index<(1<<12)));*/



					CHECK_INDEX(index,TYPE_III_TAB);

					if (!MemoryOK) return false;

				}

			}



			/* TYPE III: Position x-1,y+1,z+1 */

			if ((x>0) && (y<ysize-1) && (z<zsize-1)) {

				bindex = inv_gm_table[(z+1)*zskip+(y+1)*yskip+(x-1)];

				if ((bindex>=0) && (gm_array[bindex].layer==1)) {

					gmB = &gm_array[bindex];



					index = (int) ROTTAB_ZCCW[gmA->nbhd_code];

					index <<= 6;

					index |= (int) ROTTAB_ZCCW[gmB->nbhd_code];

					/* ASSERT((index>=0)&&(index<(1<<12)));*/



					CHECK_INDEX(index,TYPE_III_TAB);

					if (!MemoryOK) return false;

				}

			}

		}



	return true;

}



/**********************************************************************/

/**********************************************************************/



/* 

 * Returns true if adding a gray matter voxel causes contention.

 * Contention occurs when two unconnected white matter voxels

 * can claim the same voxel as a gray matter voxel.

 */

int CGray::white_grow_contendp(int grayx, int grayy, int grayz, unsigned char wm_label, unsigned char wm_mask,

		    int orient, GrayMatter *gm)

{

	if (!m_ContendWhite) return 0; // If not checking, always "No Contention"



	// Feb 24th 1998 Robert Taylor

	// Added wm_mask parameter so selected white matter may be treated the same 

	// as unselected white matter

     unsigned char *cvolp;

     int	x, y, z, xmin, xmax, ymin, ymax, zmin, zmax;

     int	cvol_xinc, cvol_yinc, cvol_zinc;



     /* Set up variables in canonical form. */

     switch( orient ) {

     case CONNECT_XPLUS:

     case CONNECT_XMINUS:

	  if (orient==CONNECT_XPLUS) grayx++; else grayx--;

	  x = grayx; y = grayy; z = grayz;

	  cvol_xinc = (orient==CONNECT_XPLUS) ? 1 : -1; 

	  cvol_yinc = gm->mrvol->yskip; cvol_zinc = gm->mrvol->zskip;

	  xmin = gm->voi_xmin; xmax = gm->voi_xmax;

	  ymin = gm->voi_ymin; ymax = gm->voi_ymax;

	  zmin = gm->voi_zmin; zmax = gm->voi_zmax;

	  break;

     case CONNECT_YPLUS:

     case CONNECT_YMINUS:

	  if (orient==CONNECT_YPLUS) grayy++; else grayy--;

	  x = grayy; y = grayx; z = grayz;

	  cvol_xinc = (orient==CONNECT_YPLUS) ? 

	       gm->mrvol->yskip : -gm->mrvol->yskip; 

	  cvol_yinc = 1; cvol_zinc = gm->mrvol->zskip;

	  xmin = gm->voi_ymin; xmax = gm->voi_ymax;

	  ymin = gm->voi_xmin; ymax = gm->voi_xmax;

	  zmin = gm->voi_zmin; zmax = gm->voi_zmax;

	  break;

     case CONNECT_ZPLUS:

     case CONNECT_ZMINUS:

	  if (orient==CONNECT_ZPLUS) grayz++; else grayz--;

	  x = grayz; y = grayx; z = grayy;

	  cvol_xinc = (orient==CONNECT_ZPLUS) ? 

	       gm->mrvol->zskip : -gm->mrvol->zskip; 

	  cvol_yinc = 1; cvol_zinc = gm->mrvol->yskip;

	  xmin = gm->voi_zmin; xmax = gm->voi_zmax;

	  ymin = gm->voi_xmin; ymax = gm->voi_xmax;

	  zmin = gm->voi_ymin; zmax = gm->voi_ymax;

	  break;

     }

     cvolp = gm->mrvol->cvol + grayx + grayy*gm->mrvol->yskip +

	  grayz*gm->mrvol->zskip;



     /* Check if opposite voxel is filled; if not, there will

      * not be any contention.  Otherwise, one of the four

      * adjacent neighbors must be present. */

     if ((((cvol_xinc>0) && (x<xmax)) || 

	  ((cvol_xinc<0) && (x>xmin))) &&

	 ((cvolp[cvol_xinc]&wm_mask)==wm_label)) {

	  if ((y>ymin) && ((cvolp[-cvol_yinc]&wm_mask)==wm_label)) return( 0 );

	  if ((y<ymax) && ((cvolp[cvol_yinc]&wm_mask)==wm_label)) return( 0 );

	  if ((z>zmin) && ((cvolp[-cvol_zinc]&wm_mask)==wm_label)) return( 0 );

	  if ((z<zmax) && ((cvolp[cvol_zinc]&wm_mask)==wm_label)) return( 0 );

	  return( 1 );		/* contention */

     }

     return( 0 );		/* no contention */

}



/**********************************************************************/



/*

 * Finds white boundary where gray matter is going to be grown

 */

int CGray::find_white_boundary(GrayMatter *gm,

			 unsigned char wm_label, unsigned char wm_mask, unsigned char gm_label, unsigned char bg_label)

{

     unsigned char *cvol, *cvolx, *cvoly, *cvolz;

     int	x, y, z, yskip, zskip;

     int	voi_xmin, voi_xmax, voi_ymin, voi_ymax;

     int	voi_zmin, voi_zmax;

     int	count=0;

     int    flag;

     

     ASSERT(!((wm_label==gm_label) || (wm_label==bg_label) || 

	      (bg_label==gm_label)));



     voi_xmin = gm->voi_xmin; voi_xmax = gm->voi_xmax;

     voi_ymin = gm->voi_ymin; voi_ymax = gm->voi_ymax;

     voi_zmin = gm->voi_zmin; voi_zmax = gm->voi_zmax;

     yskip = gm->mrvol->yskip; zskip = gm->mrvol->zskip;



     /* Initialize inverse table. */



     /* Grow. */

	cvol = gm->mrvol->cvol + voi_zmin*zskip + 

			voi_ymin*yskip + voi_xmin;



	for (z=voi_zmin, cvolz=cvol; z<=voi_zmax; z++, cvolz+=zskip)

		for (y=voi_ymin, cvoly=cvolz; y<=voi_ymax; y++, cvoly+=yskip)

	       for (x=voi_xmin, cvolx=cvoly; x<=voi_xmax; x++, cvolx++)

		    if (((*cvolx)&wm_mask)==wm_label) {

			 flag = 0;

			 /* Grow in x-direction. */

			 if ((flag == 0) && (x<voi_xmax)) { 	/* x-positive. */

			      if ((cvolx[1]==bg_label) &&

				  (!white_grow_contendp

				   (x,y,z,wm_label,wm_mask,CONNECT_XPLUS,gm))) {

				   /* Add new gray. */

				   cvolx[0] = gm_label;

                   flag = 1;

                   count++;

			      }

			 }

			 if ((flag == 0) && (x>voi_xmin)) {	/* x-minus. */

			      if ((cvolx[-1]==bg_label) &&

				  (!white_grow_contendp

				   (x,y,z,wm_label,wm_mask,CONNECT_XMINUS,gm))) {

				   /* Add new gray. */

				   cvolx[0] = gm_label;

                   flag = 1;

				   count++;

			      }

			 }



			 /* Grow in y-direction. */

			 if ((flag == 0) && (y<voi_ymax)) { 	/* y-positive. */

			      if ((cvolx[yskip]==bg_label) &&

				  (!white_grow_contendp

				   (x,y,z,wm_label,wm_mask,CONNECT_YPLUS,gm))) {

				   /* Add new gray. */

				   cvolx[0] = gm_label;

                   flag = 1;

				   count++;

			      }

			 } 

			 if ((flag == 0) && (y>voi_ymin)) {	/* y-minus. */

			      if ((cvolx[-yskip]==bg_label) &&

				  (!white_grow_contendp

				   (x,y,z,wm_label,wm_mask,CONNECT_YMINUS,gm))) {

				   /* Add new gray. */

				   cvolx[0] = gm_label;

                   flag = 1;

				   count++;

			      }

			 }



			 /* Grow in z-direction. */

			 if ((flag == 0) && (z<voi_zmax)) { 	/* z-positive. */

			      if ((cvolx[zskip]==bg_label) &&

				  (!white_grow_contendp

				   (x,y,z,wm_label,wm_mask,CONNECT_ZPLUS,gm))) {

				   /* Add new gray. */

				   cvolx[0] = gm_label;

                   flag = 1;

				   count++;

			      }

			 } 

			 if ((flag == 0) && (z>voi_zmin)) {	/* z-minus. */

			      if ((cvolx[-zskip]==bg_label) &&

				  (!white_grow_contendp

				   (x,y,z,wm_label,wm_mask,CONNECT_ZMINUS,gm))) {

				   /* Add new gray. */

				   cvolx[0] = gm_label;

                   flag = 1;

				   count++;

			      }

			 }

		    }

     return( count );

}



/**********************************************************************/



/*

 * Finds white matter

 */

int CGray::find_white_matter(GrayMatter *gm,

			 unsigned char wm_label, unsigned char wm_mask, unsigned char gm_label, unsigned char bg_label)

{

     unsigned char *cvol, *cvolx, *cvoly, *cvolz;

     int	x, y, z, yskip, zskip;

     int	voi_xmin, voi_xmax, voi_ymin, voi_ymax;

     int	voi_zmin, voi_zmax;

     int	count=0;

     int    flag;

     

     ASSERT(!((wm_label==gm_label) || (wm_label==bg_label) || 

	      (bg_label==gm_label)));



     voi_xmin = gm->voi_xmin; voi_xmax = gm->voi_xmax;

     voi_ymin = gm->voi_ymin; voi_ymax = gm->voi_ymax;

     voi_zmin = gm->voi_zmin; voi_zmax = gm->voi_zmax;

     yskip = gm->mrvol->yskip; zskip = gm->mrvol->zskip;



     /* Initialize inverse table. */



     /* Grow. */

	cvol = gm->mrvol->cvol + voi_zmin*zskip + 

			voi_ymin*yskip + voi_xmin;



	for (z=voi_zmin, cvolz=cvol; z<=voi_zmax; z++, cvolz+=zskip)

		for (y=voi_ymin, cvoly=cvolz; y<=voi_ymax; y++, cvoly+=yskip)

	       for (x=voi_xmin, cvolx=cvoly; x<=voi_xmax; x++, cvolx++)

		      if (((*cvolx)&wm_mask)==wm_label) {

			 	   cvolx[0] = gm_label;

                   count++;

              }

                   

     return( count );

}



/**********************************************************************/



/*

 * Grow out one layer from the white matter boundary ('wm_label')

 * according to 6-nb connectivity.  The background class has label

 * 'bg_label'.  The new boundary is given label 'gm_label'.  The three

 * labels cannot be the same.   Only gray matter voxels that do

 * not cause contention are added.  Return the total number of

 * gray matter voxels added.

 *

 * Robert Taylor 24th February 1998 - Added wm_mask so that selected 

 * white matter may be treated in the same manner as unselected white matter.

 */

int CGray::grow_from_white_boundary(GrayMatter *gm,

			 unsigned char wm_label, unsigned char wm_mask, unsigned char gm_label, unsigned char bg_label)

{

     unsigned char *cvol, *cvolx, *cvoly, *cvolz;

     int	x, y, z, yskip, zskip;

     int	voi_xmin, voi_xmax, voi_ymin, voi_ymax;

     int	voi_zmin, voi_zmax;

     int	count=0;



     ASSERT(!((wm_label==gm_label) || (wm_label==bg_label) || 

	      (bg_label==gm_label)));



     voi_xmin = gm->voi_xmin; voi_xmax = gm->voi_xmax;

     voi_ymin = gm->voi_ymin; voi_ymax = gm->voi_ymax;

     voi_zmin = gm->voi_zmin; voi_zmax = gm->voi_zmax;

     yskip = gm->mrvol->yskip; zskip = gm->mrvol->zskip;



     /* Initialize inverse table. */



     /* Grow. */

	cvol = gm->mrvol->cvol + voi_zmin*zskip + 

			voi_ymin*yskip + voi_xmin;



	for (z=voi_zmin, cvolz=cvol; z<=voi_zmax; z++, cvolz+=zskip)

		for (y=voi_ymin, cvoly=cvolz; y<=voi_ymax; y++, cvoly+=yskip)

	       for (x=voi_xmin, cvolx=cvoly; x<=voi_xmax; x++, cvolx++)

		    if (((*cvolx)&wm_mask)==wm_label) {

			 

			 /* Grow in x-direction. */

			 if (x<voi_xmax) { 	/* x-positive. */

			      if ((cvolx[1]==bg_label) &&

				  (!white_grow_contendp

				   (x,y,z,wm_label,wm_mask,CONNECT_XPLUS,gm))) {

				   /* Add new gray. */

				   cvolx[1] = gm_label;

				   count++;

			      }

			 }

			 if (x>voi_xmin) {	/* x-minus. */

			      if ((cvolx[-1]==bg_label) &&

				  (!white_grow_contendp

				   (x,y,z,wm_label,wm_mask,CONNECT_XMINUS,gm))) {

				   /* Add new gray. */

				   cvolx[-1] = gm_label;

				   count++;

			      }

			 }



			 /* Grow in y-direction. */

			 if (y<voi_ymax) { 	/* y-positive. */

			      if ((cvolx[yskip]==bg_label) &&

				  (!white_grow_contendp

				   (x,y,z,wm_label,wm_mask,CONNECT_YPLUS,gm))) {

				   /* Add new gray. */

				   cvolx[yskip] = gm_label;

				   count++;

			      }

			 } 

			 if (y>voi_ymin) {	/* y-minus. */

			      if ((cvolx[-yskip]==bg_label) &&

				  (!white_grow_contendp

				   (x,y,z,wm_label,wm_mask,CONNECT_YMINUS,gm))) {

				   /* Add new gray. */

				   cvolx[-yskip] = gm_label;

				   count++;

			      }

			 }



			 /* Grow in z-direction. */

			 if (z<voi_zmax) { 	/* z-positive. */

			      if ((cvolx[zskip]==bg_label) &&

				  (!white_grow_contendp

				   (x,y,z,wm_label,wm_mask,CONNECT_ZPLUS,gm))) {

				   /* Add new gray. */

				   cvolx[zskip] = gm_label;

				   count++;

			      }

			 } 

			 if (z>voi_zmin) {	/* z-minus. */

			      if ((cvolx[-zskip]==bg_label) &&

				  (!white_grow_contendp

				   (x,y,z,wm_label,wm_mask,CONNECT_ZMINUS,gm))) {

				   /* Add new gray. */

				   cvolx[-zskip] = gm_label;

				   count++;

			      }

			 }

		    }

     return( count );

}



/**********************************************************************/



/*

 * Check to see if the two gray matter voxels are neighbors. 

 * That is, if one is in the neighbor list of the other.

 */

int CGray::is_connectedp(int index1, int index2,

			 GrayVoxel *gm_arr)

{

     GrayVoxel	*gv1;

     int	i;



     gv1 = &gm_arr[index1];

     for (i=0; i<gv1->num_gm_nbhrs; i++)

	  if ((gv1->gm_nbhrs)[i]==index2) return( 1 );

     

     return( 0 );

}



/* 

 * Returns true if adding a gray matter voxel causes contention.

 * Contention occurs when two unconnected gray matter voxels

 * can claim the same voxel as a gray matter voxel.  Note that

 * two 26-nb adjacent gray matter voxels can be unconnected.

 */

int CGray::gray_grow_contendp(int grayx, int grayy, int grayz, unsigned char gm_label,

		       int orient, GrayMatter *gm)

{

	if (!m_ContendGray) return 0;  // If not checking, always "No Contention"



	if (!m_Ok) return 0;



     unsigned char *cvolp;

     GrayVoxel	*gm_arr;

     int	*inv_gm_table, aindex, bindex;

     int	x, y, z, xsize, ysize, xinc, yinc, zinc;

     int	xmin, xmax, ymin, ymax, zmin, zmax;

     int	cvol_xinc, cvol_yinc, cvol_zinc;



     xsize = gm->voi_xmax-gm->voi_xmin+1;

     ysize = gm->voi_ymax-gm->voi_ymin+1;

     gm_arr = gm->gm_array;

     inv_gm_table = 

	  &(gm->inv_gm_table

	    [(grayx-gm->voi_xmin)+(grayy-gm->voi_ymin)*xsize+

	     (grayz-gm->voi_zmin)*xsize*ysize]);

     aindex = inv_gm_table[0];



     /* Set up variables in canonical form. */

     switch( orient ) {

     case CONNECT_XPLUS:

     case CONNECT_XMINUS:

	  if (orient==CONNECT_XPLUS) grayx++; else grayx--;

	  x = grayx; y = grayy; z = grayz;

	  xinc = (orient==CONNECT_XPLUS) ? 1 : -1;

	  yinc = xsize; zinc = xsize*ysize;

	  cvol_xinc = (orient==CONNECT_XPLUS) ? 1 : -1;

	  cvol_yinc = gm->mrvol->yskip; cvol_zinc = gm->mrvol->zskip;

	  xmin = gm->voi_xmin; xmax = gm->voi_xmax;

	  ymin = gm->voi_ymin; ymax = gm->voi_ymax;

	  zmin = gm->voi_zmin; zmax = gm->voi_zmax;

	  break;

     case CONNECT_YPLUS:

     case CONNECT_YMINUS:

	  if (orient==CONNECT_YPLUS) grayy++; else grayy--;

	  x = grayy; y = grayx; z = grayz;

	  xinc = (orient==CONNECT_YPLUS) ? xsize : -xsize;

	  yinc = 1; zinc = xsize*ysize;

	  cvol_xinc = (orient==CONNECT_YPLUS) ? 

	       gm->mrvol->yskip : -gm->mrvol->yskip; 

	  cvol_yinc = 1; cvol_zinc = gm->mrvol->zskip;

	  xmin = gm->voi_ymin; xmax = gm->voi_ymax;

	  ymin = gm->voi_xmin; ymax = gm->voi_xmax;

	  zmin = gm->voi_zmin; zmax = gm->voi_zmax;

	  break;

     case CONNECT_ZPLUS:

     case CONNECT_ZMINUS:

	  if (orient==CONNECT_ZPLUS) grayz++; else grayz--;

	  x = grayz; y = grayx; z = grayy;

	  xinc = (orient==CONNECT_ZPLUS) ? 

	       xsize*ysize : -xsize*ysize;

	  yinc = 1; zinc = xsize;

	  cvol_xinc = (orient==CONNECT_ZPLUS) ? 

	       gm->mrvol->zskip : -gm->mrvol->zskip; 

	  cvol_yinc = 1; cvol_zinc = gm->mrvol->yskip;

	  xmin = gm->voi_zmin; xmax = gm->voi_zmax;

	  ymin = gm->voi_xmin; ymax = gm->voi_xmax;

	  zmin = gm->voi_ymin; zmax = gm->voi_ymax;

	  break;

     }

     cvolp = gm->mrvol->cvol + grayx + grayy*gm->mrvol->yskip +

	  grayz*gm->mrvol->zskip;

     inv_gm_table = 

	  &(gm->inv_gm_table

	    [(grayx-gm->voi_xmin)+(grayy-gm->voi_ymin)*xsize+

	     (grayz-gm->voi_zmin)*xsize*ysize]);



     /* Check 4 adjacent neighbors -- for each one that

      * is gray, it should also share a common parent with

      * the original (grayx, grayy, grayz).  Otherwise, we get

      * contention. */

     if ((y>ymin) && (cvolp[-cvol_yinc]==gm_label)) {

	  bindex = inv_gm_table[-yinc];

	  if (!(is_connectedp(aindex,bindex,gm_arr)))

	       return( 1 );

     }

     if ((y<ymax) && (cvolp[cvol_yinc]==gm_label)) {

	  bindex = inv_gm_table[yinc];

	  if (!(is_connectedp(aindex,bindex,gm_arr)))

	       return( 1 );

     }

     if ((z>zmin) && (cvolp[-cvol_zinc]==gm_label)) {

	  bindex = inv_gm_table[-zinc];

	  if (!(is_connectedp(aindex,bindex,gm_arr)))

	       return( 1 );

     }

     if ((z<zmax) && (cvolp[cvol_zinc]==gm_label)) {

	  bindex = inv_gm_table[zinc];

	  if (!(is_connectedp(aindex,bindex,gm_arr)))

	       return( 1 );

     }



     /* Check opposite voxel.  If it is gray, then it has to

      * share a parent with one of the 4 adjacent neighbors. */

     if ((((xinc>0) && (x<xmax)) || ((xinc<0) && (x>xmin))) &&

	 (cvolp[cvol_xinc]==gm_label)) {



	  if ((y>ymin) && (cvolp[-cvol_yinc]==gm_label)) {

	       bindex = inv_gm_table[-yinc];

	       if (!(is_connectedp(aindex,bindex,gm_arr)))

		    return( 0 );

	  }

	  if ((y<ymax) && (cvolp[cvol_yinc]==gm_label)) {

	       bindex = inv_gm_table[yinc];

	       if (!(is_connectedp(aindex,bindex,gm_arr)))

		    return( 0 );

	  }

	  if ((z>zmin) && (cvolp[-cvol_zinc]==gm_label)) {

	       bindex = inv_gm_table[-zinc];

	       if (!(is_connectedp(aindex,bindex,gm_arr)))

		    return( 0 );

	  }

	  if ((z<zmax) && (cvolp[cvol_zinc]==gm_label)) {

	       bindex = inv_gm_table[zinc];

	       if (!(is_connectedp(aindex,bindex,gm_arr)))

		    return( 0 );

	  }

	  return( 1 );

     }

     return( 0 );

}



/**********************************************************************/



/*

 * Grow out one layer from the white matter boundary ('wm_label')

 * according to 6-neighborhood connectivity.  The background class has

 * label 'bg_label'.  The new boundary is given label 'gm_label'.  The

 * three labels cannot be the same.  Only gray matter voxels that do

 * not cause contention are added.  Return the total number of gray

 * matter voxels added.

 */

 int CGray::grow_from_gray_boundary(GrayMatter *gm,

			unsigned char gm_label1, unsigned char gm_label2, unsigned char bg_label)

{

     unsigned char *cvol, *cvolx, *cvoly, *cvolz;

     int	x, y, z, yskip, zskip;

     int	voi_xmin, voi_xmax, voi_ymin, voi_ymax;

     int	voi_zmin, voi_zmax;

     int	count=0;



     ASSERT(!((gm_label1==gm_label2) || (gm_label1==bg_label) || 

	      (bg_label==gm_label2)));



     voi_xmin = gm->voi_xmin; voi_xmax = gm->voi_xmax;

     voi_ymin = gm->voi_ymin; voi_ymax = gm->voi_ymax;

     voi_zmin = gm->voi_zmin; voi_zmax = gm->voi_zmax;

     yskip = gm->mrvol->yskip; zskip = gm->mrvol->zskip;



     /* Initialize inverse table. */



     /* Grow. */

     cvol = gm->mrvol->cvol + voi_zmin*zskip + voi_ymin*yskip + voi_xmin;

     for (z=voi_zmin, cvolz=cvol; z<=voi_zmax; z++, cvolz+=zskip)

	  for (y=voi_ymin, cvoly=cvolz; y<=voi_ymax; y++, cvoly+=yskip)

	       for (x=voi_xmin, cvolx=cvoly; x<=voi_xmax; x++, cvolx++)

		    if ((*cvolx)==gm_label1) {

			 

			 /* Grow in x-direction. */

			 if (x<voi_xmax) { 	/* x-positive. */

			      if ((cvolx[1]==bg_label) &&

				  (!gray_grow_contendp

				   (x,y,z,gm_label1,CONNECT_XPLUS,gm))) {

				   /* Add new gray. */

				   cvolx[1] = gm_label2;

				   count++;

			      }

			 }

			 if (x>voi_xmin) {	/* x-minus. */

			      if ((cvolx[-1]==bg_label) &&

				  (!gray_grow_contendp

				   (x,y,z,gm_label1,CONNECT_XMINUS,gm))) {

				   /* Add new gray. */

				   cvolx[-1] = gm_label2;

				   count++;

			      }

			 }



			 /* Grow in y-direction. */

			 if (y<voi_ymax) { 	/* y-positive. */

			      if ((cvolx[yskip]==bg_label) &&

				  (!gray_grow_contendp

				   (x,y,z,gm_label1,CONNECT_YPLUS,gm))) {

				   /* Add new gray. */

				   cvolx[yskip] = gm_label2;

				   count++;

			      }

			 } 

			 if (y>voi_ymin) {	/* y-minus. */

			      if ((cvolx[-yskip]==bg_label) &&

				  (!gray_grow_contendp

				   (x,y,z,gm_label1,CONNECT_YMINUS,gm))) {

				   /* Add new gray. */

				   cvolx[-yskip] = gm_label2;

				   count++;

			      }

			 }



			 /* Grow in z-direction. */

			 if (z<voi_zmax) { 	/* z-positive. */

			      if ((cvolx[zskip]==bg_label) &&

				  (!gray_grow_contendp

				   (x,y,z,gm_label1,CONNECT_ZPLUS,gm))) {

				   /* Add new gray. */

				   cvolx[zskip] = gm_label2;

				   count++;

			      }

			 } 

			 if (z>voi_zmin) {	/* z-minus. */

			      if ((cvolx[-zskip]==bg_label) &&

				  (!gray_grow_contendp

				   (x,y,z,gm_label1,CONNECT_ZMINUS,gm))) {

				   /* Add new gray. */

				   cvolx[-zskip] = gm_label2;

				   count++;

			      }

			 }

		    }

     return( count );

}



/**********************************************************************/



/*

 * Check to see if either (a) the two gray matter voxels share a

 * common parent, or (b) have parents that are connected.

 */

int CGray::is_connected2p(int index1, int index2,

			  GrayVoxel *gm_arr)

{

     GrayVoxel	*gv1, *gvparent1;

     int	i, j, parent1;



     gv1 = &gm_arr[index1];

     

     /* Check if index1 and index2 gray voxels share

      * a common parent. */

     /*for (i=0; i<gv1->num_gm_nbhrs; i++)

	  if ((gv1->gm_nbhrs)[i]==index2)

          return( 1 );*/



     /* Check if index1 and index2 gray voxels have parents

      * that are connected. */

     for (i=0; i<gv1->num_gm_nbhrs; i++) {

	  parent1 = (gv1->gm_nbhrs)[i];

	  gvparent1 = &gm_arr[parent1];

      if (gvparent1->layer == gv1->layer - 1) {

    	  for (j=0; j<gvparent1->num_gm_nbhrs; j++)

               if ((gvparent1->gm_nbhrs)[j]==index2)    

                    return( 1 );

      }

           

     }

     

     /* Temptative to fix this test */

     int k, parent2;

     GrayVoxel *gv2,*gvparent2;

     for (i = 0;i < gv1->num_gm_nbhrs;i++) {

         parent1 = (gv1->gm_nbhrs)[i];

         gvparent1 = &gm_arr[parent1];

         if (gvparent1->layer == gv1->layer - 1) {

             for (j = 0;j < gvparent1->num_gm_nbhrs;j++) {

                 parent2 = (gvparent1->gm_nbhrs)[j];

                 gvparent2 = &gm_arr[parent2];

                 if (gvparent2->layer == gvparent1->layer) {

                     for (k = 0;k < gvparent2->num_gm_nbhrs;k++) {

                         if ((gvparent2->gm_nbhrs)[k]==index2)

                             return (1);

                     }

                 }

             }

         }

     }

              

     return( 0 );

     

}



/*

 * Check to see if either (a) the two gray matter voxels share a

 * common parent, or (b) have sons that are connected.

 */

int CGray::is_connected2s(int index1, int index2,

			  GrayVoxel *gm_arr)

{

     GrayVoxel	*gv1, *gvparent1;

     int	i, j, parent1;



     gv1 = &gm_arr[index1];

     

     /* Check if index1 and index2 gray voxels share

      * a common parent. */

     /*for (i=0; i<gv1->num_gm_nbhrs; i++)

	  if ((gv1->gm_nbhrs)[i]==index2)

          return( 1 );*/



     /* Check if index1 and index2 gray voxels have parents

      * that are connected. */

     for (i=0; i<gv1->num_gm_nbhrs; i++) {

	  parent1 = (gv1->gm_nbhrs)[i];

	  gvparent1 = &gm_arr[parent1];

      if (gvparent1->layer == gv1->layer + 1) {

    	  for (j=0; j<gvparent1->num_gm_nbhrs; j++)

               if ((gvparent1->gm_nbhrs)[j]==index2)    

                    return( 1 );

      }

           

     }

     

     /* Temptative to fix this test */

     int k, parent2;

     GrayVoxel *gv2,*gvparent2;

     for (i = 0;i < gv1->num_gm_nbhrs;i++) {

         parent1 = (gv1->gm_nbhrs)[i];

         gvparent1 = &gm_arr[parent1];

         if (gvparent1->layer == gv1->layer + 1) {

             for (j = 0;j < gvparent1->num_gm_nbhrs;j++) {

                 parent2 = (gvparent1->gm_nbhrs)[j];

                 gvparent2 = &gm_arr[parent2];

                 if (gvparent2->layer == gvparent1->layer) {

                     for (k = 0;k < gvparent2->num_gm_nbhrs;k++) {

                         if ((gvparent2->gm_nbhrs)[k]==index2)

                             return (1);

                     }

                 }

             }

         }

     }

              

     return( 0 );

     

}





/*

 * Computes all the gray matter neighbors within the second or

 * subsequent layers.  Two 26-nb adjacent gray matter voxels are

 * considered to be connected if either (a) they have a common 6-nb

 * gray matter parent or (b) they have 6-nb gray matter parents that

 * are connected in the previous gray matter layer.  We assume

 * that there is no possibility of intersecting surfaces (as

 * described in first_gray_layer_connectivity()) for the second

 * and subsequent layers.

 */

bool CGray::zero_layer_connectivity(GrayMatter *gm, 

			int first_gv_index, int num_new_gv)

{

	// Offsets for inter-layer 6-nb connectivity between this

	// layer and the previous.

	static int inter_offsets[6][3] = {

		{+1, 0, 0}, { 0,+1, 0}, { 0, 0,+1}, 

		{-1, 0, 0}, { 0,-1, 0}, { 0, 0,-1}

	};

	// Offsets for intra-layer 26-nb connectivity.

	

     static int intra_offsets[13][3] = {

		{+1, 0, 0}, { 0,+1, 0}, { 0, 0,+1}, 

		{+1, 0,+1}, {-1, 0,+1}, { 0,-1,+1}, 

		{ 0,+1,+1}, {-1,+1, 0}, {+1,+1, 0}, 

		{+1,+1,+1}, {-1,-1,+1}, {+1,-1,+1}, 

		{-1,+1,+1}

	};

     

    

	// For the allocation error trap...

	bool MemoryOK=true;



	int	i, j, x, y, z, xsize, ysize, zsize, yskip, zskip;

	int	newx, newy, newz, aindex, bindex;

	int	voi_xmin, voi_ymin, voi_zmin, voi_xmax, voi_ymax, voi_zmax;

	GrayVoxel	*gm_array, *gmA, *gmB;

	int	*inv_gm_table;



	gm_array = gm->gm_array;

	inv_gm_table = gm->inv_gm_table;

	voi_xmin = gm->voi_xmin; voi_xmax = gm->voi_xmax;

	voi_ymin = gm->voi_ymin; voi_ymax = gm->voi_ymax;

	voi_zmin = gm->voi_zmin; voi_zmax = gm->voi_zmax;

	xsize = gm->voi_xmax-voi_xmin+1;

	ysize = gm->voi_ymax-voi_ymin+1;

	zsize = gm->voi_zmax-voi_zmin+1;

	yskip = xsize;

	zskip = xsize*ysize;     



	/* Inter-layer connectivity.  Loop over all new gray matter

	* voxels and establish links to their 6-nb parents.  Need to

	* determine these links first because these links are used to

	* determine intra-layer connectivity subsequently.  We can be

	* sure that no gray-matter voxel can belong to two parents

	* on opposite sides of the sulcus since this would imply

	* a contention which is checked for during the growing process. */

	for (i=first_gv_index; i<first_gv_index+num_new_gv; i++) {

		aindex = i;

		gmA = &gm_array[aindex];

		x = gmA->x; y = gmA->y; z = gmA->z;



		/* Loop over all 6 neighbors. */

		for (j=0; j<6; j++) {

			newx = x+inter_offsets[j][0];

			newy = y+inter_offsets[j][1];

			newz = z+inter_offsets[j][2];

			if ((newx>=voi_xmin) && (newx<=voi_xmax) &&

			(newy>=voi_ymin) && (newy<=voi_ymax) &&

			(newz>=voi_zmin) && (newz<=voi_zmax)) {

				bindex = inv_gm_table[

					(newx-voi_xmin)+

					(newy-voi_ymin)*xsize+

					(newz-voi_zmin)*xsize*ysize];

                if (bindex!=-1) {

					/* Inter-layer connectivity. */

					gmB = &gm_array[bindex];

                    if (gmA->layer+1==gmB->layer) {

                    LINK_VOXELS;

                    if (!MemoryOK) return false;

					}

				}

			}

		}

	}



	/* Intra-layer connectivity.  Loop over all new gray matter

	* voxels again and establish links to their 26-nb siblings in

	* the current layer. */

	

     for (i=first_gv_index; i<first_gv_index+num_new_gv; i++) {

		aindex = i;

		gmA = &gm_array[aindex];

		x = gmA->x; y = gmA->y; z = gmA->z;



		// Loop over all 26 neighbors (actually, because of

		// symmetry, we need to do it only over 13 neighbors). 

		for (j=0; j<13; j++) {

			newx = x+intra_offsets[j][0];

			newy = y+intra_offsets[j][1];

			newz = z+intra_offsets[j][2];

			if ((newx>=voi_xmin) && (newx<=voi_xmax) &&

				(newy>=voi_ymin) && (newy<=voi_ymax) &&

				(newz>=voi_zmin) && (newz<=voi_zmax)) {



				bindex = inv_gm_table[(newx-voi_xmin)+

				(newy-voi_ymin)*xsize+

				(newz-voi_zmin)*xsize*ysize];

				if (bindex!=-1) {

					// Intra-layer connectivity.

					// Check if aindex and bindex voxels have a

					// common parent or connected parents. 

					gmB = &gm_array[bindex];

                    

					if ((gmA->layer==gmB->layer)) {



						//LINK_VOXELS;

						if (!MemoryOK) return false;



					}

				}

			}

		}

	}

	return true;

}



/*************************************************************************/

bool CGray::zero_layer_full_connectivity(GrayMatter *gm, 

			int first_gv_index, int num_new_gv)

{

	// Offsets for inter-layer 6-nb connectivity between this

	// layer and the previous.

	static int inter_offsets[6][3] = {

		{+1, 0, 0}, { 0,+1, 0}, { 0, 0,+1}, 

		{-1, 0, 0}, { 0,-1, 0}, { 0, 0,-1}

	};

	// Offsets for intra-layer 26-nb connectivity.

	

     static int intra_offsets[13][3] = {

		{+1, 0, 0}, { 0,+1, 0}, { 0, 0,+1}, 

		{+1, 0,+1}, {-1, 0,+1}, { 0,-1,+1}, 

		{ 0,+1,+1}, {-1,+1, 0}, {+1,+1, 0}, 

		{+1,+1,+1}, {-1,-1,+1}, {+1,-1,+1}, 

		{-1,+1,+1}

	};

     

    

	// For the allocation error trap...

	bool MemoryOK=true;



	int	i, j, x, y, z, xsize, ysize, zsize, yskip, zskip;

	int	newx, newy, newz, aindex, bindex;

	int	voi_xmin, voi_ymin, voi_zmin, voi_xmax, voi_ymax, voi_zmax;

	GrayVoxel	*gm_array, *gmA, *gmB;

	int	*inv_gm_table;



	gm_array = gm->gm_array;

	inv_gm_table = gm->inv_gm_table;

	voi_xmin = gm->voi_xmin; voi_xmax = gm->voi_xmax;

	voi_ymin = gm->voi_ymin; voi_ymax = gm->voi_ymax;

	voi_zmin = gm->voi_zmin; voi_zmax = gm->voi_zmax;

	xsize = gm->voi_xmax-voi_xmin+1;

	ysize = gm->voi_ymax-voi_ymin+1;

	zsize = gm->voi_zmax-voi_zmin+1;

	yskip = xsize;

	zskip = xsize*ysize;     



	/* Inter-layer connectivity.  Loop over all new gray matter

	* voxels and establish links to their 6-nb parents.  Need to

	* determine these links first because these links are used to

	* determine intra-layer connectivity subsequently.  We can be

	* sure that no gray-matter voxel can belong to two parents

	* on opposite sides of the sulcus since this would imply

	* a contention which is checked for during the growing process. */

	for (i=first_gv_index; i<first_gv_index+num_new_gv; i++) {

		aindex = i;

		gmA = &gm_array[aindex];

		x = gmA->x; y = gmA->y; z = gmA->z;



		/* Loop over all 6 neighbors. */

		for (j=0; j<6; j++) {

			newx = x+inter_offsets[j][0];

			newy = y+inter_offsets[j][1];

			newz = z+inter_offsets[j][2];

			if ((newx>=voi_xmin) && (newx<=voi_xmax) &&

			(newy>=voi_ymin) && (newy<=voi_ymax) &&

			(newz>=voi_zmin) && (newz<=voi_zmax)) {

				bindex = inv_gm_table[

					(newx-voi_xmin)+

					(newy-voi_ymin)*xsize+

					(newz-voi_zmin)*xsize*ysize];

                if (bindex!=-1) {

					/* Inter-layer connectivity. */

					gmB = &gm_array[bindex];

                    if (gmA->layer+1==gmB->layer) {

                    LINK_VOXELS;

                    if (!MemoryOK) return false;

					}

				}

			}

		}

	}



	/* Intra-layer connectivity.  Loop over all new gray matter

	* voxels again and establish links to their 26-nb siblings in

	* the current layer. */

	

     for (i=first_gv_index; i<first_gv_index+num_new_gv; i++) {

		aindex = i;

		gmA = &gm_array[aindex];

		x = gmA->x; y = gmA->y; z = gmA->z;



		// Loop over all 26 neighbors (actually, because of

		// symmetry, we need to do it only over 13 neighbors). 

		for (j=0; j<13; j++) {

			newx = x+intra_offsets[j][0];

			newy = y+intra_offsets[j][1];

			newz = z+intra_offsets[j][2];

			if ((newx>=voi_xmin) && (newx<=voi_xmax) &&

				(newy>=voi_ymin) && (newy<=voi_ymax) &&

				(newz>=voi_zmin) && (newz<=voi_zmax)) {



				bindex = inv_gm_table[(newx-voi_xmin)+

				(newy-voi_ymin)*xsize+

				(newz-voi_zmin)*xsize*ysize];

				if (bindex!=-1) {

					// Intra-layer connectivity.

					// Check if aindex and bindex voxels have a

					// common parent or connected parents. 

					gmB = &gm_array[bindex];

                    

					if ((gmA->layer==gmB->layer)) {



						LINK_VOXELS;

						if (!MemoryOK) return false;



					}

				}

			}

		}

	}

	return true;

}



/*************************************************************************/



/*

 * Computes all the gray matter neighbors within the second or

 * subsequent layers.  Two 26-nb adjacent gray matter voxels are

 * considered to be connected if either (a) they have a common 6-nb

 * gray matter parent or (b) they have 6-nb gray matter parents that

 * are connected in the previous gray matter layer.  We assume

 * that there is no possibility of intersecting surfaces (as

 * described in first_gray_layer_connectivity()) for the second

 * and subsequent layers.

 */

bool CGray::gray_layer_connectivity(GrayMatter *gm, 

			int first_gv_index, int num_new_gv)

{

	// Offsets for inter-layer 6-nb connectivity between this

	// layer and the previous.

	static int inter_offsets[6][3] = {

		{+1, 0, 0}, { 0,+1, 0}, { 0, 0,+1}, 

		{-1, 0, 0}, { 0,-1, 0}, { 0, 0,-1}

	};

	// Offsets for intra-layer 26-nb connectivity.

	static int intra_offsets[13][3] = {

		{+1, 0, 0}, { 0,+1, 0}, { 0, 0,+1}, 

		{+1, 0,+1}, {-1, 0,+1}, { 0,-1,+1}, 

		{ 0,+1,+1}, {-1,+1, 0}, {+1,+1, 0}, 

		{+1,+1,+1}, {-1,-1,+1}, {+1,-1,+1}, 

		{-1,+1,+1}

	};

	// For the allocation error trap...

	bool MemoryOK=true;



	int	i, j, x, y, z, xsize, ysize, zsize, yskip, zskip;

	int	newx, newy, newz, aindex, bindex;

	int	voi_xmin, voi_ymin, voi_zmin, voi_xmax, voi_ymax, voi_zmax;

	GrayVoxel	*gm_array, *gmA, *gmB;

	int	*inv_gm_table;



	gm_array = gm->gm_array;

	inv_gm_table = gm->inv_gm_table;

	voi_xmin = gm->voi_xmin; voi_xmax = gm->voi_xmax;

	voi_ymin = gm->voi_ymin; voi_ymax = gm->voi_ymax;

	voi_zmin = gm->voi_zmin; voi_zmax = gm->voi_zmax;

	xsize = gm->voi_xmax-voi_xmin+1;

	ysize = gm->voi_ymax-voi_ymin+1;

	zsize = gm->voi_zmax-voi_zmin+1;

	yskip = xsize;

	zskip = xsize*ysize;     



	/* Inter-layer connectivity.  Loop over all new gray matter

	* voxels and establish links to their 6-nb parents.  Need to

	* determine these links first because these links are used to

	* determine intra-layer connectivity subsequently.  We can be

	* sure that no gray-matter voxel can belong to two parents

	* on opposite sides of the sulcus since this would imply

	* a contention which is checked for during the growing process. */

	for (i=first_gv_index; i<first_gv_index+num_new_gv; i++) {

		aindex = i;

		gmA = &gm_array[aindex];

		x = gmA->x; y = gmA->y; z = gmA->z;



		/* Loop over all 6 neighbors. */

		for (j=0; j<6; j++) {

			newx = x+inter_offsets[j][0];

			newy = y+inter_offsets[j][1];

			newz = z+inter_offsets[j][2];

			if ((newx>=voi_xmin) && (newx<=voi_xmax) &&

			(newy>=voi_ymin) && (newy<=voi_ymax) &&

			(newz>=voi_zmin) && (newz<=voi_zmax)) {

				bindex = inv_gm_table[

					(newx-voi_xmin)+

					(newy-voi_ymin)*xsize+

					(newz-voi_zmin)*xsize*ysize];

                if (bindex!=-1) {

					/* Inter-layer connectivity. */

					gmB = &gm_array[bindex];

                    if (gmA->layer==gmB->layer+1) {

                    LINK_VOXELS;

                    if (!MemoryOK) return false;

					}

				}

			}

		}

	}



	/* Intra-layer connectivity.  Loop over all new gray matter

	* voxels again and establish links to their 26-nb siblings in

	* the current layer. */

	for (i=first_gv_index; i<first_gv_index+num_new_gv; i++) {

		aindex = i;

		gmA = &gm_array[aindex];

		x = gmA->x; y = gmA->y; z = gmA->z;



		/* Loop over all 26 neighbors (actually, because of

		* symmetry, we need to do it only over 13 neighbors). */

		for (j=0; j<13; j++) {

			newx = x+intra_offsets[j][0];

			newy = y+intra_offsets[j][1];

			newz = z+intra_offsets[j][2];

			if ((newx>=voi_xmin) && (newx<=voi_xmax) &&

				(newy>=voi_ymin) && (newy<=voi_ymax) &&

				(newz>=voi_zmin) && (newz<=voi_zmax)) {



				bindex = inv_gm_table[(newx-voi_xmin)+

				(newy-voi_ymin)*xsize+

				(newz-voi_zmin)*xsize*ysize];

				if (bindex!=-1) {

					/* Intra-layer connectivity.

					* Check if aindex and bindex voxels have a

					* common parent or connected parents. */

					gmB = &gm_array[bindex];

                    

					if ((gmA->layer==gmB->layer) &&

						is_connected2p(aindex, bindex, gm_array)) {



						LINK_VOXELS;

						if (!MemoryOK) return false;



					}

				}

			}

		}

	}

	return true;

}



/*

 * Adds new gray matter voxels into the graph and updates the

 * inverse lookup table.  Connectivity is not determined here.

 */

bool CGray::add_new_gray_matter(GrayMatter *gm, int num_new_gv, 

		    unsigned char old_label, unsigned char new_label,

		    int layer)

{

	int	x, y, z, yskip, zskip, xsize, ysize, i;

	int	voi_xmin, voi_xmax, voi_ymin, voi_ymax, voi_zmin, voi_zmax;

	unsigned char *cvol, *cvolx, *cvoly, *cvolz;

	int	*inv_gm_table;

	GrayVoxel	*gm_array;



	voi_xmin = gm->voi_xmin; voi_xmax = gm->voi_xmax;

	voi_ymin = gm->voi_ymin; voi_ymax = gm->voi_ymax;

	voi_zmin = gm->voi_zmin; voi_zmax = gm->voi_zmax;

	yskip = gm->mrvol->yskip; zskip = gm->mrvol->zskip;

	cvol = gm->mrvol->cvol + voi_zmin*zskip + voi_ymin*yskip + voi_xmin;

	inv_gm_table = gm->inv_gm_table;

	xsize = voi_xmax-voi_xmin+1;

	ysize = voi_ymax-voi_ymin+1;



	i = gm->gm_size;

	if (!alloc_gray_matter(gm, num_new_gv)) return false;

	gm_array = gm->gm_array;



	/* Also compute the neighborhood code if it is the first layer. */

	for (z=voi_zmin, cvolz=cvol; z<=voi_zmax; z++, cvolz+=zskip)

		for (y=voi_ymin, cvoly=cvolz; y<=voi_ymax; y++, cvoly+=yskip)

			for (x=voi_xmin, cvolx=cvoly; x<=voi_xmax; x++, cvolx++)

				if ((*cvolx)==old_label) {

                    *cvolx = new_label;



					ASSERT(i<gm->gm_size);



					gm_array[i].x = x;

					gm_array[i].y = y;

					gm_array[i].z = z;

					gm_array[i].layer = layer;

					gm_array[i].num_gm_nbhrs = 0;

					inv_gm_table[(z-voi_zmin)*xsize*ysize+(y-voi_ymin)*xsize+(x-voi_xmin)] = i;

					if (layer==1) {

						gm_array[i].nbhd_code = (unsigned char)

							compute_wm_nbhd_code(cvol, 

								voi_xmax-voi_xmin+1, 

								voi_ymax-voi_ymin+1, 

								voi_zmax-voi_zmin+1, 

								yskip, zskip,

								x-voi_xmin, 

								y-voi_ymin, 

								z-voi_zmin,

								WHITE_CLASS,CLASS_MASK);

					}

					i++;

				}

	return true;

}





/**********************************************************************/



/*

 * Grow the first layer of gray within VOI.

 *

 * Robert Taylor 24th February 1998 - Added white mask to call to grow from

 * white boundary so that selected white matter may be treated in the same 

 * manner as unselected white matter.

 */

bool CGray::grow_gray_layers(GrayMatter *gm,

		      int voi_xmin, int voi_xmax,

		      int voi_ymin, int voi_ymax,

		      int voi_zmin, int voi_zmax,

		      int num_layers)

{



	if (!m_Ok) return false;

	static char tmp[75];



	unsigned char *cvol;

	int i, layer;

	int	xsize, ysize, zsize, yskip, zskip;

	int	num_new_gv, old_gm_size, num_wm;

	int	*inv_gm_table;



	yskip = gm->mrvol->yskip; zskip = gm->mrvol->zskip;



	cvol = ((gm)->mrvol)->cvol;

	cvol += voi_zmin*zskip;

	cvol += voi_ymin*yskip;

	cvol += voi_xmin;



	xsize = voi_xmax-voi_xmin+1;

	ysize = voi_ymax-voi_ymin+1;

	zsize = voi_zmax-voi_zmin+1;



	gm->voi_xmin = voi_xmin; gm->voi_xmax = voi_xmax;

	gm->voi_ymin = voi_ymin; gm->voi_ymax = voi_ymax;

	gm->voi_zmin = voi_zmin; gm->voi_zmax = voi_zmax;



	/* Allocate inverse lookup table. */

	inv_gm_table = (int*) new int[xsize*ysize*zsize];

	gm->inv_gm_table = inv_gm_table;

	if (!inv_gm_table) return false;

	for (i=0; i<xsize*ysize*zsize; i++) inv_gm_table[i]=-1;



	/*

	* [1] Grow first layer of gray matter from white matter boundary.

	* [2] Add new gray matter voxels to graph. 

	* [3] Compute first layer's connectivity.

	* [4] Grow subsequent layers and compute their connectivity. 

	*/



    /* Finds the white boundary */

    layer = 0;

    

    /*if (gm->layer0 == 1) {

        num_wm = find_white_matter

            (gm, WHITE_CLASS,CLASS_MASK,TMP_CLASS1, UNKNOWN_CLASS);



        if (num_wm > 0) {

             if (!add_new_gray_matter(gm, num_wm, TMP_CLASS1, WHITE_CLASS, layer)) {

                if (gm->inv_gm_table) delete gm->inv_gm_table;

                gm->inv_gm_table=NULL;

                return false;        

            }

        }

    }*/

        

    layer++;     



	num_new_gv = grow_from_white_boundary

		(gm, WHITE_CLASS,CLASS_MASK,TMP_CLASS1, UNKNOWN_CLASS);

    

	if (num_new_gv>0) {



		if (!add_new_gray_matter(gm, num_new_gv, TMP_CLASS1, GRAY_CLASS, layer)) {

			if (gm->inv_gm_table) delete gm->inv_gm_table;

			gm->inv_gm_table=NULL;

			return false;

		}



		i=1;



		if (!first_gray_layer_connectivity(gm)) {

			if (gm->inv_gm_table) delete gm->inv_gm_table;

			gm->inv_gm_table=NULL;

			return false;

		}



		i++;



        /*if (gm->layer0 == 1) {

            if (!zero_layer_connectivity(gm, 0, num_wm)) {

                if (gm->inv_gm_table) delete gm->inv_gm_table;

                gm->inv_gm_table=NULL;

                return false;

            }

        }*/

            

        i++;

        

        layer++;        

		

        for (; layer<=num_layers; layer++) {

			num_new_gv = grow_from_gray_boundary(gm, GRAY_CLASS, TMP_CLASS1, UNKNOWN_CLASS);



			if (num_new_gv==0) break;

			else {

				old_gm_size = gm->gm_size;



				if (!add_new_gray_matter(gm, num_new_gv, TMP_CLASS1, GRAY_CLASS, layer)) {

					if (gm->inv_gm_table) delete gm->inv_gm_table;

					gm->inv_gm_table=NULL;

					return false;

				}



				i++;



				if (!gray_layer_connectivity(gm, old_gm_size, num_new_gv)) {

					if (gm->inv_gm_table) delete gm->inv_gm_table;

					gm->inv_gm_table=NULL;

					return false;

				}

                

                i++;

			}

		}

        

	    /*if (gm->layer0 == 2) {

            

            old_gm_size = gm->gm_size;

            

            num_wm = find_white_matter

                (gm, WHITE_CLASS,CLASS_MASK,TMP_CLASS1, UNKNOWN_CLASS);



            if (num_wm > 0) {

                 if (!add_new_gray_matter(gm, num_wm, TMP_CLASS1, WHITE_CLASS, 0)) {

                    if (gm->inv_gm_table) delete gm->inv_gm_table;

                    gm->inv_gm_table=NULL;

                    return false;        

                }

            }

            

            if (!zero_layer_connectivity(gm, old_gm_size, num_wm)) {

                if (gm->inv_gm_table) delete gm->inv_gm_table;

                gm->inv_gm_table=NULL;

                return false;

            }

        }*/

	}

	return true;

}



/**********************************************************************/



bool CGray::add_white_matter(GrayMatter *gm)

{

    int old_gm_size;

    int num_wm;

    

    old_gm_size = gm->gm_size;

            

    num_wm = find_white_matter

        (gm, WHITE_CLASS,CLASS_MASK,TMP_CLASS1, UNKNOWN_CLASS);



    if (num_wm > 0) {

         if (!add_new_gray_matter(gm, num_wm, TMP_CLASS1, WHITE_CLASS, 0)) {

            if (gm->inv_gm_table) delete gm->inv_gm_table;

            gm->inv_gm_table=NULL;

            return false;        

        }

    }



    if (!zero_layer_full_connectivity(gm, old_gm_size, num_wm)) {

        if (gm->inv_gm_table) delete gm->inv_gm_table;

        gm->inv_gm_table=NULL;

        return false;

    }

    

    return true;

}



/**********************************************************************/



bool CGray::add_white_boundary(GrayMatter *gm)

{

    int old_gm_size;

    int num_wm;

    

    old_gm_size = gm->gm_size;

            

    num_wm = find_white_boundary

        (gm, WHITE_CLASS,CLASS_MASK,TMP_CLASS1, GRAY_CLASS);



    if (num_wm > 0) {

         if (!add_new_gray_matter(gm, num_wm, TMP_CLASS1, WHITE_CLASS, 0)) {

            if (gm->inv_gm_table) delete gm->inv_gm_table;

            gm->inv_gm_table=NULL;

            return false;        

        }

    }



    if (!zero_layer_connectivity(gm, old_gm_size, num_wm)) {

        if (gm->inv_gm_table) delete gm->inv_gm_table;

        gm->inv_gm_table=NULL;

        return false;

    }

    

    return true;

}



/**********************************************************************/



/* Sets all the flags in the gray voxels to 'value'. */

void CGray::gray_matter_set_flag(GrayMatter *gm, unsigned char value)

{

     int	i;

     GrayVoxel	*gv;



     gv = gm->gm_array;

     for (i=gm->gm_size; i>0; i--, gv++) gv->flag=value;

}



/*

 * Flood fill the gray matter manifold starting at index.

 * All gray voxels with flag values 'Old' are replaced with

 * 'New'.  Neighborhood relationship is determined via the

 * graph.   Returns the number of voxels in the connected component.

 *

 * This version uses a static buffer for speed (Robert Taylor)

 */

int CGray::GrayMatterFlood(GrayMatter *gm, int Seed, unsigned char Old, unsigned char New)

{

	// Load up some parameters and check validity of input

	if (!gm) return -1;

	if (New==Old) return -1; // Not Allowed



	// Allocate enough memory to hold every point (worst case)

	int Count=gm->gm_size;	if (!Count) return -1;

	static GrayVoxel *gm_array; gm_array = gm->gm_array;	if (!gm_array) return -1;



	// Get the VOI to which we must clip... statics are fast

	static int x1,x2,y1,y2,z1,z2,x,y,z;

	x1 = gm->voi_xmin;

	x2 = gm->voi_xmax;

	y1 = gm->voi_ymin;

	y2 = gm->voi_ymax;

	z1 = gm->voi_zmin;

	z2 = gm->voi_zmax;



	bool InVOI;



	// Here's the test VOI macro...

#define TESTIFINVOI(gv) {\
		InVOI=false;\
		x=gv->x; y=gv->y; z=gv->z;\
		do {\
			if (x<x1) break;\
			if (x>x2) break;\
			if (y<y1) break;\
			if (y>y2) break;\
			if (z<z1) break;\
			if (z>z2) break;\
			InVOI=true;\
		} while (!InVOI);\
	}



	// Get the first point, make sure it

	// qualifies itself.

	static GrayVoxel *gv; gv = &(gm->gm_array[Seed]);

	if ((gv->flag)!=Old) return 0;

	TESTIFINVOI(gv);

	if (!InVOI) return 0;



	// Ok, it does. So we have at least some work to do.

	// Get a big enough stack

	static GrayVoxel **Stk; Stk = new GrayVoxel*[Count];

	if (!Stk) return -1;

	static GrayVoxel **Sptr; Sptr=Stk;

	static GrayVoxel **Topptr; Topptr = Stk + Count;



	// Set and push the seed

	gv->flag=New;

	*(Sptr++)=gv;

	Count=1;



	// Start off flood

	while (Sptr!=Stk) {

		gv = *(--Sptr);

		// This voxel has already been set and counted.

		// Our mission here is to set, count and push

		// all its neighbours which are within the VOI

		for (int i=0; i<gv->num_gm_nbhrs; i++) {

			static GrayVoxel *newgv;

			newgv = & (gm_array[gv->gm_nbhrs[i]]);

			if (newgv->flag!=Old) continue;

			TESTIFINVOI(newgv);

			if (!InVOI) continue;



			// Set, push and count the voxel

			newgv->flag=New;

			*(Sptr++)=newgv;

			Count++;

			// Make sure we don't go too far

			if (Sptr==Topptr) {

				ASSERT(0);

				delete Stk;

				return -1;

			}

		} // All done for this point's neighbours

		// Get next off stack

	} // End while(Sptr!=Stk)



	delete Stk;

	return Count;



#undef TESTINVOI

}



/*

 * Extract gray matter component starting from (x,y,z).
 * SelOrDesel=1 to select, SelOrDesel=0 to deselct.
 * Returns the number of voxels selected or deselcted.

 */

int CGray::select_gray_matter_comp(GrayMatter *gm, int startx, int starty, int startz, int SelOrDesel)

{

	if (!m_Ok) return(0);



    GrayVoxel	*gv;

	int	i, yskip, zskip;

	unsigned char *cvol;



    gray_matter_set_flag(gm, 0);



    /* Find vertex in gray matter connectivity graph. */

    gv = gm->gm_array;
    bool foundIt = false;

    for(i=0; i<gm->gm_size; i++, gv++){

       if((gv->x==startx) && (gv->y==starty) && (gv->z==startz)){
         foundIt = true;
         break;
       }
    }



    // Not a gray matter voxel?

    if(!foundIt) return(0);



    if(-1==GrayMatterFlood(gm, i, 0, 1)) {
       return(0);

	}



    /* Update cvol for all selected gray voxels. */
    int n = 0;

    gv = gm->gm_array; cvol = gm->mrvol->cvol;

    yskip = gm->mrvol->yskip; zskip = gm->mrvol->zskip;

    for (i=gm->gm_size; i>0; i--, gv++){

	   if (gv->flag==1) {
	      n++;

          cvol[gv->z*zskip+gv->y*yskip+gv->x] =

			   (SelOrDesel?GRAY_SELECTED_CLASS:GRAY_CLASS);

	   }
	}
	return(n);

}



/**********************************************************************/



