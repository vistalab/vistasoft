#include "mex.h"
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  double d;
  double *A, *B, *Ap, *Bp, *Ae, *Be, *Ac, *R;
  int Am;
  
  if (nrhs != 2) {
     mexErrMsgTxt("Exactly two inputs required.");
  }
  if (nlhs > 1) {
     mexErrMsgTxt("Too many outputs.");
  }
  if (!mxIsDouble(prhs[0]) || !mxIsDouble(prhs[1]) ||
      mxIsSparse(prhs[0]) || mxIsSparse(prhs[1]) ||
      mxGetNumberOfDimensions(prhs[0]) != 2 ||
      mxGetNumberOfDimensions(prhs[1]) != 2 ||
      mxIsComplex(prhs[0]) || mxIsComplex(prhs[1]) ) {
     mexErrMsgTxt("Inputs must be full, real, double 2D matrices.");
  }
  if (mxIsEmpty(prhs[0]) || mxIsEmpty(prhs[1])) {
     plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
     return;
  }
  
  A = mxGetPr(prhs[0]);
  B = mxGetPr(prhs[1]);
  Am = mxGetM(prhs[0]);
  if (Am != mxGetM(prhs[1])) {
     mexErrMsgTxt("Number of rows of A and B must be the same.");
  }
  
  plhs[0] = mxCreateDoubleMatrix(mxGetN(prhs[0]), mxGetN(prhs[1]), mxREAL);
  R = mxGetPr(plhs[0]);
  
  Ae = A + mxGetNumberOfElements(prhs[0]);
  Be = B + mxGetNumberOfElements(prhs[1]);
  Ap = A;
  while (B < Be) {
     while (Ap < Ae) {
        Bp = B;
        Ac = Ap + Am;
        *R = *Ap++ * *Bp++;
        while (Ap < Ac) {
           d = *Ap++ * *Bp++;
           if (d > *R) {
             *R = d;
           }
        }
        R++;
     }
     B = Bp;
     Ap = A;
  }
}
