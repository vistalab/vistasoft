/******************************************************************************

File        : InfCache.cc

Date        : Wednesday 13th September 2000

Author      : Dr Gavin C. Cawley

Description : Class defining a structure ued to cache kernel evaluations in a
              MATLAB Implementation of Vapnik's support vector machine (SVM)
              [1] trained using the sequential minimal optimisation algorithm
              due to Platt [2].  This class implements an infinite, i.e. it
              is able to cache the entire Gram matrix.

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
#include "InfCache.h"

InfCache::InfCache(mxArray *kernel, mxArray *x) : Cache(x)
{
   mxArray *rhs[3], *lhs[1];

   rhs[0] = kernel;
   rhs[1] = x;
   rhs[2] = x;

   mexCallMATLAB(1, lhs, 3, rhs, "evaluate");
   
   K = mxGetPr(lhs[0]);
}

/***************************** That's all Folks! *****************************/

