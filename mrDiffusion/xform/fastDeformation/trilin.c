/*
 *
 * trilin.c
 *
 * (c) 2002 Stefan Wirtz
 *
 */

#include "mex.h"
#include <math.h>

/* 
Aufruf:  Tnew=trilin(T,X,Y,Z);
trilineare Interpolation von T an den Stellen (I-X,I-Y,I-Z) in Matlabnotation (1:n)

SW 8/2002
*/


void trilin(double Tnew[],double X[],double Y[],double Z[],double T[],int n1,int n2,int n3 ){
  int i, j, k, n12=n1*n2, count = 0;
  /* (xc,yc,zc) \in [xd,xe]x[yd,ye]x[zd,ze] */
  double xc, yc, zc, dx, dy, dz;
  int xd, xe, yd, ye, zd, ze;

  for( k=0; k<n3; k++ ){
   for( j=0; j<n2; j++ ){
    for( i=0; i<n1; i++ ){
      xc  = i - *(X+count); /* von 1:n auf 0:n-1 zurueckrechnen */
      yc  = j - *(Y+count); 
      zc  = k - *(Z+count);
      /* sind die Koordinaten ausserhalb des Bildes? */
      if ( (xc<0) || (xc>n1-1) || (yc<0) || (yc>n2-1) || (zc<0) || (zc>n3-1) ) { 
			*(Tnew+count) = T[0]; /* wenn ausserhalb Farbwert T(1,1) nehmen */
      } 
		else {
			xd = (int)xc;  
			xe = xd+1;	
			xe = (xe > n1-1)? n1-1 : xe; /* ueber den Rand, dann zurueck */
			yd = (int)yc;  
			ye = yd+1;
			ye = (ye > n2-1)? n2-1 : ye; /* ueber den Rand, dann zurueck */
			zd = (int)zc;  
			ze = zd+1;
			ze = (ze > n3-1)? n3-1 : ze; /* ueber den Rand, dann zurueck */

         dx = xc - xd;
			dy = yc - yd;
         dz = zc - zd;
/*	der Uebersicht halber hier noch mal ausfuehrlich:
|         *(Tnew+count) =   T[xd+n1*yd+n12*zd]*(1-dx)*(1-dy)*(1-dz) + 
|                           T[xd+n1*ye+n12*zd]*(1-dx)*(dy)*(1-dz)   + 
|                           T[xe+n1*yd+n12*zd]*(dx)*(1-dy)*(1-dz)   + 
|                           T[xe+n1*ye+n12*zd]*(dx)*(dy)*(1-dz)     + 
|                           T[xd+n1*yd+n12*ze]*(1-dx)*(1-dy)*(dz)   + 
|                           T[xd+n1*ye+n12*ze]*(1-dx)*(dy)*(dz)     + 
|                           T[xe+n1*yd+n12*ze]*(dx)*(1-dy)*(dz)     +
|                           T[xe+n1*ye+n12*ze]*(dx)*(dy)*(dz);
*/

/* und nun ausgeklammert, um Zeit zu sparen */
         *(Tnew+count) = ( (T[xd+n1*yd+n12*zd]*(1-dy)+T[xd+n1*ye+n12*zd]*(dy))*(1-dx) +
                           (T[xe+n1*yd+n12*zd]*(1-dy)+T[xe+n1*ye+n12*zd]*(dy))*(dx)     )*(1-dz) +
                         ( (T[xd+n1*yd+n12*ze]*(1-dy)+T[xd+n1*ye+n12*ze]*(dy))*(1-dx) +
                           (T[xe+n1*yd+n12*ze]*(1-dy)+T[xe+n1*ye+n12*ze]*(dy))*(dx)     )*(dz);

      }; /* end else */
      count++;
    } /* end for i */
   } /* end for j */
  } /* end for k */
  return;
} /* end trilinearInC */

void mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[]){
  double *X, *Y, *Z, *T, *Tnew;
  unsigned int  n1, n2, n3;
  const int* dims;

  X = mxGetPr(prhs[1]);
  Y = mxGetPr(prhs[2]);
  Z = mxGetPr(prhs[3]);

  dims = mxGetDimensions(prhs[0]);
  n1 = dims[0];
  n2 = dims[1];
  n3 = dims[2];

  T  = mxGetPr(prhs[0]);

  /* Create Matrix for the return argument */
  plhs[0] = mxCreateNumericArray(3, dims, mxDOUBLE_CLASS, mxREAL);

  /* create pointer to input and output*/
  Tnew = mxGetPr(plhs[0]);
  trilin(Tnew,X,Y,Z,T,n1,n2,n3);
} /* end mexFunction */
