/******************************************************************************

File        : SmoTutor.cc

Date        : Wednesday 13th September 2000

Author      : Dr Gavin C. Cawley

Description : Implementation of the sequential minimal optimisation (SMO)
              training algorithm for Vapnik's support vector machine (SVM)
              [1], due to Platt [2].

References  : [1] V. N. Vapnik, "The Nature of Statistical Learning Theory",
                  Springer-Verlag, New York, ISBN 0-387-94559-8, 1995.

              [2] J. C. Platt, "Fast Training of Support Vector Machines using
                  Sequential Minimal Optimization".  In B. Scholkopf, C. J. C.
                  Burges and A. J. Smola, editors, "Advances in Kernel Methods
                  - Support Vector Learning", pp 185-208, MIT Press, 1998.

History     : 07/07/2000 - v1.00
              13/09/2000 - v1.01 minor improvements to comments
              13/09/2000 - v1.10 zeta (pattern replication factors) and C
                                 removed from svc objects

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

#include <stdlib.h>
#include <math.h>

#include "mex.h"

#include "Cache.h"
#include "SmoTutor.h"

#include "utils.hh"

void rotor()
{
   static int counter = 0;

   char symbol[] = {'/', '-', '\\', '|'};

   counter = (counter + 1) % 4;

   mexPrintf("%c\b", symbol[counter]);
}

SmoTutor::SmoTutor(mxArray *x,
                   mxArray *y,
                   mxArray *C,
                   mxArray *kernel,
                   mxArray *zeta,
                   mxArray *alpha,
                   mxArray *bias,
                   Cache   *cache)
{
   this->ntp       = mxGetM(x);
   this->y         = mxGetPr(y);
   this->C         = (double*)mxCalloc(ntp, sizeof(double));
   this->bias      = mxGetScalar(bias);
   this->epsilon   = 1e-12;
   this->tolerance = 1e-3;
   this->minimum   = -1;
   this->maximum   = -1;
   this->error     = (double*)mxCalloc(ntp, sizeof(double));
   this->alpha     = mxGetPr(alpha);
   this->zeta      = zeta;
   this->x         = x;
   this->kernel    = kernel;
   this->cache     = cache;

   double c = mxGetScalar(C);

   double *z = mxGetPr(zeta);

   for (int i = 0; i < ntp; i++)
   {
      this->C[i] = c*z[i];

      if (this->alpha[i] > 0.0 && this->alpha[i] < this->C[i])
      {
         this->error[i] = fwd(i) - this->y[i];
      }
      else
      {
         this->error[i] = 0.0;
      }
   }
}

double SmoTutor::fwd(int n)
{
   double result = -bias;

   for (int i = 0; i < ntp; i++)
   {
      if (alpha[i] > 0.0)
      {
         result += y[i]*alpha[i]*cache->fetch(n, i);
      }
   }

   return result;
}

int SmoTutor::nonBoundLagrangeMultipliers()
{
   int result = 0;

   for (int i = 0; i < ntp; i++)
   {
      if (alpha[i] > 0.0 && alpha[i] < C[i])
      {
         result++;
      }
   }

   return result;
}

int SmoTutor::nonZeroLagrangeMultipliers()
{
   int result = 0;

   for (int i = 0; i < ntp; i++)
   {
      if (alpha[i] > 0.0)
      {
         result++;
      }
   }

   return result;
}

int SmoTutor::takeStep(int i1, int i2, double e2)
{
   if (i1 == i2)
   {
      return 0;
   }

   /* compute upper and lower constraints, L and H, on multiplier a2 */

   double alpha1 = alpha[i1];
   double alpha2 = alpha[i2];
   double y1     = y[i1];
   double y2     = y[i2];
   double L;
   double H;

   if (y1 != y2)
   {
      L = max(0,     alpha2 - alpha1);
      H = min(C[i2], alpha2 - alpha1 + C[i1]);
   }
   else
   {
      L = max(0,     alpha1 + alpha2 - C[i1]);
      H = min(C[i2], alpha1 + alpha2);
   }

   if (L == H)
   {
      return 0;
   }

   /* recompute Lagrange multiplier for pattern i2 */

   double e1;

   if (alpha1 > 0.0 && alpha1 < C[i1])
   {
      e1 = error[i1];
   }
   else
   {
      e1 = fwd(i1) - y1;
   }

   double k11 = cache->fetch(i1, i1);
   double k12 = cache->fetch(i1, i2);
   double k22 = cache->fetch(i2, i2);
   double eta = 2.0*k12-k11-k22;
   double s   = y1*y2;
   double a2  = 0.0;

   if (eta < 0.0)
   {
      a2 = alpha2 - y2*(e1 - e2)/eta;

      /* constrain a2 to lie between L and H */

      if (a2 < L)
      {
         a2 = L;
      }
      else if (a2 > H)
      {
         a2 = H;
      }
   }
   else
   {
      return 0;
   }

   if (fabs(a2-alpha2) < epsilon*(a2+alpha2+epsilon))
   {
      return 0;
   }

   /* recompute Lagrange multiplier for pattern i1 */

   double a1 = alpha1+s*(alpha2-a2);

   /* update vector of Lagrange multipliers */

   alpha[i1] = a1;
   alpha[i2] = a2;

   /* update threshold to reflect change in Lagrange multipliers */

   double w1   = y1*(a1 - alpha1);
   double w2   = y2*(a2 - alpha2);
   double b1   = e1 + w1*k11 + w2*k12;
   double b2   = e2 + w1*k12 + w2*k22;
   double bold = bias;

   bias += 0.5*(b1 + b2);

   /* update error cache->*/

   if (fabs(b1-b2) < epsilon)
   {
      error[i1] = 0.0;
      error[i2] = 0.0;
   }
   else
   {
      if (a1 > 0.0 && a1 < C[i1])
      {
         error[i1] = fwd(i1) - y1;
      }

      if (a2 > 0.0 && a2 < C[i2])
      {
         error[i2] = fwd(i2) - y2;
      }
   }

   if (error[i1] > error[i2])
   {
      minimum = i2;
      maximum = i1;
   }
   else
   {
      minimum = i1;
      maximum = i2;
   }

   for (int i = 0; i < ntp; i++)
   {
      if (alpha[i] > 0.0 && alpha[i] < C[i] && i != i1 && i != i2)
      {
         error[i] += w1*cache->fetch(i1, i)
                  +  w2*cache->fetch(i2, i)
                  +  bold - bias;

         if (error[i] > error[maximum])
         {
            maximum = i;
         }

         if (error[i] < error[minimum])
         {
            minimum = i;
         }
      }
   }

   /* report progress made */

   return 1;
}

int SmoTutor::examineNonBound(int i2, double e2)
{
   int start = rand() % ntp;

   for (int i = 0; i < ntp; i++)
   {
      int i1 = (i + start) % ntp;

      if (alpha[i1] > 0.0 && alpha[i1] < C[i1])
      {
         if (takeStep(i1, i2, e2))
         {
            return 1;
         }
      }
   }

   return 0;
}

int SmoTutor::examineBound(int i2, double e2)
{
   int start = rand() % ntp;

   for (int i = 0; i < ntp; i++)
   {
      int i1 = (i + start) % ntp;

      if (alpha[i1] == 0.0 || alpha[i1] == C[i1])
      {
         if (takeStep(i1, i2, e2))
         {
            return 1;
         }
      }
   }

   return 0;
}

int SmoTutor::examineFirstChoice(int i2, double e2)
{
   if (minimum > -1)
   {
      if (fabs(e2 - error[minimum]) > fabs(e2 - error[maximum]))
      {
         if (takeStep(minimum, i2, e2))
         {
            return 1;
         }
      }
      else
      {
         if (takeStep(maximum, i2, e2))
         {
            return 1;
         }
      }
   }

   return 0;
}

int SmoTutor::examineExample(int i2)
{
   double alpha2 = alpha[i2];
   double y2     = y[i2];
   double e2;

   if (alpha2 > 0.0 && alpha2 < C[i2])
   {
      e2 = error[i2];
   }
   else
   {
      e2 = fwd(i2) - y2;
   }

   double r2 = e2*y2;

   // take action only if i2 violates Karush-Kuhn-Tucker conditions

   if ((r2 < -tolerance && alpha2 < C[i2]) || (r2 > tolerance && alpha2 > 0))
   {
      if (examineFirstChoice(i2, e2))
      {
         return 1;
      }

      if (examineNonBound(i2, e2))
      {
         return 1;
      }

      if (examineBound(i2, e2))
      {
         return 1;
      }
   }

   // no progress possible

   return 0;
}

void SmoTutor::sequentialMinimalOptimisation()
{
   int numberChanged;
   int examineAll    = 0;
   int epoch         = 1;

   do
   {
      numberChanged = 0;

      if (examineAll == 1)
      {
         for (int i = 0; i < ntp; i++)
         {
            numberChanged += examineExample(i);
         }

         examineAll = 0;
      }
      else
      {
         for (int i = 0; i < ntp; i++)
         {
            if (alpha[i] > 0 && alpha[i] < C[i])
            {
               numberChanged += examineExample(i);
            }
         }

         if (numberChanged == 0)
         {
            examineAll = 1;
         }
      }

      /*
      mexPrintf("epoch %d number of changes %d/%d\n",
                epoch++,
                numberChanged,
                nonZeroLagrangeMultipliers());
      */
   }
   while (numberChanged > 0 || examineAll);
}

mxArray *SmoTutor::train()
{
   sequentialMinimalOptimisation();

   mxArray *rhs[4], *lhs[1];

   rhs[0] = kernel;                                   // kernel
   rhs[1] = x;                                        // svs
   rhs[2] = mxCreateDoubleMatrix(1, ntp, mxREAL);     // w
   rhs[3] = mxCreateDoubleMatrix(1, 1,   mxREAL);     // bias

   // set up weight vector

   double *w = mxGetPr(rhs[2]);

   for (int i = 0; i < ntp; i++)
   {
      w[i] = y[i]*alpha[i];
   }

   // set up bias

   *mxGetPr(rhs[3]) = bias;

   // form support vector machine

   mexCallMATLAB(1, lhs, 4, rhs, "svc");

   return lhs[0];
}

/***************************** That's all Folks! *****************************/
