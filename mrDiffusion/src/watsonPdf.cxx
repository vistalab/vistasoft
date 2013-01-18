/* C-Mex implementation for watsonPdf.cxx
 *
 * To compile on most platforms, run:
 *    strPath2Util = ''; %% Path to DTIQuery util directory.
 *    cmd = ['mex -O -I' strPath2Util ' watsonPdf.cxx ' fullfile(strPath2Util,'DTIMath.cpp') ' ' fullfile(strPath2Util,'dcdf.cpp')];
 *    eval(cmd)
 *
 * To compile under linux with gcc, run:
 *    mex -O COPTIMFLAGS='-O3 -march=i686 -DNDEBUG' watsonPdf.cxx
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
    mexErrMsgTxt("Inputs are: meanVec (3x1), testVectors (3xN), k value (1x1)");
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
  double    *meanPtr = mxGetPr(prhs[0]);
  const int *dimsMeanPtr = mxGetDimensions(prhs[0]);
  if( dimsMeanPtr[0] != 3 || dimsMeanPtr[1] != 1 ) {
    mexErrMsgTxt("First vector is mean of distribution. I.e. m = [1;0;0]");
    exit(-1);
  }

  // Get input vector
  double    *testPtr = mxGetPr(prhs[1]);
  const int *dimsTestPtr = mxGetDimensions(prhs[1]);
  int N = dimsTestPtr[1];
  if( dimsMeanPtr[0] != 3) {
    mexErrMsgTxt("Second input is matrix of test vectors. I.e. V = [v1, v2, v3, ...]");
    exit(-1);
  }

  DTIVector meanVec(3);
  DTIVector testVec(3);
  meanVec[0] = meanPtr[0]; meanVec[1] = meanPtr[1]; meanVec[2] = meanPtr[2];
  double *kPtr = mxGetPr(prhs[2]);

  plhs[0] = mxCreateDoubleMatrix(1,N,mxREAL);
  double *outPtr = mxGetPr(plhs[0]);
  for(int ii=0; ii<N; ii++){
    testVec[0] = testPtr[ii*3]; testVec[1] = testPtr[1+ii*3]; testVec[2] = testPtr[2+ii*3];
    double xDotMean = dproduct(testVec,meanVec);
    outPtr[ii] = exp( DTIMath::logWatsonPDF( xDotMean, kPtr[0]) ) / (4*M_PI);
  }
}
