/******************************************************************************

File        : LrrCache.h

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

class LrrCache : public Cache
{

protected:

   int ncl, maxcl;

   double **K;

   int counter;

   int *time;

   int *pattern;

   int *line;

   mxArray *rhs[3];

   void loadLine(int i, int a);

   int load(int a);

public:

   double fetch(int i, int j);

   LrrCache(mxArray *kernel, mxArray *x);
};

/***************************** That's all Folks! *****************************/
