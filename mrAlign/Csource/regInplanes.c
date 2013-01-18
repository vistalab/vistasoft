/*  Matlab MEX file.

regInplanes.c - Generates a set of interpolated inplanes from the volume,
                correcting for the voxel sizes.

inp = regInplanes(vol, NxI, NyI, NzI, scaleFac, rot, trans, <badval>)

Oscar Nestares - 5/99

*/

#include "mex.h"
#include <stdio.h>
#include <ctype.h>
#include <math.h>
#include <sys/types.h>

/* Cinplanes - MAIN C routine.
  This function takes a cube of coordinates from 1:NxI,1:NyI,1:NzI, transforms 
  it applying the rotation and translation matrix, and the scaleFactors, and
  interpolates the corresponding values from the volume.
  If the scaleFactors are different for the inplanes (first row) than for the
  volume (second row), the function oversamples and then
  averages to adjust the resolution.
*/
void Cinplanes(register double *vol, int NxV, int NyV, int NzV, int NxI, int NyI, int NzI,
            double *sFac, double *M, register double *f, double badval)
	    
{
   register int x, y, z, i, j, k, NxNy, index, ind; /* indexes and sizes */
   register double ox, oy, oz;  /* oversampled coordinates (inplane coordinate system)*/
   register double xM, yM, zM;  /* transformed coordinates (volume coordinate system)*/
   register double wa,wb,wc;    /* distance from non-integer coordinate to integer one */
   register int a,b,c;       /* integer part of the coordinate */
   register double m11 = *M;    /* transformation matrix*/
   register double m21 = *(M+1);
   register double m31 = *(M+2);
   register double m12 = *(M+4);
   register double m22 = *(M+5);
   register double m32 = *(M+6);
   register double m13 = *(M+8);
   register double m23 = *(M+9);
   register double m33 = *(M+10);
   register double m14 = *(M+12);
   register double m24 = *(M+13);
   register double m34 = *(M+14);
   double FSVol;       /* maximum sampling frequency for the volume */
   double srx,sry,srz; /* normalized sampling rates for oversampled inplanes */
   int badflag; /* activated if oversampled point is outside vol. bounds */
   double npts; /* number of oversamp. points corresponding to 1 inplane point*/


   /* choosing sampling rates to obtain oversampled inplane coordinates */
   /* they are based on the maximun sampling frequency for the VOLUME */
   FSVol = 0;
   for(i=0; i<3; i++)
     if (sFac[1+2*i]> FSVol)
        FSVol = sFac[1+2*i];
   srx = 1/ceil(FSVol/sFac[0]);
   sry = 1/ceil(FSVol/sFac[2]);
   srz = 1/ceil(FSVol/sFac[4]);
   npts = ceil(FSVol/sFac[0])*ceil(FSVol/sFac[2])*ceil(FSVol/sFac[4]);

   /* sagittal size of the volume */
   NxNy = NxV*NyV;

   /* index for inplane pixels */
   ind = 0;

   /* loops for inplane coordinates */
   for (z=1;z<=NzI;z++)
   for (x=1;x<=NxI;x++) 
   for (y=1;y<=NyI;y++) {

     badflag = 0;  /* reset badflag */
     /* mean over oversampled coordinates */
     oz = z-(1-srz)/2; 
     for (k=0; k<(1/srz); k++)
     {
     ox = x-(1-srx)/2;
     for (i=0; i<(1/srx); i++)
     {
     oy=y-(1-sry)/2;
     for (j=0; j<(1/sry); j++)
     {
       /* computing current interpolated coordinates */
       xM = (ox*m11/sFac[0]+oy*m12/sFac[2]+oz/sFac[4]*m13+m14) * sFac[1];
       yM = (ox*m21/sFac[0]+oy*m22/sFac[2]+oz/sFac[4]*m23+m24) * sFac[3];
       zM = (ox*m31/sFac[0]+oy*m32/sFac[2]+oz/sFac[4]*m33+m34) * sFac[5];
       /* distances to nearest lower integer coordinate */
       a = (int) xM; wa = xM - a; a--;
       b = (int) yM; wb = yM - b; b--;
       c = (int) zM; wc = zM - c; c--;
       if (a<0 || a>=NxV-1 || 
	   b<0 || b>=NyV-1 ||
	       c<0 || c>=NzV-1 ) badflag = 1;
       else { 
       /* linear interpolation */
       index=c*NxNy+a*NyV+b;

       f[ind] = f[ind] + (1-wc) * ( (1-wa) * ( (1-wb) * (*(vol+index)) 
                                   +   wb  * (*(vol+index+1)) )
                        +   wa  * ( (1-wb) * (*(vol+index+NyV))
                                   +   wb  * (*(vol+index+NyV+1))  ))
             +   wc  * ( (1-wa) * ( (1-wb) * (*(vol+index+NxNy)) 
                                    +  wb  * (*(vol+index+NxNy+1)) ) 
                        +   wa  * ( (1-wb) * (*(vol+index+NxNy+NyV))
                                    +  wb  * (*(vol+index+NxNy+NyV+1)) ) ); 
       }
     oy = oy+sry;
     }
     ox = ox+srx;
     }
     oz = oz+srz;
     }
     /* computing the mean */
     if (badflag==1) {
	 f[ind] = badval;}
     else {
	 f[ind] = f[ind]/npts;}
    ind++;
 }

}


void mexFunction(int nlhs,   /* number of arguments on lhs */
		 mxArray	*plhs[],   /* Matrices on lhs      */
		 int nrhs,	   /* no. of mat on rhs    */
		 const mxArray	*prhs[]    /* Matrices on rhs      */
		 )
{
  const mxArray *vol;        /* input volume array */
  double *voldata;    /* pointer to input volume data */
  double *NxI, *NyI, *NzI;  /* inplane dimensions */
  double *scaleFac;  /*sampling rates */
  double *rot, *trans; /* rotation matrix and translation vector */
  double badval;  /* bad value to fill out of bounds positions */
  int dims[3];    /* inplane dimensions, array form */
  double *f;      /* pointer to the output matrix data */
  int ndimsvol;   /* number of dimensions of the input volume */
  const int *dimsvol;   /* dimensions of the vol, array form */
  int NxV, NyV, NzV; /* dimensions of the vol */ 
  double M[16];      /* 4x4 transformation matrix */
  int i, j; /* loop indexes */

  /* Check for proper number of arguments */
  if (nrhs==0) { /* help */
   printf("inp = inplanes(vol, NxI, NyI, NzI, scaleFac, rot, trans, <badval>)\n");
   printf("\n  vol: volume anatomy data (3D array)\n");
   printf("  NxI, NyI, NzI: size of the inplanes\n");
   printf("  scaleFac: sampling rates (first row: inplanes; second: volume)\n");
   printf("  rot:  3x3 rotation matrix\n");
   printf("  trans:  1x3 translation matrix\n");
   printf("  badval (opt.): returned for points outside volume (default=0)\n");
   return;
  }
  else {
    if (nrhs < 7) {
      mexErrMsgTxt("inplanes needs at least seven arguments.");
    }
  }

  /* reading input parameters */
  vol = prhs[0];
  voldata = mxGetPr(vol);
  NxI = mxGetPr(prhs[1]);
  NyI = mxGetPr(prhs[2]);
  NzI = mxGetPr(prhs[3]);
  scaleFac = mxGetPr(prhs[4]);
  rot = mxGetPr(prhs[5]);
  trans = mxGetPr(prhs[6]);
  if (nrhs==8) {
    badval=*mxGetPr(prhs[7]);
  }
  else {
    badval=0.0;
  }
  
  /* geting volume size */
  ndimsvol = mxGetNumberOfDimensions(vol);
  if (ndimsvol!=3) {
      mexErrMsgTxt("vol must be a 3-D array.");
  }
  else {
      dimsvol = mxGetDimensions(vol);
      NxV = dimsvol[1];
      NyV = dimsvol[0];
      NzV = dimsvol[2];
  }

  /* creating output array for the inplanes */
  dims[0] = (int) *NyI; dims[1] = (int) *NxI; dims[2] = (int) *NzI;
  plhs[0] = mxCreateNumericArray(3, dims, mxDOUBLE_CLASS, mxREAL);
  f = mxGetPr(plhs[0]);

  /* creating the homogeneus transformation matrix M from rot and trans */
  for(i=0; i<3; i++)
    for(j=0; j<3; j++)
       M[j+4*i] = rot[j+3*i];
  for(i=0; i<3; i++)
       M[i+12] = trans[i];

  /* main routine */
  Cinplanes(voldata, NxV, NyV, NzV, dims[1], dims[0], dims[2], scaleFac, M, f, badval);  

}
