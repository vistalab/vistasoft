/* MEX file to take a set of grey points and a set of underlying mesh points and */
/* compute which grey point maps to which mesh point - no interpolation! */
/* v0.1 A.Wade 11/2000 */
/* 2003.07.13 R. Dougherty: transposed expected input data form so that our loops 
 * don't have to jump all over RAM. Also reversed loops. Hopefully this will speed 
 * things up a bit. */


#include <math.h>
#include "mex.h"

void getNearest(double *inpPtr,double *refPtr,double *outPtr, double *distPtr, unsigned int inpCols,unsigned int refCols)
{

	// Run through each member of inpPtr and take the distance between it and
	// each member of refPtr. Return the indices of the nearest points in refPtr

	unsigned int RefCounter,InpCounter;
	double cLowest,thisDist,distX,distY,distZ, xInp,yInp,zInp; 
	unsigned int indLowest;

  for (InpCounter=inpCols-1;InpCounter>=0;InpCounter--) {
		
		xInp=inpPtr[InpCounter]; // Matlab orders its data so that the row dimension increases fastest
		yInp=inpPtr[InpCounter+1];
		zInp=inpPtr[InpCounter+2];

		cLowest=9999999;
		indLowest=0;

		for (RefCounter=refCols-1;RefCounter>=0;RefCounter--) {
			distX=refPtr[RefCounter]-xInp;
			distY=refPtr[RefCounter+1]-yInp;
			distZ=refPtr[RefCounter+2]-zInp;
			thisDist=(distX*distX+distY*distY+distZ*distZ);

			if (thisDist<cLowest) {
				cLowest=thisDist;
				indLowest=RefCounter;
			} // end if

		} // next RefCounter

		*(outPtr++)=indLowest+1; // add the one because matlab references arrays from 1
		*(distPtr++)=cLowest; // Returns the squared distances
	} // next InpCounter


} // end of function

void mexFunction( int nlhs, 
		  mxArray *plhs[], 
		  int nrhs, 
		  const mxArray *prhs[] )
{ 
    double *yp; 
    double *t,*y, *refPtr, *inpPtr, *outPtr, *distPtr; 
    unsigned int refRows,refCols,inpRows,inpCols; 

    /* Check for proper number of arguments */

    if (nrhs != 2) { 
		mexErrMsgTxt("Two input vectors required."); 
    } else if (nlhs > 2) {
		mexErrMsgTxt("Error! Too many output arguments."); 
    } 

    
  /*  Get the dimensions and a pointer to the reference matrix. */
	refRows = mxGetM(prhs[0]);
	refCols = mxGetN(prhs[0]);
	refPtr = mxGetPr(prhs[0]);

  /*  Get the dimensions and a pointer to the input matrix. */
	inpRows = mxGetM(prhs[1]);
	inpCols = mxGetN(prhs[1]);
	inpPtr = mxGetPr(prhs[1]);

  
 	// Check for type and size

    if (!mxIsDouble(prhs[0]) || mxIsComplex(prhs[0])) { 
		mexErrMsgTxt("Argument 1 must be a real double"); 
    } 
    
    if (!mxIsDouble(prhs[1]) || mxIsComplex(prhs[1])) { 
		mexErrMsgTxt("Argument 2 must be a real double"); 
    } 

	if ((refRows!=3) || (inpRows!=3)) {
		mexErrMsgTxt("Both input arguments must have 3 rows"); 
	}

    //printf("Got here ... assigning");
    /* Create a matrix for the return argument */ 
    plhs[0] = mxCreateDoubleMatrix(inpCols, 1, mxREAL); 
    plhs[1] = mxCreateDoubleMatrix(inpCols, 1, mxREAL); 

  
    outPtr=mxGetPr(plhs[0]);
    distPtr=mxGetPr(plhs[1]);
    /* Assign pointers to the various parameters */ 

    if ((!outPtr) || (!distPtr)) { 
		mexErrMsgTxt("Could not assign output matrices. Out of memory?"); 
    } 

  //  printf("Got here 232");
    /* Do the actual computations in a subroutine */
    getNearest(inpPtr,refPtr,outPtr,distPtr,inpCols,refCols); 
//  printf("Got here dfjdkj");
  
    
	// Don't compute the flops
  return;
    
}





