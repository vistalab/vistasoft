/*  Matlab MEX file.

regHistogram.c - Computes histogram for N-Dimensional arrays.
                 Much faster than matlab hist.
                 Permits only regularly spaced bins.

[h, x] = regHistogram(A, <Nbins>);

Oscar Nestares - 5/99

*/

#include "mex.h"
#include <stdio.h>
#include <ctype.h>
#include <math.h>
#include <sys/types.h>

/* histogram - MAIN C routine.
     dat -> pointer to the data
     npoints -> number of points in the data
     h -> pointer to the computed histogram (must be an array of Nbins+1)
     x -> pointer to the computed bin centers (must be an array of Nbins+1)
     Nbins -> number of bins in the histogram
   */
void histogram(register const double *dat, register int npoints, register double *h, register double *x, int Nbins)   
{
   register int i;    /* loop index */
   register double Nrange;   /* normalized range of the data Nbins*(Max-Min) */
   double BinWidth; /* width of the histogram bins */
   register double MinX;     /* minimum bin value */
   register double Min, Max; /* minimum and maximum values of the data */
   register double temp;
   register int bin;

   /* selecting min and max values */
   Min = *dat; Max = Min;
   for(i=1; i<npoints; i++)
      {
      temp = dat[i];
      if (temp>Max) { Max = temp; }
      else if (temp<Min) { Min = temp; }
   }
   Nrange = Nbins/(Max-Min);

   /* histogram */
   for(i=0; i<npoints; i++) {
     bin = (int) ((dat[i]-Min)*Nrange);
     h[bin] += 1.0;
   }

   /* incorporating number of Max to the last histogram bin */
   h[Nbins-1] = h[Nbins-1] + h[Nbins];

   /* values of the bins */
   BinWidth = 1/Nrange;
   MinX = Min + BinWidth / 2;
   for(i=0; i<Nbins; i++)
     x[i] = MinX + BinWidth*i;

}


void mexFunction(int nlhs,   /* number of arguments on lhs */
		 mxArray	*plhs[],   /* Matrices on lhs      */
		 int nrhs,	   /* no. of mat on rhs    */
		 const mxArray	*prhs[]    /* Matrices on rhs      */
		 )
{
  register const double *data;     /* pointer to input data */
  mxArray *xArray;  /* pointer to output x */
  register double *h, *x;/* pointers to histogram and intensity values */
  register int npoints;      /* number of points in the input array */
  int Nbins;        /* number of bins in the histogram */
  double *NbinsPtr; /* pointer to the number of bins input argument */
  int Outdims[2];   /* dimensions of the output arrays */

  /* Check for proper number of arguments */
  if (nrhs<1) { /* help */
   printf("[h, x] = regHistogram(A, <Nbins>);\n");
   printf("    Computes the histogram of a N-dimensional array (A), \n");
   printf("    using Nbins intervals (default = 256). \n");
  }

  /* reading input parameters */
  data = mxGetPr(prhs[0]);
  npoints = mxGetNumberOfElements(prhs[0]);
  if (nrhs==2) {
    NbinsPtr = mxGetPr(prhs[1]);
    Nbins = (int)(*NbinsPtr);}
  else {
    Nbins = 256;}

  /* creating output array for histogram and intensity values, with
     room for one more value (corresponding to Max */
  Outdims[0] = 1; Outdims[1] = Nbins+1;
  plhs[0] = mxCreateNumericArray(2, Outdims, mxDOUBLE_CLASS, mxREAL);
  xArray = mxCreateNumericArray(2, Outdims, mxDOUBLE_CLASS, mxREAL);
  h = mxGetPr(plhs[0]);
  x = mxGetPr(xArray);

  /* main routine */
  histogram(data, npoints, h, x, Nbins);

  /* returning arrays with the actual number of bins */
  Outdims[0] = 1; Outdims[1] = Nbins;
  mxSetDimensions(plhs[0], Outdims, 2);
  mxSetDimensions(xArray, Outdims, 2);

  /* returning bin centers if requested */
  if (nlhs == 2) {
    plhs[1] = xArray;
  }
}
