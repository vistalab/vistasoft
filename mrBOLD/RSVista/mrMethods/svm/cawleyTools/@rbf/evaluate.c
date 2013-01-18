/******************************************************************************

File        : @rbf/evaluate.c

Date        : Saturday 18th March 2000 

Author      : Dr Gavin C. Cawley

Description : Mex file reimplemetation of the kernel evaluation method of a
              MATLAB class implementing a Gaussian radial basis kernel.

History     : 18/03/2000

Copyright   : (c) G. C. Cawley, March 2000.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

******************************************************************************/

#include <math.h>

#include "mex.h"

double square(double x)
{
   return x*x;
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   double *x1, *x2, *y, gamma;

   int row, i, j, k, m, n, o, N;

   const mxArray *net;

   /* check number of input and output arguments */

   if (nrhs != 3)
   {
      mexErrMsgTxt("Wrong number input arguments.");
   }
   else if (nlhs > 1)
   {
      mexErrMsgTxt("Too many output arguments.");
   }

   /* get kernel structure */

   gamma = mxGetScalar(mxGetField(prhs[0],0,"gamma"));

   /* get input arguments */

   if (!mxIsDouble(prhs[1]) || mxIsComplex(prhs[1]))
   {
      mexErrMsgTxt("x1 must be a double matrix.");
   }

   m  = mxGetM(prhs[1]);
   x1 = mxGetPr(prhs[1]);

   if (!mxIsDouble(prhs[2]) || mxIsComplex(prhs[2]))
   {
      mexErrMsgTxt("x2 must be a double matrix.");
   }

   n  = mxGetM(prhs[2]);
   o  = mxGetN(prhs[2]);
   x2 = mxGetPr(prhs[2]);

   /* allocate and initialise output matrix */

   plhs[0] = mxCreateDoubleMatrix(m, n, mxREAL);

   y = mxGetPr(plhs[0]);

   /* compute kernel matrix */

   for (i = 0; i < m; i++)
   {
      for (j = 0; j < n; j++)
      {
         for (k = 0; k < o; k++)
         {
            y[i+j*m] += square(x1[i+k*m] - x2[j+k*n]);
         }
      }
   }

   for (i = 0; i < m*n; i++)
   {
      y[i] = exp(-gamma*y[i]);
   }

   /* bye bye... */
}

/**************************** That's all Folks!  *****************************/

