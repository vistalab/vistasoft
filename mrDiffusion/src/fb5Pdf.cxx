/* C-Mex implementation for fb5Pdf.cxx
 *
 * To compile on most platforms, run:
 *    strPath2Util = ''; %% Path to DTIQuery util directory.
 *    cmd = ['mex -O -I' strPath2Util ' fb5Pdf.cxx ' fullfile(strPath2Util,'DTIMath.cpp') ' ' fullfile(strPath2Util,'dcdf.cpp')];
 *    eval(cmd)
 *
 * To compile under linux with gcc, run:
 *    mex -O COPTIMFLAGS='-O3 -march=i686 -DNDEBUG' fb5Pdf.cxx
 *
 * Original code was lifted from;
 * 
 * 2007-03-26: AJS Created it.
 */


#include <math.h>
#include <mex.h>
#include <iostream>
#include <DTIMath.h>

using namespace std;


/*********************************************************************
 * Entry point for MEX function
*/
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]){


  /* Check number of arguments */
  if(nrhs != 3){
    mexErrMsgTxt("Inputs are: eigVecs (3x3), testVectors (3xN), k value (2x1)");
    exit(-1);
  }else if (!mxIsDouble(prhs[0]) || mxIsComplex(prhs[0]) ||
	    mxGetNumberOfDimensions(prhs[0]) != 2 ||
	    !mxIsDouble(prhs[1]) || mxIsComplex(prhs[1]) ||
	    mxGetNumberOfDimensions(prhs[1]) != 2 ||
	    !mxIsDouble(prhs[2]) || mxIsComplex(prhs[2]) ||
	    mxGetNumberOfDimensions(prhs[2]) != 2){

    mexErrMsgTxt("Inputs must be real scalar arrays.");
    exit(-1);
  }

  // Get input vector
  double    *eigPtr = mxGetPr(prhs[0]);
  const int *dimsEigPtr = mxGetDimensions(prhs[0]);
  if( dimsEigPtr[0] != 3 || dimsEigPtr[1] != 2 ) {
    mexErrMsgTxt("First matrix is [eVec2,eVec3]");
    exit(-1);
  }

  // Get input vector
  double    *testPtr = mxGetPr(prhs[1]);
  const int *dimsTestPtr = mxGetDimensions(prhs[1]);
  int N = dimsTestPtr[1];
  if( dimsTestPtr[0] != 3) {
    mexErrMsgTxt("Second input is matrix of test vectors. I.e. V = [v1, v2, v3, ...]");
    exit(-1);
  }

  DTIVector eVec2(3);
  DTIVector eVec3(3);
  DTIVector testVec(3);
  eVec2[0] = eigPtr[0]; eVec2[1] = eigPtr[1]; eVec2[2] = eigPtr[2];
  eVec3[0] = eigPtr[3]; eVec3[1] = eigPtr[4]; eVec3[2] = eigPtr[5];
  double *kPtr = mxGetPr(prhs[2]);

  plhs[0] = mxCreateDoubleMatrix(1,N,mxREAL);
  double *outPtr = mxGetPr(plhs[0]);
  for(int ii=0; ii<N; ii++){
    testVec[0] = testPtr[ii*3]; testVec[1] = testPtr[1+ii*3]; testVec[2] = testPtr[2+ii*3];
    outPtr[ii] = exp( DTIMath::logFB5PDF(testVec, eVec3, eVec2, kPtr[0], kPtr[1])) / (4*M_PI);
  }
}
