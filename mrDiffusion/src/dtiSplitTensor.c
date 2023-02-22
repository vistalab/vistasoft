/* C-Mex implementation for dtiSplitTensor.m
 *
 * To compile on most platforms, run:
 *    mex dtiSplitTensor.c
 *
 * On Microsoft Windows, you have to append one of the following filenames to
 * the command line, where <root> is what you get when you call matlabroot:
 *  - lcc compiler: <root>\extern\lib\win32\lcc\libmwlapack.lib
 *  - Visual C++:   <root>\extern\lib\win32\microsoft\msvc60\libmwlapack.lib
 *
 * To compile under linux with gcc, run:
 *    mex -O COPTIMFLAGS='-O3 -march=i686 -DNDEBUG' dtiSplitTensor.c
 */


#include <stdlib.h>
#include <mex.h>
#include <matrix.h>
#include <math.h>

#ifdef MAX
#undef MAX
#endif

#define MAX(a, b) ((a)>(b)?(a):(b))

#define n 3

void eigen_decomposition(double A[3][3], double V[3][3], double d[3]);

/*********************************************************************
 * Entry point for MEX function
*/
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    /* Check number of arguments */
    if (nrhs != 1) {
        mexErrMsgTxt("One input required.");
    } else if (nlhs != 2) {
        mexErrMsgTxt("Two outputs required.");
    } else if (!mxIsDouble(prhs[0]) || mxIsComplex(prhs[0]) ||
        mxGetNumberOfDimensions(prhs[0]) < 4 ||
        mxGetNumberOfDimensions(prhs[0]) > 5)
    {
        /* Only arg must be a real XxYxZx6xN array */
        printf("%d\n", mxGetNumberOfDimensions(prhs[0]));
        mexErrMsgTxt("Tensor data must be a real XxYxZx6xN array.");
    }
    /* Input matrix */
    const int *dimsPtr = mxGetDimensions(prhs[0]);
    int        nVox    = dimsPtr[0] * dimsPtr[1] * dimsPtr[2];
    double    *dtPtr   = mxGetPr(prhs[0]);
    int        nSub;

    /* Output matrices */
    int     vecDims[6];
    int     valDims[5];
    double *vecPtr;
    double *valPtr;

    /* Loop variables */
    int i, j, m;

    /* Double-check the input size */
    if (dimsPtr[3]!=6) {
        mexErrMsgTxt("Tensor data must be a real XxYxZx6xN array"
                        " (ie. 6 elements per voxel).");
    }

    /* Check number of subjects */
    if (mxGetNumberOfDimensions(prhs[0]) == 5) {
        nSub = dimsPtr[4];
    } else {
        nSub = 1;
    }
    
    /* Create the output arrays */
    vecDims[0] = (int)dimsPtr[0];   valDims[0] = (int)dimsPtr[0];
    vecDims[1] = (int)dimsPtr[1];   valDims[1] = (int)dimsPtr[1];
    vecDims[2] = (int)dimsPtr[2];   valDims[2] = (int)dimsPtr[2];
    vecDims[3] = 3;                 valDims[3] = 3;
    vecDims[4] = 3;                 valDims[4] = nSub;
    vecDims[5] = nSub;

    plhs[0] = mxCreateNumericArray(6, vecDims, mxDOUBLE_CLASS, mxREAL);
    plhs[1] = mxCreateNumericArray(5, valDims, mxDOUBLE_CLASS, mxREAL);

    vecPtr = mxGetPr(plhs[0]);
    valPtr = mxGetPr(plhs[1]);

    for (m = 0; m < nSub; m++) {
        for (i = 0; i < nVox; i++) {
            double A[3][3];
            double V[3][3];
            double d[3];
            A[0][0] = dtPtr[i + 0*nVox + 6*m*nVox];  /* A[0,0] = dtPtr[i,0] */
            A[1][1] = dtPtr[i + 1*nVox + 6*m*nVox];  /* A[1,1] = dtPtr[i,1] */
            A[2][2] = dtPtr[i + 2*nVox + 6*m*nVox];  /* A[2,2] = dtPtr[i,2] */
            A[0][1] = dtPtr[i + 3*nVox + 6*m*nVox];  /* A[0,1] = dtPtr[i,3] */
            A[1][0] = dtPtr[i + 3*nVox + 6*m*nVox];  /* A[1,0] = dtPtr[i,3] */
            A[0][2] = dtPtr[i + 4*nVox + 6*m*nVox];  /* A[0,2] = dtPtr[i,4] */
            A[2][0] = dtPtr[i + 4*nVox + 6*m*nVox];  /* A[2,0] = dtPtr[i,4] */
            A[1][2] = dtPtr[i + 5*nVox + 6*m*nVox];  /* A[1,2] = dtPtr[i,5] */
            A[2][1] = dtPtr[i + 5*nVox + 6*m*nVox];  /* A[2,1] = dtPtr[i,5] */

            eigen_decomposition(A, V, d);
    
            /* Assign outputs. */
            for(j = 0; j < 3; j++) {
                valPtr[i + j*nVox + 3*m*nVox] = d[j];
                vecPtr[i + (0 + j*3)*nVox + 9*m*nVox] = V[0][j];
                vecPtr[i + (1 + j*3)*nVox + 9*m*nVox] = V[1][j];
                vecPtr[i + (2 + j*3)*nVox + 9*m*nVox] = V[2][j];
            }
        }
    }
}

/* Eigen decomposition code for symmetric 3x3 matrices, copied from the public
   domain Java Matrix library JAMA. */

static double hypot2(double x, double y) {
  return sqrt(x*x+y*y);
}

/* Symmetric Householder reduction to tridiagonal form. */

static void tred2(double V[n][n], double d[n], double e[n]) {

/*  This is derived from the Algol procedures tred2 by
    Bowdler, Martin, Reinsch, and Wilkinson, Handbook for
    Auto. Comp., Vol.ii-Linear Algebra, and the corresponding
    Fortran subroutine in EISPACK. */
  int j,i,k;
  for (j = 0; j < n; j++) {
    d[j] = V[n-1][j];
  }

  /* Householder reduction to tridiagonal form. */

  for (i = n-1; i > 0; i--) {

    /* Scale to avoid under/overflow. */

    double scale = 0.0;
    double h = 0.0;
    for (k = 0; k < i; k++) {
      scale = scale + fabs(d[k]);
    }
    if (scale == 0.0) {
      e[i] = d[i-1];
      for (j = 0; j < i; j++) {
        d[j] = V[i-1][j];
        V[i][j] = 0.0;
        V[j][i] = 0.0;
      }
    } else {

      /* Generate Householder vector. */

      for (k = 0; k < i; k++) {
        d[k] /= scale;
        h += d[k] * d[k];
      }
      double f = d[i-1];
      double g = sqrt(h);
      if (f > 0) {
        g = -g;
      }
      e[i] = scale * g;
      h = h - f * g;
      d[i-1] = f - g;
      for (j = 0; j < i; j++) {
        e[j] = 0.0;
      }

      /* Apply similarity transformation to remaining columns. */

      for (j = 0; j < i; j++) {
        f = d[j];
        V[j][i] = f;
        g = e[j] + V[j][j] * f;
        for (k = j+1; k <= i-1; k++) {
          g += V[k][j] * d[k];
          e[k] += V[k][j] * f;
        }
        e[j] = g;
      }
      f = 0.0;
      for (j = 0; j < i; j++) {
        e[j] /= h;
        f += e[j] * d[j];
      }
      double hh = f / (h + h);
      for (j = 0; j < i; j++) {
        e[j] -= hh * d[j];
      }
      for (j = 0; j < i; j++) {
        f = d[j];
        g = e[j];
        for (k = j; k <= i-1; k++) {
          V[k][j] -= (f * e[k] + g * d[k]);
        }
        d[j] = V[i-1][j];
        V[i][j] = 0.0;
      }
    }
    d[i] = h;
  }

  /* Accumulate transformations. */

  for (i = 0; i < n-1; i++) {
    V[n-1][i] = V[i][i];
    V[i][i] = 1.0;
    double h = d[i+1];
    if (h != 0.0) {
      for (k = 0; k <= i; k++) {
        d[k] = V[k][i+1] / h;
      }
      for (j = 0; j <= i; j++) {
        double g = 0.0;
        for (k = 0; k <= i; k++) {
          g += V[k][i+1] * V[k][j];
        }
        for (k = 0; k <= i; k++) {
          V[k][j] -= g * d[k];
        }
      }
    }
    for (k = 0; k <= i; k++) {
      V[k][i+1] = 0.0;
    }
  }
  for (j = 0; j < n; j++) {
    d[j] = V[n-1][j];
    V[n-1][j] = 0.0;
  }
  V[n-1][n-1] = 1.0;
  e[0] = 0.0;
} 

/* Symmetric tridiagonal QL algorithm. */

static void tql2(double V[n][n], double d[n], double e[n]) {

/*  This is derived from the Algol procedures tql2, by
    Bowdler, Martin, Reinsch, and Wilkinson, Handbook for
    Auto. Comp., Vol.ii-Linear Algebra, and the corresponding
    Fortran subroutine in EISPACK. */
  int i,j,k,l;
  for (i = 1; i < n; i++) {
    e[i-1] = e[i];
  }
  e[n-1] = 0.0;

  double f = 0.0;
  double tst1 = 0.0;
  double eps = pow(2.0,-52.0);
  for (l = 0; l < n; l++) {

    /* Find small subdiagonal element */

    tst1 = MAX(tst1,fabs(d[l]) + fabs(e[l]));
    int m = l;
    while (m < n) {
      if (fabs(e[m]) <= eps*tst1) {
        break;
      }
      m++;
    }

    /* If m == l, d[l] is an eigenvalue,
       otherwise, iterate. */

    if (m > l) {
      int iter = 0;
      do {
        iter = iter + 1;  /* (Could check iteration count here.) */

        /* Compute implicit shift */

        double g = d[l];
        double p = (d[l+1] - g) / (2.0 * e[l]);
        double r = hypot2(p,1.0);
        if (p < 0) {
          r = -r;
        }
        d[l] = e[l] / (p + r);
        d[l+1] = e[l] * (p + r);
        double dl1 = d[l+1];
        double h = g - d[l];
        for (i = l+2; i < n; i++) {
          d[i] -= h;
        }
        f = f + h;

        /* Implicit QL transformation. */

        p = d[m];
        double c = 1.0;
        double c2 = c;
        double c3 = c;
        double el1 = e[l+1];
        double s = 0.0;
        double s2 = 0.0;
        for (i = m-1; i >= l; i--) {
          c3 = c2;
          c2 = c;
          s2 = s;
          g = c * e[i];
          h = c * p;
          r = hypot2(p,e[i]);
          e[i+1] = s * r;
          s = e[i] / r;
          c = p / r;
          p = c * d[i] - s * g;
          d[i+1] = h + s * (c * g + s * d[i]);

          /* Accumulate transformation. */

          for (k = 0; k < n; k++) {
            h = V[k][i+1];
            V[k][i+1] = s * V[k][i] + c * h;
            V[k][i] = c * V[k][i] - s * h;
          }
        }
        p = -s * s2 * c3 * el1 * e[l] / dl1;
        e[l] = s * p;
        d[l] = c * p;

        /* Check for convergence. */

      } while (fabs(e[l]) > eps*tst1);
    }
    d[l] = d[l] + f;
    e[l] = 0.0;
  }
  
  /* Sort eigenvalues and corresponding vectors. */
/* *** WORK HERE *** change sort to go in descending order */ 

  for (i = 0; i < n-1; i++) {
    k = i;
    double p = d[i];
    for (j = i+1; j < n; j++) {
      if (d[j] > p) {
        k = j;
        p = d[j];
      }
    }
    if (k != i) {
      d[k] = d[i];
      d[i] = p;
      for (j = 0; j < n; j++) {
        p = V[j][i];
        V[j][i] = V[j][k];
        V[j][k] = p;
      }
    }
  }
}

void eigen_decomposition(double A[n][n], double V[n][n], double d[n]) {
  double e[n];
  int i,j;
  for (i = 0; i < n; i++) {
    for (j = 0; j < n; j++) {
      V[i][j] = A[i][j];
    }
  }
  tred2(V, d, e);
  tql2(V, d, e);
}
