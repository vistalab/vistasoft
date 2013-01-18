/* MEX file to take a set of grey points and a set of underlying mesh points and 
 * compute which grey point maps to which mesh point - no interpolation! 
 * v0.1 A.Wade 11/2000 
 * 2003.07.13 R. Dougherty: transposed expected input data form so that our loops 
 * don't have to jump all over RAM. We also now operate on integers rather than doubles. 
 * 
 * Compile with: mex -O COPTIMFLAGS='-O3 -march=i686 -DNDEBUG' findNearest.c
 * (or try -march=pentium4)
 */


#include <math.h>
#include "mex.h"

void getNearest(short *inpPtr, short *refPtr, unsigned long *outPtr, long *distPtr, unsigned int inpCols, unsigned int refCols){
	/* Run through each member of inpPtr and take the distance between it and
   * each member of refPtr. Return the indices of the nearest points in refPtr 
	 */

  unsigned long inpCnt, refCnt, indLowest;
  long thisDist,cLowest;
  short distX,distY,distZ,xInp,yInp,zInp; 
	short *refPtrTmp;

  for (inpCnt=inpCols; inpCnt>0; inpCnt--) {
		/* Matlab orders its data so that the row dimension increases fastest */
    xInp = *(inpPtr++);
    yInp = *(inpPtr++);
    zInp = *(inpPtr++);

    cLowest = 9999999;
    /*indLowest=0;*/
		refPtrTmp = refPtr;
    for (refCnt=0; refCnt<refCols; refCnt++) {
      distX = *(refPtrTmp++) - xInp;
      distY = *(refPtrTmp++) - yInp;
      distZ = *(refPtrTmp++) - zInp;
      thisDist = (long)(distX*distX+distY*distY+distZ*distZ);
/*      if(distX<0) distX = -distX; */
/* 			if(distY<0) distY = -distY; */
/* 			if(distZ<0) distZ = -distZ; */
/*      thisDist = distX+distY+distZ; */

      if (thisDist<cLowest) {
        cLowest = thisDist;
        indLowest = refCnt;
      }
    } /* next RefCounter */

    *(outPtr++) = indLowest+1; /* add the one because matlab references arrays from 1 */
    *(distPtr++) = (long)cLowest;      /* Returns the squared distances */
  } /* next InpCounter */
} /* end of function */

void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] ){ 
  short *refPtr, *inpPtr;
  unsigned long *outPtr;
  long *distPtr;
  unsigned int refRows,refCols,inpRows,inpCols; 

  /* Check for proper number of arguments */
  if (nrhs != 2) { 
    mexErrMsgTxt("Two input vectors required."); 
  } else if (nlhs > 2) {
    mexErrMsgTxt("Error! Too many output arguments."); 
  } 
    
  refRows = mxGetM(prhs[0]);
  refCols = mxGetN(prhs[0]);
  inpRows = mxGetM(prhs[1]);
  inpCols = mxGetN(prhs[1]);
  
  /* Check for type and size */
  if (!mxIsClass(prhs[0], "int16"))
    mexErrMsgTxt("Argument 1 must be an int16 array"); 
  if (!mxIsClass(prhs[1], "int16"))
    mexErrMsgTxt("Argument 2 must be an int16 array"); 
  if ((refRows!=3) || (inpRows!=3))
    mexErrMsgTxt("Both input arguments must have 3 rows"); 

	refPtr = (short *)mxGetPr(prhs[0]);
  inpPtr = (short *)mxGetPr(prhs[1]);

  /* Create a matrix for the return argument */ 
  plhs[0] = mxCreateNumericArray(1, &inpCols, mxUINT32_CLASS, mxREAL); 
  plhs[1] = mxCreateNumericArray(1, &inpCols, mxINT32_CLASS, mxREAL); 

  outPtr = (unsigned long *)mxGetPr(plhs[0]);
  distPtr = (long *)mxGetPr(plhs[1]);
  if ((!outPtr) || (!distPtr)) { 
    mexErrMsgTxt("Could not assign output matrices. Out of memory?"); 
  } 

  /* Do the actual computations in a subroutine */
  getNearest(inpPtr,refPtr,outPtr,distPtr,inpCols,refCols); 

  return; 
}





