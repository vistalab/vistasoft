/* ndfun.c: MEX (MATLAB) file to implement functions that treat
   multi-dimensional arrays as "pages" of 2D matrices.
   
   This allows you do to, for example, 
     C = ndfun('mult', A, B),
   which is equivalent to
     for i = 1:100
       C(:,:,i) = A(:,:,i) * B(:,:,i);
     end

   except it is more flexible, since it does the same for any number
   of dimensions.

   It also automatically reuses 2D matrices in either position, as in:
     for i = 1:100
       C(:,:,i) = A * B(:,:,i);
     end

   Supported operations are now multiplication, inverses, square
   matrix backslash, eigenvectors/values, and 'mprod', which
   cumulatively multiplies all 2D matrices.

   Debating including a "fast" option that skips the singularity
   check.  For 100x100 inverse, this would save 15%.  Opinions?


   TO COMPILE:  This file makes extensive use of BLAS and LAPACK functions.
   "New" versions of MATLAB require the explicit linking of the library that
   supports those functions, on both Windows and UNIX.  On Linux, my command
   line is: 
  
      mex -v -largeArrayDims ndfun.c -lmwlapack -lmwblas
 
 *
 * On Windows/XP (SP2) for a 32 bit with Matlab R2008a, Wandell compiled using
 *   mex ndfun.c <root>\libmwlapack.lib <root>\libmwblas.lib
 * There may be a way to always have mex include these ... not sure.
    "C:\Program Files\MATLAB\R2008a\extern\lib\win32\microsoft\libmwlapack.lib" 
    "C:\Program Files\MATLAB\R2008a\extern\lib\win32\microsoft\libmwblas.lib" 
 *
   Author: Peter Boettcher <boettcher@ll.mit.edu>
   Copyright 2002, Peter Boettcher
*/

/* $Log: ndfun.c,v $
/* Revision 1.3  2008/01/24 22:54:21  bob
/* none
/*
/* Revision 1.2  2007-11-10 02:18:40  bob
/* many little changes; adding tensor-based anisotropic smoothing (needs testing)
/*
 * Revision 1.13  2007/11/01 14:51:45  pe17029
 * Added quick compilation instructions
 *
 * Revision 1.12  2007/11/01 14:43:15  pe17029
 * Fixed crash bug in backslash for small matrices.
 *
 * Revision 1.11  2005/07/22 17:08:08  pwb
 * Added complex numbers for mprod
 *
 * Revision 1.10  2005/07/21 13:22:59  pwb
 * Modifed mprod to collapse only dimension 3, and leave the others
 * intact
 *
 * Revision 1.9  2005/07/19 15:04:07  pwb
 * Added mprod command
 * Disallowed complex inputs
 *
 * Revision 1.8  2002/11/25 19:30:39  pwb
 * Added eigenvalue/vector support
 *
 * Revision 1.7  2002/11/19 13:59:03  pwb
 * Added _MSC_VER to list of symbols which identify compilers that don't
 * add underbars to BLAS functions
 *
 * 2010.10.01 RFD: replaced int with mwSignedIndex to conform the the new BLAS/LAPACK API.
 *
 * */


/* 	$Id: ndfun.c,v 1.3 2008/01/24 22:54:21 bob Exp $	 */

#ifndef lint
static char vcid[] = "$Id: ndfun.c,v 1.3 2008/01/24 22:54:21 bob Exp $";
#endif /* lint */

#include "mex.h"
#include <string.h>
#include <math.h>

double compute_norm(double *A, mwSignedIndex m, mwSignedIndex n);
void compute_lu(double *X, mwSignedIndex m, mwSignedIndex *ipivot, double *work, mwSignedIndex *iwork, mwSignedIndex check_singular);
void blas_return_check(mwSignedIndex info, const char *blasfcn);

/* Declare BLAS/LAPACK externs 
 *
 * When calling an LAPACK or BLAS function, some platforms require an 
 * underscore following the function name in the call statement.
 *
 * See Matworks example matrixDivide.cpp
 */
#if !defined(_WIN32)
#define dgemm dgemm_
#define zgemm zgemm_
#define dgetrs dgetrs_
#define dgetri dgetri_
#define dgetrf dgetrf_
#define dgecon dgecon_
#define dgeev dgeev_
#endif

/* Typedefs */
typedef enum {COMMAND_INVALID=0, COMMAND_MULT, COMMAND_INV, 
			  COMMAND_BACKSLASH, COMMAND_VERSION, COMMAND_EIG, COMMAND_MPROD} commandcode_t;

#define CHECK_SQUARE_A 1
#define CHECK_SQUARE_B 2
#define CHECK_AT_LEAST_2D_A 4
#define CHECK_AT_LEAST_2D_B 8
#define ALLOW_COMPLEX_A 16
#define ALLOW_COMPLEX_B 32

struct ndcommand_s {
  char *cmdstr;
  commandcode_t commandcode;
  int num_args;
  int check;
} ndcommand_list[] = {{"mult", COMMAND_MULT, 2, 0},
					  {"inv", COMMAND_INV, 1, CHECK_SQUARE_A | CHECK_AT_LEAST_2D_A},
					  {"backslash", COMMAND_BACKSLASH, 2, CHECK_SQUARE_A | CHECK_AT_LEAST_2D_A},
					  {"version", COMMAND_VERSION, 0, 0},
					  {"eig", COMMAND_EIG, 1, CHECK_SQUARE_A},
					  {"mprod", COMMAND_MPROD, 1, CHECK_SQUARE_A | ALLOW_COMPLEX_A},
					  {NULL, COMMAND_INVALID, 0}};

double eps;

struct ndcommand_s *get_command(const mxArray *mxCMD)
{
  char *commandstr;
  mwSignedIndex i=0;

  if(mxGetClassID(mxCMD) != mxCHAR_CLASS)
    mexErrMsgTxt("First argument must be the command to use");
  commandstr = mxArrayToString(mxCMD);
  
  while(ndcommand_list[i].cmdstr) {
    if (strcmp(commandstr, ndcommand_list[i].cmdstr) == 0) {
      mxFree(commandstr);
      return(&ndcommand_list[i]);
    }
    i++;
  }

  mxFree(commandstr);
  mexErrMsgTxt("Unknown command");

  return(NULL);
}

int page_dim_check(mwSignedIndex numDimsA, mwSignedIndex numDimsB, const mwSignedIndex *dimsA, const mwSignedIndex *dimsB, 
				   const mxArray *mxA, const mxArray *mxB, mwSignedIndex dimcheck)
{
  mwSignedIndex i, numPages=1;
 
  /* OK, valid possibilities are: 
     -Fully matching N-D arrays
     -One 2D (or less) array and one arbitrary N-D array */

  if((numDimsA <= 2) || (numDimsB <= 2)) {
    /* repeated_arg = 1; */
  } else {
    if(numDimsA != numDimsB)
      mexErrMsgTxt("Invalid dimensions");
    for(i=2; i<numDimsA; i++) {
      if(dimsA[i] != dimsB[i])
	mexErrMsgTxt("Dimensions after 2 must match");
      numPages *= dimsA[i];
    }
  }     

  if(dimcheck & CHECK_AT_LEAST_2D_A) {
    if(numDimsA < 2)
      mexErrMsgTxt("A must be at least 2D!");
  }
  if(dimcheck & CHECK_AT_LEAST_2D_B) {
    if(numDimsB < 2)
      mexErrMsgTxt("B must be at least 2D!");
  }
     
  if(dimcheck & CHECK_SQUARE_A) {
	  if(dimsA[0] != dimsA[1])
		  mexErrMsgTxt("A must be square in first 2 dimensions");
  }
  if(dimcheck & CHECK_SQUARE_B) {
    if(dimsB[0] != dimsB[1])
      mexErrMsgTxt("A must be square in first 2 dimensions");
  }

  if(!(dimcheck & ALLOW_COMPLEX_A))
	  if(mxIsComplex(mxA))
		  mexErrMsgTxt("Complex arguments not yet supported");

  if(!(dimcheck & ALLOW_COMPLEX_B))
	  if(mxB && mxIsComplex(mxB))
		  mexErrMsgTxt("Complex arguments not yet supported");

  return(0);
}
    


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  const mwSignedIndex *dimsA=NULL, *dimsB=NULL, *dimsptr;
  mwSignedIndex *dimsC;
  mwSignedIndex numDimsA=0, numDimsB=0, numDimsC=0;
  mwSignedIndex numElA, numElB=1;
  mwSignedIndex m=0, n=0, p=0, i;
  double *A, *B, *C, one = 1.0, zero = 0.0;
  mwSignedIndex numPages=1;
  mwSignedIndex strideA, strideB, strideC;
  struct ndcommand_s *command;
  const mxArray *mxA=NULL, *mxB=NULL;
  mwSignedIndex *ipivot, info, *iwork;
  double *work, *scratchA;
  mxArray *tmp;
  double *T;

  eps = mxGetEps();

  if(nrhs < 1)
    mexErrMsgTxt("Not enough arguments");

  /* Figure which command was chosen */
  command = get_command(prhs[0]);

  /* Set up some variables for the 2 and 1 argument cases */
  if(command->num_args == 2) {
    if(nrhs != 3)
      mexErrMsgTxt("Two arguments required");


    mxA = prhs[1];
    mxB = prhs[2];


    numElA = mxGetNumberOfElements(mxA);
    numDimsA = mxGetNumberOfDimensions(mxA);
    dimsA = mxGetDimensions(mxA);

    numElB = mxGetNumberOfElements(mxB);
    numDimsB = mxGetNumberOfDimensions(mxB);
    dimsB = mxGetDimensions(mxB);
  } else if(command->num_args == 1) {
    if(nrhs != 2)
      mexErrMsgTxt("One argument required");

    mxA = prhs[1];
	mxB = NULL;

    numElA = mxGetNumberOfElements(mxA);
    numDimsA = mxGetNumberOfDimensions(mxA);
    dimsA = mxGetDimensions(mxA);
  }

  if((numElA == 0) || (numElB == 0)) {
      plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
      return;
  }

  /* Be sure dimensions agree in the necessary ways.  check is a
     bitmask of "necessary" checks to perform, which depends on the
     command chosen */
  page_dim_check(numDimsA, numDimsB, dimsA, dimsB, mxA, mxB, command->check);

  switch(command->commandcode) {
  case COMMAND_VERSION:
    mexPrintf("NDFUN MEX file\nCopyright 2002 Peter Boettcher\n%s\n", 
	      "$Revision: 1.3 $");
    break;
  case COMMAND_MULT:
    /******************************************
     * MULTIPLY
     ******************************************/

    if(dimsA[1] != dimsB[0])
      mexErrMsgTxt("Inner dimensions (first 2) don't match");
   
    m = dimsA[0];
    n = dimsB[1];
    p = dimsA[1];
    strideC = m*n;

    strideA = m*p;
    strideB = p*n;
    dimsptr = dimsA;
    numDimsC = numDimsA;

    if(numDimsA != numDimsB) {
      if(numDimsA < numDimsB) {
	strideA = 0;
	numDimsC = numDimsB;
	dimsptr = dimsB;
      } else {
	strideB = 0;
      }
    }

    for(i=2; i<numDimsC; i++)
      numPages *= dimsptr[i];

    dimsC = (mwSignedIndex *)mxMalloc(numDimsC*sizeof(mwSignedIndex));
    dimsC[0] = m;
    dimsC[1] = n;
    for(i=2; i<numDimsC; i++)
      dimsC[i] = dimsptr[i];
    
    plhs[0] = mxCreateNumericArray(numDimsC, dimsC, mxDOUBLE_CLASS, mxREAL);
    C = mxGetPr(plhs[0]);
    A = mxGetPr(mxA);
    B = mxGetPr(mxB);
    
    for(i=0; i<numPages; i++) {
      dgemm("N", "N", &m, &n, &p, &one, A + i*strideA, &m, B + i*strideB, 
		      &p, &zero, C + i*strideC, &m);
    }
  
    mxFree(dimsC);
    break;

  case COMMAND_MPROD: {
	  /******************************************
	   * MPROD
	   ******************************************/
	  double *tptr, *dst, *src;   
	  int complexFlag;
	  mwSignedIndex msize;
	  double cone[2], czero[2];

	  m = dimsA[0];
	  strideA = m*m;
	  dimsptr = dimsA;

	  czero[0] = czero[1] = 0.0;
	  cone[0] = 1.0; cone[1] = 0.0;

	  complexFlag = mxIsComplex(mxA);

	  if(numDimsA > 2) {
		  n = dimsptr[2];
		  if(numDimsA > 3) {
			  for(i=3; i<numDimsA; i++)
				  numPages *= dimsptr[i];
		  } else {
			  numPages = 1;
		  }
		  numDimsC = numDimsA - 1;
	  } else {
		  n = 1; /* Return myself if only 2D */
		  numDimsC = 2;
	  }


	  dimsC = (mwSignedIndex *)mxMalloc(numDimsC*sizeof(mwSignedIndex));
	  dimsC[0] = m;
	  dimsC[1] = m;

	  for(i=2; i<numDimsC; i++) {
		  dimsC[i] = dimsptr[i+1];
	  }

	  strideC = m*m;


	  if(complexFlag) {
		  double *Ar, *Ai;

		  Ar = mxGetPr(mxA);
		  Ai = mxGetPi(mxA);
		  A = mxCalloc(m*m*n*numPages * 2, sizeof(double));
		  for(i=0; i<m*m*n*numPages; i++) {
			  A[2*i] = Ar[i];
			  A[2*i+1] = Ai[i];
		  }

		  strideA *= 2;

		  plhs[0] = mxCreateNumericArray(numDimsC, dimsC, mxDOUBLE_CLASS, mxCOMPLEX);
		  C = mxCalloc(m*m*numPages*2, sizeof(double));
		  T = mxCalloc(m*m*2, sizeof(double));
		  strideC *= 2;
		  msize = m*m*sizeof(double)*2;

	  } else {
		  A = mxGetPr(mxA);

		  plhs[0] = mxCreateNumericArray(numDimsC, dimsC, mxDOUBLE_CLASS, mxREAL);
		  C = mxGetPr(plhs[0]);
		  T = mxCalloc(m*m, sizeof(double));
		  msize = m*m*sizeof(double);
	  }


	  for(p=0; p<numPages; p++) {
		  memcpy(T, A + p*n*strideA, msize);
	  
		  src = C + p*strideC; /* will be swapped before using */
		  dst = T;

		  /* Bounce back and forth between temp space and destination */
		  for(i=1; i<n; i++) {
			  tptr = src;
			  src = dst;
			  dst = tptr;
			  
			  if(!complexFlag) {
				  dgemm("N", "N", &m, &m, &m, &one, src, &m, A + (p*n + i)*strideA, 
								  &m, &zero, dst, &m);
			  } else {
				  zgemm("N", "N", &m, &m, &m, &cone, src, &m, A + (p*n + i)*strideA, 
								  &m, &czero, dst, &m);
			  }
		  }
		  
		  /* If we ended in the temp space, copy to the destination */
		  if(dst != C + p*strideC)
			  memcpy(C + p*strideC, T, msize);
	  }

	  if(complexFlag) {
		  double *Cr, *Ci;

		  Cr = mxGetPr(plhs[0]);
		  Ci = mxGetPi(plhs[0]);
		  for(i=0; i<m*m*numPages; i++) {
			  Cr[i] = C[2*i];
			  Ci[i] = C[2*i+1];
		  }
		  mxFree(C);
		  mxFree(A);
	  }
	  mxFree(T);
	  mxFree(dimsC);

  }
	  break;

  case COMMAND_BACKSLASH:
    /******************************************
     * BACKSLASH
     ******************************************/

    if(dimsA[0] != dimsB[0])
      mexErrMsgTxt("First dimensions must match");
    
    m = dimsA[0];
    n = dimsA[1];
    p = dimsB[1];
    
    strideC = n*p;
    strideA = m*n;
    strideB = m*p;
    dimsptr = dimsA;
    numDimsC = numDimsA;

    if(numDimsA != numDimsB) {
      if(numDimsA < numDimsB) {
	strideA = 0;
	numDimsC = numDimsB;
	dimsptr = dimsB;
      } else {
	strideB = 0;
      }
    }
    for(i=2; i<numDimsC; i++)
      numPages *= dimsptr[i];
    dimsC = (mwSignedIndex *)mxMalloc(numDimsC*sizeof(mwSignedIndex));
    dimsC[0] = n;
    dimsC[1] = p;
    for(i=2; i<numDimsC; i++)
      dimsC[i] = dimsptr[i];
    
    plhs[0] = mxCreateNumericArray(numDimsC, dimsC, mxDOUBLE_CLASS, mxREAL);

    C = mxGetPr(plhs[0]);
    A = mxGetPr(mxA);
    B = mxGetPr(mxB);
  
    ipivot = (mwSignedIndex *)mxMalloc(m*sizeof(mwSignedIndex));
    iwork = (mwSignedIndex *)mxMalloc(m*sizeof(mwSignedIndex));
    work = (double *)mxMalloc(4*m*sizeof(double));
    scratchA = (double *)mxMalloc(m*n*sizeof(double));


    if(numDimsA < numDimsB) {
      /* Single A, multiple B.  That means do one LU on A, and multiple solves */
      /* Save memory by doing it this way... that way we need only a m*n temp array */
      memcpy(scratchA, A, mxGetNumberOfElements(mxA)*sizeof(double));
      memcpy(C, B, m*p*numPages*sizeof(double));
      compute_lu(scratchA, m, ipivot, work, iwork, 1);

      /* Loop over pages of B and compute */
      for(i=0; i<numPages; i++) {
	dgetrs("N", &m, &p, scratchA, &m, ipivot, C + i*strideC, &m, &info);
	blas_return_check(info, "DGETRS");
      }
    } else {
      /* Multiple A.  Do the LU each step through */
      for(i=0; i<numPages; i++) {
	memcpy(scratchA, A + i*strideA, m*n*sizeof(double));
	compute_lu(scratchA, m, ipivot, work, iwork, 1);

	/* Compute */
	memcpy(C+i*strideC, B+i*strideB, m*p*sizeof(double));
	dgetrs("N", &m, &p, scratchA, &m, ipivot, C + i*strideC, &m, &info);
	blas_return_check(info, "DGETRS");	
      }
    }
    
    mxFree(iwork);
    mxFree(scratchA);
    mxFree(dimsC);
    mxFree(ipivot);
    mxFree(work);
    break;
  case COMMAND_INV:
    /******************************************
     * INVERSE
     ******************************************/
    m = dimsA[0];
    n = dimsA[1];

    ipivot = (mwSignedIndex *)mxMalloc(m*sizeof(mwSignedIndex));
    work = (double *)mxMalloc(m*m*sizeof(double));
    iwork = (mwSignedIndex *)mxMalloc(m*sizeof(mwSignedIndex));

    plhs[0] = mxDuplicateArray(mxA);
    C = mxGetPr(plhs[0]);
    strideC = n*m;

    for(i=2; i<numDimsA; i++)
      numPages *= dimsA[i];

    for(i=0; i<numPages; i++) {
	if(m*n == 1)
	    *(C + i*strideC) = 1 / *(C + i*strideC);
	else {
	    compute_lu(C + i*strideC, m, ipivot, work, iwork, 1);
	
	    dgetri(&n, C + i*strideC, &m, ipivot, work, &n, &info );
	    blas_return_check(info, "DGETRI");
	}
      /*      if(info>0) mexWarnMsgTxt("Matrix is singular to working precision"); */
    }
    
    mxFree(ipivot);
    mxFree(work);
    mxFree(iwork);
    break;
  case COMMAND_EIG: {
      mwSignedIndex zero=0;
      mwSignedIndex one=1;
      mwSignedIndex lwork;
      double *outeigsR;
      double *outeigsI;
      mwSignedIndex strideOut;
      double *vl, *vr;
      double *eigvR, *eigvI;
      double *input;
      mwSignedIndex inputstride;
      mwSignedIndex numel;
      char jobvr;
      mwSignedIndex j, k;
      mwSignedIndex haveComplex=0;

      /******************************************
       * EIGENVALUE
       ******************************************/
      m = dimsA[0];
      n = dimsA[1];
      numel = mxGetNumberOfElements(mxA);
      
      lwork = 6*m;
      work = (double *)mxMalloc(lwork*sizeof(double));
 
      input = (double *)mxMalloc(numel*sizeof(double));
      memcpy(input, mxGetPr(mxA), numel*sizeof(double));
      inputstride = n*m;

      dimsC = (mwSignedIndex *)mxMalloc(numDimsA*sizeof(mwSignedIndex));
      dimsC[0] = m;
      dimsC[1] = 1;
      for(i=2; i<numDimsA; i++)
	  dimsC[i] = dimsA[i];
 

      if(nlhs > 1) {
	  /* Return eigenvectors and diagonal eigenvalue matrix */
	  dimsC[1] = m;

	  plhs[1] = mxCreateNumericArray(numDimsA, dimsC, mxDOUBLE_CLASS, mxCOMPLEX);
	  outeigsR = mxGetPr(plhs[1]);
	  outeigsI = mxGetPi(plhs[1]);
	  strideOut = m*m;

	  plhs[0] = mxCreateNumericArray(numDimsA, dimsC, mxDOUBLE_CLASS, mxCOMPLEX);
	  eigvR = mxGetPr(plhs[0]);
	  eigvI = mxGetPi(plhs[0]);
	  jobvr = 'V';

	  vl = (double *)mxMalloc(m*m*sizeof(double));
	  vr = (double *)mxMalloc(m*m*sizeof(double));
      } else {
	  /* Just the eigenvalues */
	  plhs[0] = mxCreateNumericArray(numDimsA, dimsC, mxDOUBLE_CLASS, mxCOMPLEX);
	  outeigsR = mxGetPr(plhs[0]);
	  outeigsI = mxGetPi(plhs[0]);
	  strideOut = m;
	  jobvr = 'N';

	  vl = NULL;
	  vr = NULL;
      }

      for(i=2; i<numDimsA; i++)
	  numPages *= dimsA[i];

      if(m==0) numPages = 0;

      for(i=0; i<numPages; i++) {
	  dgeev("N", &jobvr, &m, input + i*inputstride, &m, outeigsR + i*strideOut,
			  outeigsI + i*strideOut, vl, &m, vr, &m, work, &lwork, &info);

	  blas_return_check(info, "DGEEV");

	  if(nlhs>1) {
	      memcpy(eigvR + i*m*m, vr, m*m*sizeof(double));

	      for(j=0; j<m; j++) {
		  /* If this eigenvalue is complex, the next is it's
		     complex conjugate, and we have to sort out the
		     corresponding eigenvectors */
		  if(*(outeigsI + i*strideOut + j) > 0.0) {
		      haveComplex=1;
		      for(k=0; k<m; k++) {
			  *(eigvR + i*m*m + (j+1)*m + k) = vr[j*m + k];
			  *(eigvI + i*m*m + j*m + k) = vr[(j+1)*m + k];
			  *(eigvI + i*m*m + (j+1)*m + k) = -vr[(j+1)*m + k];
		      }
		      j++;
		  } 
	      }
	      
	      /* We also need to spread the eigenvectors into the diagonal */
	      for(j=1; j<m; j++) {
		  *(outeigsR + i*strideOut + j*m + j) = *(outeigsR + i*strideOut + j);
		  *(outeigsR + i*strideOut + j) = 0;
		  *(outeigsI + i*strideOut + j*m + j) = *(outeigsI + i*strideOut + j);
		  *(outeigsI + i*strideOut + j) = 0;
	      }
	  }
      }

      mxFree(input);
      mxFree(dimsC);
      mxFree(work);
      if(vl) mxFree(vl);
      if(vr) mxFree(vr);
      break;
  }
  default:
    mexErrMsgTxt("Should never get here");
  }

}

/* Wrapper function for LU decomposition.  Optionally checks
   singularity of result.  For efficiency, pass in the scratch
   buffers.  Result appears in-place.  See BLAS docs on DGETRF and
   DGECON for required scratch buffer sizes.  */
void compute_lu(double *X, mwSignedIndex m, mwSignedIndex *ipivot, double *work, mwSignedIndex *iwork, mwSignedIndex check_singular)
{
  double anorm, rcond;
  mwSignedIndex info;
  char errmsg[255];
  
  anorm = compute_norm(X, m, m);
  dgetrf(&m, &m, X, &m, ipivot, &info); /* LU call */
  blas_return_check(info, "DGETRF");
  
  if(check_singular) {
    /* Check singularity */
    if(info>0)
      mexWarnMsgTxt("Matrix is singular to working precision");
    else {
      dgecon("1", &m, X, &m, &anorm, &rcond, work, iwork, &info);
      blas_return_check(info, "DGECON");
      
      if(rcond < eps) {
	sprintf(errmsg, "%s\n         %s RCOND = %e.",
		"Matrix is close to singular or badly scaled.",
		"Results may be inaccurate.", rcond);
	mexWarnMsgTxt(errmsg);
      }
    }
  }

} 

/* Check the INFO parameter of a BLAS call and error with a useful message if negative */
void blas_return_check(mwSignedIndex info, const char *blasfcn)
{
  char errmsg[255];

  if(info < 0) {
    sprintf(errmsg, "Internal error: Illegal %s call, problem in arg %i", blasfcn, 
	    abs(info));
    mexErrMsgTxt(errmsg);
  }
}

double compute_norm(double *A, mwSignedIndex m, mwSignedIndex n)
{
  mwSignedIndex i, j;
  double sum;
  double curmax = 0.0;

  for(j=0; j<n; j++) {
    sum = 0;
    for(i=0; i<m; i++) {
      sum += fabs(A[m*j + i]);
    }
    if(sum > curmax)
      curmax = sum;
  }
  return(curmax);
}
