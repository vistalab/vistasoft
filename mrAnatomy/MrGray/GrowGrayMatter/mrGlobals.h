#define SELECT_MASK	0x80

#define CLASS_MASK	0x70



#define UNKNOWN_CLASS	0

#define WHITE_CLASS	(1<<4)

#define GRAY_CLASS	(2<<4)

#define CSF_CLASS	(3<<4)

#define TMP_CLASS1	(4<<4)



#define WHITE_CLASSP(c)	(((c)&CLASS_MASK)==WHITE_CLASS)

#define GRAY_CLASSP(c)	(((c)&CLASS_MASK)==GRAY_CLASS)

#define CSF_CLASSP(c)	(((c)&CLASS_MASK)==CSF_CLASS)



#define WHITE_SELECTED_CLASS	(SELECT_MASK|WHITE_CLASS)

#define GRAY_SELECTED_CLASS	(SELECT_MASK|GRAY_CLASS)



/* Maximum aposteriori probability estimation parameters. */

#define NUM_MAP_CLASSES	3

#define MAP_CSF		0

#define MAP_GRAY	1

#define MAP_WHITE	2



/* Classification Defaults. */

/* Default class means are found in global.h. */

/* Default class stdevs are found in global.h. */

/* Default confidence, num_iters are found in global.h. */



#define DEF_CSF_ANISO_K		0.5	/* CSF diffusivity. */

#define DEF_GRAY_ANISO_K	0.5	/* Gray diffusivity. */

#define DEF_WHITE_ANISO_K	0.5	/* White diffusivity. */



#define DEF_CSF_PRIOR		0.3	/* CSF prior. */

#define DEF_GRAY_PRIOR		0.3	/* Gray prior. */

#define DEF_WHITE_PRIOR		0.4	/* White prior. */



#define DEF_LAMBDA		1.0	/* Maximum delta. */





/* TYPES */



typedef struct {

	unsigned char wovR,wovG,wovB;

	unsigned char wsovR,wsovG,wsovB;

	unsigned char govR,govG,govB;

	unsigned char gsovR,gsovG,gsovB;

	unsigned char covR,covG,covB;

	unsigned char B3dR,B3dG,B3dB;	// 3D background colour

}  OvCols;



/*

 * All the information associated with the MR volume and its

 * csf/grey/white segmentation.

 */



typedef struct {

     

     /* Raw MR volume: */

     unsigned char	*mvol;			/* ptr to raw volume. */

     int	xsize, ysize, zsize;	/* dimensions. */

     int	yskip, zskip;		/* num cols, size of plane. */



     /* Classification volume: */

     unsigned char	*cvol;			/* ptr to class volume. */



     /* Gray matter connectivity graph: */

     struct _GrayMatterS_ *gm;		/* gray matter. */



} MRVol;



/****************************************/



/* 

 * GrayVoxel contains all the information associated with a segmented

 * gray matter voxel. Allocating the maximum number of neighbors for

 * gm_nbhrs is wasteful.  Need to find better alternative. 

 */

typedef struct {

     int	x, y, z;	/* absolute coord of gray voxel

				 * - not relative to VOI. */

     int	layer;		/* layer number. */

#ifdef DYNAMIC_NEIGHBOURS

     int	*gm_nbhrs;	/* Dynamically allocated as necessary */

#else

     int	gm_nbhrs[26];	/* maximum number of neighbors. */

#endif

     int	num_gm_nbhrs;



     unsigned char	nbhd_code;	/* temporary for computing the

				 * first gray matter layer. */



     /* Priority queue temporaries. */

     unsigned char	flag;

     float	dist;

     int	pqindex;
     
     /* Misc. flag for user use */
     unsigned char userFlag;
     

} GrayVoxel;



/*

 * GrayMatter contains an array of GrayVoxel's and a copy of

 * the volume of interest (VOI).  inv_gm_table is a volume

 * the same size as the VOI containing indices into gm_array.

 * It is used to quickly determine the index of a given gray

 * matter voxel from its (x,y,z) coordinate.

 */

typedef struct _GrayMatterS_ {

     MRVol	*mrvol;		/* pointer to MR volume. */

     int	voi_xmin, voi_ymin, voi_zmin;

     int	voi_xmax, voi_ymax, voi_zmax;

     GrayVoxel	*gm_array;

     int	gm_size;

     int	*inv_gm_table;

     int	num_gray_layers;	/* number of gray layers. */

     int    num_connex;

     int    *connex;

     int    layer0;

} GrayMatter;



/* 

 * GrayPQueue is a data structure that contains an array of pointers

 * to GrayVoxels.  It is used in a heap implementation of a priority

 * queue sorted by (GrayVoxel*)->dist.  The index of each GrayVoxel

 * in this array is also stored in (GrayVoxel*)->pqindex so that

 * the priority queue can be updated quickly when a GrayVoxel's

 * dist is reduced.

 */

typedef struct {

     int	max_size;

     int	size;

     GrayVoxel	**array;

} GrayPQueue;



// Bespoke 3D mesh format



typedef struct {

	float p[3];	// x,y,z of vert

	float n[3];	// x,y,z of normal

	unsigned char c[4]; // r,g,b,a

} MrVertex;	// 28 bytes per vertex



#define MRMESH_NORMALS_OK 0x01

#define MRMESH_COLOR_OK  0x02



typedef struct {

	int Flags;  // maybe MRMESH_NORMALS_OK, MRMESH_COLOR_OK

	int nStrips;

	int nTriangles;

	float Bounds[6];	// Bounding box of figure: x0 x1 y0 y1 z0 z1

	int *StripList;

	MrVertex *sVerticies;	// list of verticies for the strips

	MrVertex *tVerticies;  // list of verticies for the triangles

} MrMesh;





/**********************************************************************/

typedef struct {int x1,y1,z1,x2,y2,z2;} VOItype;

typedef struct {

	VOItype list[10];

	int VOIlistptr;

	int VOIlast;

} VOIlist;



// Data required for the classify data thread.

typedef struct {

	int CSFMean;

	int GrayMean;

	int WhiteMean;

	int NoiseStdev;

	int Confidence;

	int Smoothness;

	VOItype VOI;

	unsigned char *mvol, *cvol;

	int xskip,yskip,zskip;

	int sxyz;

} ClassifyData;



/* connected.c */



typedef unsigned char u_char;



#ifdef __cplusplus

extern "C" 

#else

extern

#endif



void extract_wm_comp(u_char* cvol,

		int voi_xmin, int voi_xmax, 

		int voi_ymin, int voi_ymax,

		int voi_zmin, int voi_zmax,

		int xsize, int ysize, int zsize,

		int yskip, int zskip,

		int startx, int starty, int startz,

		int SelectOrDeselect);



#define ASSERT(a) {if(!(a)) {int q=1,b=0,c=q/b;}}

