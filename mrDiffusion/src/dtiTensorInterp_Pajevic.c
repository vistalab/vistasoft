/* Matlab gateway for Pajevic's tensor interpolation C functions:
 *   InitializeApproximation(dtdata, dims, scale, voxdims, origin)
 *   GetTensorAt(coords, derivs, dt6)
 *
 * Documentation for these functions is found in files:
 *   bcadtlib.pdf
 *   README
 * 
 * To compile under linux, run:
 *    mex -O COPTIMFLAGS='-O3 -march=i686 -DNDEBUG' dtiTensorInterp_Pajevic.c ./bcadtlib.so
 */

#include "mex.h"
#include "matrix.h"
#include <stdlib.h>
#include "bcadt.h"

void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
  /*  Check for proper number of arguments. */
  /* NOTE: You do not need an else statement when using
     mexErrMsgTxt within an if statement. It will never
     get to the else statement if mexErrMsgTxt is executed.
     (mexErrMsgTxt breaks you out of the MEX-file.) 
  */
  if (nrhs < 3 || nrhs > 6) 
    mexErrMsgTxt("At least three and no more than six inputs required.");
  if (nlhs != 1) 
    mexErrMsgTxt("One output required.");
  
  /* First arg is tensor data XxYxZx6 array */
  if(!mxIsDouble(prhs[0]) || mxIsComplex(prhs[0]) ||
    (mxGetNumberOfDimensions(prhs[0])!=4 & !mxIsEmpty(prhs[0]))) {
      mexErrMsgTxt("Tensor data must be a real XxYxZx6 array.");
  }
  float *dtData=NULL;
  long dims[3];
  int i,j;
  if(!mxIsEmpty(prhs[0])){
    int *dimsPtr;
    dimsPtr = mxGetDimensions(prhs[0]);
    if(dimsPtr[3]!=6) {
      mexErrMsgTxt("Tensor data must be a real XxYxZx6 array (ie. 6 elements per voxel).");
    }
    dims[0] = (long)dimsPtr[0]; 
    dims[1] = (long)dimsPtr[1]; 
    dims[2] = (long)dimsPtr[2];
    int dtSize = mxGetNumberOfElements(prhs[0]);
    int nVox = dims[0]*dims[1]*dims[2];
    
    /* unfortunately, matlab only deals in doubles, yet the library wants floats. */
    double *dtPtr;
    dtPtr = mxGetPr(prhs[0]);
    dtData = mxCalloc(dtSize, sizeof(float));
    for(i=0; i<nVox; i++){
      for(j=0; j<6; j++){
	dtData[6*i + j] = (float)dtPtr[i + nVox*j];
      }
    }
  }

  /* Second arg is the coordinate list */
  if(!mxIsDouble(prhs[1]) || mxIsComplex(prhs[1]) ||
    mxGetNumberOfDimensions(prhs[1])!=2 || mxGetN(prhs[1])!=3) {
      mexErrMsgTxt("Coord list must be a real 2 dim Nx3 array.");
  }
  double *coordsPtr;
  int nCoords = mxGetM(prhs[1]);
  coordsPtr = mxGetPr(prhs[1]);

  /* Third argument is the voxel dimensions (eg. mmPerVoxel). */
  if(!mxIsDouble(prhs[2]) || mxIsComplex(prhs[2]) ||
    mxGetM(prhs[2])!=1 || mxGetN(prhs[2])!=3) {
      mexErrMsgTxt("Voxel dimensions must be a 1x3 array of doubles.");
  }
  double *voxDimsPtr;
  float voxDims[3];
  voxDimsPtr = mxGetPr(prhs[2]);
  voxDims[0] = (float)voxDimsPtr[0]; 
  voxDims[1] = (float)voxDimsPtr[1]; 
  voxDims[2] = (float)voxDimsPtr[2];

  /* Fourth arg is the optional scale */
  float scale;
  if(nrhs>3){
    if(!mxIsDouble(prhs[3]) || mxIsComplex(prhs[3]) ||
      mxGetN(prhs[3])*mxGetM(prhs[3]) != 1) {
	mexErrMsgTxt("Scale input must be a scalar.");
	}
    scale = (float)mxGetScalar(prhs[3]);
	if((scale <= 0) || (scale > 1))
	  mexErrMsgTxt("Scale input must be in (0, 1].");
  }else{
    /* Default scale is 1 (interpolation) */
	scale = (float)1.0;
  }

  /* Fifth argument is optional origin */
  double *originPtr;
  float origin[3];
  if(nrhs>4){
    if(!mxIsDouble(prhs[4]) || mxIsComplex(prhs[4]) ||
      mxGetM(prhs[4])!=1 || mxGetN(prhs[4])!=3) {
        mexErrMsgTxt("Origin must be a 1x3 array of doubles.");
	}
    originPtr = mxGetPr(prhs[4]);
    origin[0] = (float)originPtr[0]; 
    origin[1] = (float)originPtr[1]; 
    origin[2] = (float)originPtr[2];
  }else{
    /* default origin- so that 0,0,0 is the center of the first voxel. */
    origin[0] = (float)voxDimsPtr[0]/2; 
    origin[1] = (float)voxDimsPtr[1]/2; 
    origin[2] = (float)voxDimsPtr[2]/2;
  }

  /* Sixth argument is optional degree of derivatives */
  double *derivsPtr;
  int derivs[3];
  if(nrhs>5){
    if(!mxIsDouble(prhs[5]) || mxIsComplex(prhs[5]) ||
      mxGetM(prhs[5])!=1 || mxGetN(prhs[5])!=3) {
        mexErrMsgTxt("Derivs must be a 1x3 array of doubles.");
	}
    derivsPtr = mxGetPr(prhs[5]);
    derivs[0] = (int)derivsPtr[0]; 
    derivs[1] = (int)derivsPtr[1]; 
    derivs[2] = (int)derivsPtr[2];
  }else{
    /* default origin- so that 0,0,0 is the center of the first voxel. */
    derivs[0] = 0; 
    derivs[1] = 0; 
    derivs[2] = 0;
  }
  
/*   mexPrintf("dims=[%d %d %d] scale=%f dtSize=%d\n", dims[0], dims[1], dims[2], */
/* 		 scale, dtSize); */
/*   mexPrintf("dtData = %f %f %f %f %f %f\n%f %f %f %f %f %f\n", */
/*     dtData[0],dtData[1],dtData[2],dtData[3],dtData[4],dtData[5], */
/*     dtData[6],dtData[7],dtData[8],dtData[9],dtData[10],dtData[11],dtData[12]); */
  if(!mxIsEmpty(prhs[0])){
    InitializeApproximation(dtData, dims, scale, voxDims, origin);
    mexPrintf("Finished Initialization...\n"); 
  }

  /* Set the output pointer to the output matrix. */
  /* Data will be returned in same order as input (usually Dxx, Dyy, Dzz, Dxy, Dxz, Dyz). */
  plhs[0] = mxCreateDoubleMatrix(nCoords, 6, mxREAL);
  double *outPtr = mxGetPr(plhs[0]);
  float coords[3];
  float dt6[6]; 
  for(i=0; i<nCoords; i++){
    for(j=0; j<3; j++){
      coords[j] = (float)coordsPtr[i + nCoords*j];
    }
    /* mexPrintf("%d (out of %d), coords=[%f %f %f]\n", i+1, nCoords, coords[0], */
/* coords[1], coords[2]); */
    GetTensorAt(coords, derivs, dt6);
    for (j=0; j<6; j++){
      outPtr[i + nCoords*j] = (double)dt6[j];
    }
    /* mexPrintf("dt6 = %f %f %f %f %f %f\n", dt6[0],dt6[1],dt6[2],dt6[3],dt6[4],dt6[5]); */
  }
  mxFree(dtData);
}
