/******************************************************************************

File        : LrrCache.cc

Date        : Wednesday 13th September 2000

Author      : Dr Gavin C. Cawley

Description : Class defining a structure ued to cache kernel evaluations in a
              MATLAB Implementation of Vapnik's support vector machine (SVM)
              [1] trained using the sequential minimal optimisation algorithm
              due to Platt [2].  Objects defined by this class cache columns
              of the kernel matrix, using a least recently accessed replacement
              rule.

References  : [1] V. N. Vapnik, "The Nature of Statistical Learning Theory",
                  Springer-Verlag, New York, ISBN 0-387-94559-8, 1995.

              [2] J. C. Platt, "Fast Training of Support Vector Machines using
                  Sequential Minimal Optimization".  In B. Scholkopf, C. J. C.
                  Burges and A. J. Smola, editors, "Advances in Cache Methods
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

#include <math.h>

#include "mex.h"

#include "Cache.h"
#include "LrrCache.h"

#include "utils.hh"

void LrrCache::loadLine(int i, int a)
{
   int j, k;

   double *X = mxGetPr(rhs[1]);
   double *x = mxGetPr(rhs[2]);

   for (j = 0, k = i; j < ni; j++, k += ntp)
   {
      x[j] = X[k];
   }

   mxArray *lhs[1];

   mexCallMATLAB(1, lhs, 3, rhs, "evaluate");

   x = mxGetPr(lhs[0]);

   // mexPrintf("m = %d, n = %d\n", mxGetM(lhs[0]), mxGetN(lhs[0]));

   for (j = 0; j < ntp; j++)
   {
      K[a][j] = x[j];
   }

   mxDestroyArray(lhs[0]);
}

int LrrCache::load(int i)
{
   if (ncl < maxcl)
   {
      line[i]      = ncl;
      pattern[ncl] = i;

      loadLine(i, ncl);

      return ncl++;
   }
   else
   {
      int a = 0;

      for (int b = 1; b < ncl; b++)
      {
         if (time[b] < time[a])
         {
            a = b;
         }
      }

      int j = pattern[a];

      line[i] =  a;
      line[j] = -1;

      pattern[a] = i;

      loadLine(i, a);

      return a;
   }
}

double LrrCache::fetch(int i, int j)
{
   int a = line[i];
   int b = line[j];

   if (a != -1)
   {
      time[a] = counter++;

      return K[a][j];
   }
   else if (b != -1)
   {
      time[b] = counter++;

      return K[b][i];
   }
   else
   {
      a = load(i);

      time[a] = counter++;

      return K[a][j];
   }
}

LrrCache::LrrCache(mxArray *kernel, mxArray *x) : Cache(x)
{
   int i;
   // set up cache
   static const long int CACHE_MEMORY = 134217728L/4;  // 128Mb

   maxcl   = (int)min(ntp, floor(CACHE_MEMORY/(8*ntp)));
   ncl     = 0;
   counter = 1;
   line    = (int*)mxCalloc(ntp,   sizeof(int));
   time    = (int*)mxCalloc(ntp,   sizeof(int));
   pattern = (int*)mxCalloc(maxcl, sizeof(int));
   K       = (double**)mxCalloc(maxcl, sizeof(double*));

   for (i = 0; i < maxcl; i++)
   {
      K[i]       = (double*)mxCalloc(ntp, sizeof(double));
      time[i]    =  0;
      pattern[i] = -1;
   }

   for (i = 0; i < ntp; i++)
   {
      line[i] = -1;
   }

   // set up kernel evaluation MATLAB interface workspace

   rhs[0] = kernel;
   rhs[1] = x;
   rhs[2] = mxCreateDoubleMatrix(1, ni, mxREAL);
}

/***************************** That's all Folks! *****************************/
