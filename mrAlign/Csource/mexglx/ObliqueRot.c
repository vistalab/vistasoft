
/*  Matlab MEX file. rotateOblique:
 * ---------------------------------
 * AUTHOR: Sunil Gandhi
 * DATE: 11.1.96
 * FUNCTION:rotPts = ObliqueRot(obA,obB,aTheta,cTheta,numSlices,sagSize,curSag)
 *     Rotates the oblique slice about the center of the sagittal image.
 *     runs in the z direction (curSag) from -ROOM/2 to numSlices+ROOM/2
 *     when the sagittal plane rotates, one side of the oblique gets rotated
 *     into out-of-range coordinates and are weeded out later, while points
 *     from the other side once invalid now get rotated into valid coordinates.
 *     So this extra room in the z-direction means that we can see more of the
 *     fringe image.   
 *
 *UPDATES:
 * 01.26.99:  AW/BW Changed from version 4.0 to 5.1
*/

#include "mex.h"
#include <stdio.h>
#include <ctype.h>
#include <math.h>
#include <sys/types.h>


#define STORAGE
#define XDIM 0
#define YDIM 1
#define ROOM 10 /* number buffer slices */

/* index ordering of matlab function inputs */

#define OBA 0
#define OBB 1
#define ATHETA 2
#define CTHETA 3
#define NUMSLICES 4
#define SAGSIZE 5
#define CURSAG 6
 
/* function: RotateOblique. Performs composite rotation in sag and axial
 * directions.
 */

void ObliqueRot(double *obA, double *obB, double *sagSize,
		   double curSag, double aTheta, double cTheta,
		   double numS, double d,double *obPts);

void mexFunction(int nlhs,                /* number of arguments on lhs */
		 mxArray *plhs[],         /* Matrices on lhs      */
		 int nrhs,	          /* no. of mat on rhs    */
		 const mxArray *prhs[]    /* Matrices on rhs      */
		 )
{
 double *obA, *obB, *obPts, numSlices, d;
 int numPts;

 /* Check for proper number of arguments */

  if ((nrhs<4) || (nlhs==0)) { /* help */
   printf("rotPts = ObliqueRot(obA,obB,aTheta,cTheta,numSlices,sagSize,curSag)\n");
   printf("rotates Oblique slice by aTheta in the axial\n");
   printf("axis and by cTheta in the coronal axis about [sagX/2,sagY/2,curSag]\n");
  } else {
 
   obA = mxGetPr(prhs[OBA]);
   obB = mxGetPr(prhs[OBB]);
   d = sqrt(pow((obA[XDIM]-obB[XDIM]),2) + pow((obA[YDIM]-obB[YDIM]),2));
   numSlices = *mxGetPr(prhs[NUMSLICES]);
   numPts = (ceil(d))*(numSlices+ROOM);

   plhs[0] = mxCreateDoubleMatrix(numPts*3,1,mxREAL);

   obPts = mxGetPr(plhs[0]);
   ObliqueRot(obA, obB, mxGetPr(prhs[SAGSIZE]), 
		 *mxGetPr(prhs[CURSAG]), *mxGetPr(prhs[ATHETA]),
		 *mxGetPr(prhs[CTHETA]), numSlices,d, obPts);

  }
} 

void ObliqueRot(double *obA, double *obB, double *sagSize,
		   double curSag, double aTheta, double cTheta,
		   double numS, double d,double *obPts) {

int i, z, D, numSlices;
double x, y, cosX, cosY, sinX, sinY, unitvX, unitvY;

numSlices = (int) numS;
D = (int) d + 1; /* gets the ceiling of d */

cosX = cos(cTheta);
sinX = sin(cTheta);
cosY = cos(aTheta);
sinY = sin(aTheta); 

unitvX = (obB[XDIM]-obA[XDIM])/d; 
unitvY = (obB[YDIM]-obA[YDIM])/d;


   for (z=-ROOM/2;z<numSlices+ROOM/2;z++) {
       x = obA[XDIM];
       y = obA[YDIM];

     for (i=0; i<D; i++) {
       x+=unitvX;
       y+=unitvY;

       obPts[((z+ROOM/2)*D + i)] = 
	 (x-sagSize[XDIM]/2)*cosY + (z-curSag)*cosX*sinY - (y-sagSize[YDIM]/2)*sinX*sinY + sagSize[XDIM]/2;
	
	obPts[((numSlices+ROOM)*D + (z+ROOM/2)*D + i)] = 
	  (y-sagSize[YDIM]/2)*cosX + (z-curSag)*sinX + sagSize[YDIM]/2;
	
	obPts[(2*(numSlices+ROOM)*D + (z+ROOM/2)*D + i)] =
	  -(x-sagSize[XDIM]/2)*sinY -(y-sagSize[YDIM]/2)*sinX*cosY + (z-curSag)*cosX*cosY + curSag;
	}
   }

}





