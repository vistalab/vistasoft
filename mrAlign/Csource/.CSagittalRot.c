/*  Matlab MEX file. SagittalRot:
 * ---------------------------------
 * AUTHOR: Sunil Gandhi
 * DATE: 11.1.96
 * FUNCTION:    rotPts = SagittalRot(sagSize,aTheta,cTheta,curSag)
 *      returns coordinate points for a rotated sagittal plane.
 *      To avoid dealing with the nasty matlab interface, instead
 *      of returning a matrix of coordinate points, as the 3d linear
 *      interpolator requires, the function returns all the x values,
 *      followed by the y values and the then the z values. In the
 *      matlab script, must assemble the matrix by making a reshape call.


 01.26.99:  AW/BW Updated for Matlab 5.X

*/

#include <mex.h>
#include <stdio.h>
#include <ctype.h>
#include <math.h>
#include <sys/types.h>


#define STORAGE
#define XDIM 1
#define YDIM 0


/* index ordering of matlab function inputs */

#define SAGSIZE 0
#define ATHETA 1
#define CTHETA 2
#define CURSAG 3

/* function: SagittalRot. Performs composite rotation in sag and axial
 * directions.
 */
void SagittalRot(int sagX, int sagY, double aTheta, double cTheta,
				int curSag, double *sagPts);

void mexFunction(int nlhs,mxArray *plhs[],
		 int nrhs,const mxArray *prhs[])
{
 double *sagSize;
 double *sagPts;

/* Check for proper number of arguments */

  if ((nrhs<4) || (nlhs==0)) { /* help */
   printf("rotPts = SagittalRot(sagSize,aTheta,cTheta,curSag)\n");
   printf("rotates sagittal slice by aTheta in the axial\n");
   printf("axis and by cTheta in the coronal axis\n");
  } else {
 
   sagSize = (double *) mxGetPr(prhs[SAGSIZE]);

   plhs[0] = mxCreateDoubleMatrix(sagSize[XDIM]*sagSize[YDIM]*3,1,mxREAL);
   /* mexPrintf("size sagPts: %f\n",sagSize[XDIM]*sagSize[YDIM]*3); */ 

   sagPts = mxGetPr(plhs[0]);

   SagittalRot((int) sagSize[XDIM], (int) sagSize[YDIM], 
	       *mxGetPr(prhs[ATHETA]),
	       *mxGetPr(prhs[CTHETA]), (int) *mxGetPr(prhs[CURSAG]), sagPts);

  }
} 

void SagittalRot(int sagX, int sagY, double aTheta, double cTheta,
			int curSag, double *sagPts) {

int i, j;
double cosX, cosY, sinX, sinY;

cosX = cos(cTheta);
sinX = sin(cTheta);
cosY = cos(aTheta);
sinY = sin(aTheta);

for (i=0; i<sagX; i++) {
   for (j=0; j<sagY; j++) {
	sagPts[(i*sagY + j)] =
	  (i-sagX/2)*cosY + sinY*(-(j-sagY/2)*sinX) + sagX/2;
	sagPts[(sagX*sagY + i*sagY + j)] =
	  (j-sagY/2)*cosX + sagY/2;
	sagPts[(2*sagX*sagY + i*sagY + j)] = 
	  -(i-sagX/2)*sinY + cosY*(-sinX*(j-sagY/2)) + curSag;
	}
   }

}









