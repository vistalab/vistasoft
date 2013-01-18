/******************************************************************************

File        : smotrain.c

Date        : Wednesday 13th September 2000

Author      : Dr Gavin C. Cawley

Description : MATLAB interface function for a C++ MEX implementation of
              Vapnik's support vector machine (SVM) [1] trained using the
              sequential minimal optimisation algorithm due to Platt [2].

References  : [1] V. N. Vapnik, "The Nature of Statistical Learning Theory",
                  Springer-Verlag, New York, ISBN 0-387-94559-8, 1995.

              [2] J. C. Platt, "Fast Training of Support Vector Machines using
                  Sequential Minimal Optimization".  In B. Scholkopf, C. J. C.
                  Burges and A. J. Smola, editors, "Advances in Kernel Methods
                  - Support Vector Learning", pp 185-208, MIT Press, 1998.

History     : 07/07/2000 - v1.00
              13/09/2000 - v1.01 minor improvements to comments

Copyright   : (c) Dr Gavin C. Cawley, September 2000.

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

#include "mex.h"

#include "Cache.h"
#include "InfCache.h"
#include "LrrCache.h"
#include "SmoTutor.h"

// net = smosvctrain(tutor, x, y, C, kernel, zeta, alpha, bias);

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   mxArray *x, *y, *C, *kernel, *zeta, *alpha, *bias;

   /* check number of input and output arguments */

   if (nrhs != 8)
   {
      mexErrMsgTxt("Wrong number of input arguments.");
   }

   if (nlhs > 1)
   {
      mexErrMsgTxt("Too many output arguments.");
   }

   // the first argument is the tutor object, only used in dynamic binding

   // get input patterns 

   if (!mxIsDouble(prhs[1]) || mxIsComplex(prhs[1]))
   {
      mexErrMsgTxt("x must be a double matrix.");
   }

   x  = (mxArray*)prhs[1];

   // get target patterns 

   if (!mxIsDouble(prhs[2]) || mxIsComplex(prhs[2]))
   {
      mexErrMsgTxt("y must be a double matrix.");
   }

   y = (mxArray*)prhs[2];

   // get regularisation parameter 

   if (!mxIsDouble(prhs[3]) || mxIsComplex(prhs[3]))
   {
      mexErrMsgTxt("C must be a double scalar.");
   }

   C = (mxArray*)prhs[3];

   // get kernel structure 

   if (!mxIsStruct(prhs[4]))
   {
      mexErrMsgTxt("kernel must be a structure.");
   }

   kernel = (mxArray*)prhs[4];

   // get pattern weighting factors

   if (!mxIsDouble(prhs[5]) || mxIsComplex(prhs[5]))
   {
      mexErrMsgTxt("zeta must be a double matrix.");
   }

   zeta = (mxArray*)prhs[5];

   // get Lagrange multipliers

   if (!mxIsDouble(prhs[6]) || mxIsComplex(prhs[6]))
   {
      mexErrMsgTxt("alpha must be a double matrix.");
   }

   alpha = (mxArray*)prhs[6];

   // get bias 

   if (!mxIsDouble(prhs[7]) || mxIsComplex(prhs[7]))
   {
      mexErrMsgTxt("alpha must be a double matrix.");
   }

   bias = (mxArray*)prhs[7];

   // get on with it

   SmoTutor tutor = SmoTutor(x,
                             y,
                             C,
                             kernel,
                             zeta,
                             alpha,
                             bias,
                             new LrrCache(kernel, x));

   plhs[0] = tutor.train();

   // bye bye... 
}

/***************************** That's all Folks! *****************************/

