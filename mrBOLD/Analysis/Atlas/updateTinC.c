// HISTORY:
// 2001.07.03: donated by Bernd Fischer <fischer@math.mu-luebeck.de>
//

#include "mex.h"
#include <math.h>

void updateTinC(double Tnew[],double Xphi[],double Yphi[],double T[],int m,int n ){
  int i, j, count = 0;
  double xc, xi, yc, eta;
  int xd, xe, yd, ye;

  for( j=0; j<n; j++ ) {
    for( i=0; i<m; i++ ){
      xc  = *(Xphi+count) - 1.0; 
      yc  = *(Yphi+count) - 1.0; 
      /* sind die Koordinaten ausserhalb des Bildes? */
      if ( (xc<0) || (xc>m-1) || (yc<0) || (yc>n-1) ) { 
			*(Tnew+count) = Tnew[0]; /* wenn ausserhalb Farbwert Tnew(1,1) nehmen */
      } 
		else {
			xd  = (int)xc;  
			xe  = xd+1;	
			xe  = (xe > m-1)? m-1 : xe; /* ueber den Rand, dann zurueck */
			xi  = xc - xd;
			yd  = (int)yc;  
			ye  = yd+1;
			ye  = (ye > n-1)? n-1 : ye; /* ueber den Rand, dann zurueck */
			eta = yc - yd;
	
			/* Bilinear Ansatz im Quadrat [i,i+1]x[j,j+1] */
	
			*(Tnew+count) = (T[xd+m*yd]*(1-eta)+T[xd+m*ye]*eta)*(1-xi)+(T[xe+m*yd]*(1-eta)+T[xe+m*ye]*eta)*xi;
      }; /* end else */
      count++;
    } /* end for i */
  } /* end for j */
  return;
} /* end updateTinC */

void mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[]){
  double *Xphi, *Yphi, *T, *Tnew;
  unsigned int  m, n;
  Xphi = mxGetPr(prhs[1]);
  Yphi = mxGetPr(prhs[2]);

  m  = mxGetM(prhs[0]);
  n  = mxGetN(prhs[0]);
  T  = mxGetPr(prhs[0]);

  /* Create Matrix for the return argument */
  plhs[0] = mxCreateDoubleMatrix(m,n,mxREAL);

  /* create pointer to input and output*/
  Tnew = mxGetPr(plhs[0]);
  updateTinC(Tnew,Xphi,Yphi,T,m,n);
} /* end mexFunction */
