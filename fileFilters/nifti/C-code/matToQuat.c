/*
	 *
	 * To compile on most unices (maybe BSD/OS-X?):
	 *   mex matToQuat.c nifti1_io.c znzlib.c
	 *
	 * On cygwin:
	 * mex nifti1_io.c znzlib.c matToQuat.c -I../../../VISTAPACK/zlib/include/cygwin ../../../VISTAPACK/zlib/lib/cygwin/libz.a
	 *
	* On 32-bit Windows, try:
	 *   mex -D_WINDOWS_ -I./win32 matToQuat.c nifti1_io.c znzlib.c ./win32/zlib.lib
	 * On 64-bit Windows, try:
	 *   mex -D_WINDOWS_ -I./win64 matToQuat.c nifti1_io.c znzlib.c ./win64/zlib.lib
	 */
	
	#include <mex.h>
	#include "nifti1_io.h"
	
	void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[]){
	  int *dim;
	  const char *fnames[11];
	  int i=0;
	  double* mx;
	  mat44 mat;
	  float qb, qc, qd;
	  float qx, qy, qz;
	  float dx, dy, dz;
	  float qfac;
	  char *str = "foo";
	 
	  if(nrhs!=1){
	    mexPrintf("\nmatToQuat(matrix)\n\n");
	                        mexPrintf("Converts a matrix to the quaternion format\n");
	                        mexPrintf("needed to fill out the qform fields of NIFTI\n\n");
	                        return;
	    }else if(nlhs>1) { mexPrintf("Too many output arguments\n"); return; }
	 
	  if (!mxIsNumeric(prhs[0]) || mxIsComplex(prhs[0])) {
	    mexErrMsgTxt("Wrong sort of data (1).");
	  }
	  if (mxGetNumberOfDimensions(prhs[0]) != 2) {
	    mexErrMsgTxt("Wrong number of dims (should be 2).");
	  }
	  dim  = (int *)mxGetDimensions(prhs[0]);
	  if (dim[0] != 4 || dim[1] != 4) {
	    mexErrMsgTxt ("Matrix is not 4x4!.");
	  }
	
	  /* create a Matlab struct for output  */
	  fnames[i++] = "quatern_b";
	  fnames[i++] = "quatern_c";
	  fnames[i++] = "quatern_d";
	  fnames[i++] = "quatern_x";
	  fnames[i++] = "quatern_y";
	  fnames[i++] = "quatern_z";
	  fnames[i++] = "dx";
	  fnames[i++] = "dy";
	  fnames[i++] = "dz";
	  fnames[i++] = "qfac";
	  fnames[i++] = "blah";
	
	  plhs[0] = mxCreateStructMatrix(1, 1, 11, fnames);
	
	  mx = (double *)mxGetPr(prhs[0]);
	 
	  for(i=0; i<16; i++) mat.m[i%4][i/4] = (float) mx[i];
	 
	  nifti_mat44_to_quatern (mat,
	                          &qb, &qc, &qd,
	                          &qx, &qy, &qz,
	                          &dx, &dy, &dz,
	                          &qfac);
	
	  mxSetField(plhs[0], 0, "quatern_b", mxCreateDoubleScalar (qb));
	  mxSetField(plhs[0], 0, "quatern_c", mxCreateDoubleScalar (qc));
	  mxSetField(plhs[0], 0, "quatern_d", mxCreateDoubleScalar (qd));
	  mxSetField(plhs[0], 0, "quatern_x", mxCreateDoubleScalar (qx));
	  mxSetField(plhs[0], 0, "quatern_y", mxCreateDoubleScalar (qy));
	  mxSetField(plhs[0], 0, "quatern_z", mxCreateDoubleScalar (qz));
	  mxSetField(plhs[0], 0, "dx", mxCreateDoubleScalar (dx));
	  mxSetField(plhs[0], 0, "dy", mxCreateDoubleScalar (dy));
	  mxSetField(plhs[0], 0, "dz", mxCreateDoubleScalar (dz));
	  mxSetField(plhs[0], 0, "qfac", mxCreateDoubleScalar (qfac));
	  mxSetField(plhs[0], 0, "blah", mxCreateString (str));	
    }
