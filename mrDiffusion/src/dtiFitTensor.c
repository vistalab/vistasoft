/* C-Mex implementation for tensor fitting
 *
 * On Microsoft Windows, you have to append one of the following filenames to
 * the command line, where <root> is what you get when you call matlabroot:
 *  - lcc compiler: <root>\extern\lib\win32\lcc\libmwlapack.lib
 *  - Visual C++:   <root>\extern\lib\win32\microsoft\msvc60\libmwlapack.lib
 *
 * To compile under linux:
 *    mex -v -largeArrayDims dtiFitTensor.c -lmwlapack
 *
 * On Microsoft Windows, you have to link to the libraries in matlabroot/extern/lib/win32/microsoft/. 
 *    lapacklib = fullfile(matlabroot, 'extern', 'lib', 'win32', 'microsoft', 'libmwlapack.lib');
 *    blaslib = fullfile(matlabroot, 'extern', 'lib', 'win32', 'microsoft', 'libmwblas.lib');
 *    mex('-v', '-largeArrayDims', 'matrixMultiply.c', blaslib)
 *
 * TEST CODE:

 bn = '/biac3/wandell4/data/reading_longitude/dti_y4/mho070519/raw/rawDti_g13_b800_aligned';

 bn = '/biac3/wandell4/data/reading_longitude/dti_y1/ar040522/raw/rawDti';

 dwRaw = niftiRead([bn '.nii.gz']);
 sz = size(dwRaw.data);
 d = double(dwRaw.data);
 bvecs = dlmread([bn '.bvec']);
 bvals = dlmread([bn '.bval']);
 tau = 40;
 q = [bvecs.*sqrt(repmat(bvals./tau,3,1))]';
 X = [ones(size(q,1),1) -tau.*q(:,1).^2 -tau.*q(:,2).^2 -tau.*q(:,3).^2 -2*tau.*q(:,1).*q(:,2) -2*tau.*q(:,1).*q(:,3) -2*tau.*q(:,2).*q(:,3)];
 tic; [dt,pdd] = dtiFitTensor(d,X); toc;
 makeMontage3(abs(pdd));

 % Try using a mask:
 mnB0 = mean(d(:,:,:,bvals==0),4);
 % Tidy up the data a bit- replace any dw value > the mean b0 with the mean b0.
 % Such data must be artifacts and fixing them reduces the # of non P-D tensors.
 for(ii=find(bvals>0)) tmp=d(:,:,:,ii); bv=tmp>mnB0; tmp(bv)=mnB0(bv); d(:,:,:,ii)=tmp; end 
 mask = uint8(dtiCleanImageMask(mrAnatHistogramClip(mnB0,0.4,0.99)>0.3));
 tic;[dt,pdd] = dtiFitTensor(d,X,0,[],mask); toc
 makeMontage3(abs(pdd));

 % Add some permutations (Repetition)
 pm = dtiBootGetPermMatrix(dlmread([bn '.bvecs']), dlmread([bn '.bvals']));
 permutations = dtiBootGetPermutations(pm, 500, 1);
 tic;[dt,pdd,mdStd,faStd,pddDisp] = dtiFitTensor(d,X,1,permutations,mask); toc
 b0=exp(dt(:,:,:,1)); b0=mrAnatHistogramClip(b0,0.4,0.99);
 showMontage(b0);
 [fa,md] = dtiComputeFA(dt(:,:,:,2:7));
 md(md>5) = 5; md(md<0) = 0;
 showMontage(fa);
 showMontage(md);
 showMontage(faStd);
 mdStd(mdStd>0.3)=0.3;
 showMontage(mdStd);
 showMontage(pddDisp/pi*180);
 inds = find(mask);
 figure;scatter(fa(inds),pddDisp(inds)/pi*180,1);
 xlabel('FA'); ylabel('PDD dispersion (deg)');

% Add some permutations (Residual)
 permutations = dtiBootGetPermutations(length(bvals),300,0);
 tic;[dt,pdd,mdStd,faStd,pddDisp] = dtiFitTensor(d,X,0,permutations,mask); toc
 b0=exp(dt(:,:,:,1)); b0=mrAnatHistogramClip(b0,0.4,0.99);
 showMontage(b0);
 [fa,md] = dtiComputeFA(dt(:,:,:,2:7));
 md(md>5) = 5; md(md<0) = 0;
 showMontage(fa);
 showMontage(md);
 showMontage(faStd);
 mdStd(mdStd>0.3)=0.3;
 showMontage(mdStd);
 showMontage(pddDisp/pi*180);
 inds = find(mask);
 figure;scatter(fa(inds),pddDisp(inds)/pi*180,1);
 xlabel('FA'); ylabel('PDD dispersion (deg)');

 *
 
 HISTORY:
 2010.09.30 RFD: Updated code to use new matlab LAPAK standards. Most importantly, 
 Matlab now requires all the int inputs to LAPK functions to be of type mwSignedIndex.
 */


/* Declare LAPACK externs 
 *
 * When calling an LAPACK or BLAS function, some platforms require an 
 * underscore following the function name in the call statement.
 *
 * See Matworks example matrixDivide.cpp
 */
#if !defined(_WIN32)
#define dgesv dgesv_
#define dsyev dsyev_
#define dgelss dgelss_
#endif

/* 
void DSYEV(const char *JOBZ, const char *UPLO, const int *N, double *A,
           const int *LDA, double *W, double *WORK, const int *LWORK,
           int *INFO);
void DGELSS(int *m, int *n, int *nrhs, double *a, int *lda,
			double *b, int *ldb, double *s, double *rcond, int *rank,
            double *work, int *lwork, int *info);
*/

#include "mex.h"
#include "string.h"
#include "lapack.h"
#include "stdlib.h"
#include "matrix.h"
#include "math.h"

#define MAX(m, n) (m) < (n) ? (n) : (m)
#define MIN(m, n) (m) < (n) ? (m) : (n)
#define SQUARE(x) ((x)*(x))

#ifndef ROUND
#define  ROUND(f)   ((f>=0)?(int)(f + .5):(int)(f - .5)) 
#endif


/*
 * Simple wrapper for memory allocation.
 */
void *myMalloc(int nbytes){
  void *ptr = mxMalloc(nbytes);
  if(ptr==NULL && nbytes>0) 
	mexErrMsgTxt("Out of memory!");
  return ptr;
}

/* 
 *   PSEUDO-INVERSE
 *
 *   Uses LAPACK's "dgelss" to find the pseudoinverse of a rectangular matrix. 
 *
 *   Usage: pinv(A, AI, m, n);
 *
 *   A : input matrix of dimension m x n (NOTE: WILL BE OVERWRITTEN!)
 *   AI: output matrix that contains the pseudoinverse of A -
 *       dimension n x m.
 *   
 *  (Based on code from Swagat Kumar)
 */
void pinv(double *A, double *AI, mwSignedIndex m, mwSignedIndex n){
  mwSignedIndex ldb, rank, lwork, info, sdim;
  mwSignedIndex i, j;  
  double *s, *B,  rcond, *work;

  ldb = MAX(m,n);                /* leading dimension of B */
  sdim = MIN(m,n);               /* # of singular values */
  rcond = 1e-06;                 /* condition number */
  lwork = 30 * m * n;            /* size of workspace */

  work = (double *)mxMalloc(lwork*sizeof(double));  
  s = (double *)mxMalloc(sdim*sizeof(double));
  B = (double *)mxMalloc(ldb*m*sizeof(double));
  /* Dimension of B  : ldb x m
     Dimension of A  : m x n
     Dimension of X  : n x m
     Dimension of AI : n x m  */

  for(i=0; i<ldb; i++){
    for(j = 0; j < m; j++){
      if(i == j) B[i+j*ldb] = 1.0;
      else       B[i+j*ldb] = 0.0;
    }
  }
  dgelss(&m, &n, &m, A, &m, B, &ldb, s, &rcond, &rank, work, &lwork, &info);
  for(i = 0; i < n; i++)
    for(j = 0; j < m; j++)
      AI[i+j*n] = B[i+j*ldb];

  mxFree(work);
  mxFree(s);
  mxFree(B);
} 


/* 
 *   PSEUDO-INVERSE Weighted
 *
 */

void pinvW(double **Xinv, mwSignedIndex nVols, mxArray *mxA, double *logData, double* W){
  mwSignedIndex j;
  
  const mwSignedIndex nrhs=3;
  const mwSignedIndex nlhs=1;
  mxArray *prhs[3];
  mxArray *plhs[1];
  
  mwSignedIndex dims[2];
  mxArray *mxLogData;
  double *tmpLogData;
  mxArray *mxW;
  double *tmpW;
  
  dims[0] = nVols;
  dims[1] = 1;
  mxLogData = mxCreateNumericArray(2, dims, mxDOUBLE_CLASS, mxREAL);
  tmpLogData = (double *)mxGetPr(mxLogData);
  mxW = mxCreateNumericArray(2, dims, mxDOUBLE_CLASS, mxREAL);
  tmpW = (double *)mxGetPr(mxW);

  for( j=0; j<nVols; j++) {
    tmpLogData[j] = logData[j];
    tmpW[j] = W[j];
  }
  prhs[0] = mxA;
  prhs[1] = mxLogData;
  prhs[2] = mxW;
  
  mexCallMATLAB(nlhs, plhs, nrhs, prhs, "lscov");
  *Xinv = (double *)mxGetPr(plhs[0]);
  if(*Xinv==NULL) mexErrMsgTxt("Solution to weighted inverse is empty.");
}


void setupBootstrapProcData(int nlhs, mxArray *plhs[], int nrhs,
                            const mxArray *prhs[], mwSignedIndex nDims, mwSignedIndex* dims,
                            const mwSignedIndex outDims[4], const mwSignedIndex pddDims[4],
                            mwSignedIndex nVox, mwSignedIndex nVols, mwSignedIndex nPermutations,
                            bool verbose, const double* permuteMatrix,
                            const double* X, double** bsX, double*** bsXinv, 
                            mwSignedIndex* bsStride, double** mdBs, double** faBs, 
                            double** pddBs, double** mdStd, double** faStd,
                            double** pddDisp, double** H, double** W, double** pLogData,
			    double*** logDataBs, bool bResidualBootstrap) {
  mwSignedIndex p,j,m,k;
  double seven=7;
  if(nPermutations>0){
    /*
     * PREPARE BOOTSTRAP
     *   1) Compute all the inversion matrices- one for each permutation.
     *   2) Allocate memory for stats
     */
    if( bResidualBootstrap ) {
      *logDataBs = (double **)myMalloc(nPermutations*sizeof(double));
      for(p=0; p<nPermutations; p++)
	(*logDataBs)[p] = (double *)myMalloc(nVols*sizeof(double));
      *H = (double *)myMalloc(nVols*sizeof(double));
      *W = (double *)myMalloc(nVols*sizeof(double));
      *pLogData = (double *)myMalloc(nVols*sizeof(double));
    }
    else {
      if(verbose) mexPrintf("Inverting %d permuted matrices for bootstrap...\n",nPermutations);
      *bsX = (double *)myMalloc(nVols*7*sizeof(double));
      *bsXinv = (double **)myMalloc(nPermutations*sizeof(double*));
      for(p=0; p<nPermutations; p++){
	(*bsXinv)[p] = (double *)myMalloc(nVols*7*sizeof(double));
	*bsStride = nVols*p;
	for(j=0;j<nVols; j++){
	  /* Convert from Matlab 1-indexing to C 0-indexing */
	  m = (mwSignedIndex)permuteMatrix[j+*bsStride]-1;
	  if(m<0||m>=nVols) {
	    mexPrintf("Out-of-range volume index (%d) in permutation array (%d,%d).",m+1,j+1,p+1);
	    mexErrMsgTxt("Aborting.");
	  }
	  for(k=0; k<7; k++){
	    (*bsX)[j+k*nVols] = X[m+k*nVols];
	  }
	}
	pinv(*bsX, (*bsXinv)[p], nVols, seven);
      }
    }
    
    *mdBs = (double *)myMalloc(nPermutations*sizeof(double));
    *faBs = (double *)myMalloc(nPermutations*sizeof(double));
    *pddBs = (double *)myMalloc(3*nPermutations*sizeof(double));
    
    
    plhs[2] = mxCreateNumericArray(nDims-1, outDims, mxDOUBLE_CLASS, mxREAL);
    if(plhs[2]==NULL) mexErrMsgTxt("out of memory.");
    *mdStd = (double *)mxGetPr(plhs[2]);
    
    plhs[3] = mxCreateNumericArray(nDims-1, outDims, mxDOUBLE_CLASS, mxREAL);
    if(plhs[3]==NULL) mexErrMsgTxt("out of memory.");
    *faStd = (double *)mxGetPr(plhs[3]);
        
    plhs[4] = mxCreateNumericArray(nDims-1, outDims, mxDOUBLE_CLASS, mxREAL);
    if(plhs[4]==NULL) mexErrMsgTxt("out of memory.");
    *pddDisp = (double *)mxGetPr(plhs[4]);
  }
  
  if(verbose) {
    if(nPermutations>0)
      mexPrintf("Tensor fitting with %d bootstrap iterations (%0.1f million tensor fits)...\n",nPermutations,nVox*nPermutations/1e6);
    else
      mexPrintf("Tensor fitting for %d voxels...\n",nVox);
  }
}

void matTensorFit(double A[9]/*out*/, mwSignedIndex nVols, const double* w, const double* logData, const double* Xinv, const double* permuteMatrix){
  mwSignedIndex j,n,l;
  double d;
  for(j=0; j<nVols; j++){
    l = j*7;
    if( permuteMatrix==NULL )
      n=j;
    else
      n = (mwSignedIndex)permuteMatrix[j]-1;
    if( w==NULL )
      d = logData[n];
    else
      d = w[n]*logData[n];
    /* Assign data to upper-triangular part of A */
    A[0] = A[0] + d*Xinv[l+1];
    A[4] = A[4] + d*Xinv[l+2];
    A[8] = A[8] + d*Xinv[l+3];
    A[3] = A[3] + d*Xinv[l+4];
    A[6] = A[6] + d*Xinv[l+5];
    A[7] = A[7] + d*Xinv[l+6];
  }
}

void dtTensorFit(double dt[7]/*out*/, mwSignedIndex nVols, const double* w, const double* logData, const double* Xinv){
  /* Need w??*/
  mwSignedIndex k;
  mwSignedIndex j;
  mwSignedIndex l;
  double d;
  for(k=0; k<7; k++) dt[k] = 0;
  for(j=0; j<nVols; j++){
    l = j*7;
    k = 0;
    if(w==NULL)
      d = logData[j];
    else
      d = w[j]*logData[j];  
    dt[k] = dt[k++] + d*Xinv[l  ];
    dt[k] = dt[k++] + d*Xinv[l+1];
    dt[k] = dt[k++] + d*Xinv[l+2];
    dt[k] = dt[k++] + d*Xinv[l+3];
    dt[k] = dt[k++] + d*Xinv[l+4];
    dt[k] = dt[k++] + d*Xinv[l+5];
    dt[k] = dt[k  ] + d*Xinv[l+6];
  }
}

mwSignedIndex computeResidual(double *maxErr/*out*/, double* err/*out*/, mwSignedIndex nVols, const double* w, const double* data, const double* X, const double* dt, const double* outlierThresh){
    double pLogData;
    mwSignedIndex l,k,j;
    double d;
    mwSignedIndex nOutliers=0;
    *maxErr = 0;
    for(j=0; j<nVols; j++){
        pLogData = 0;
        k = 0;
        if( w==NULL )
            d=1;
        else
            d=w[j];
        l=j;      pLogData = pLogData + d*X[l] * dt[k++];
        l+=nVols; pLogData = pLogData + d*X[l] * dt[k++];
        l+=nVols; pLogData = pLogData + d*X[l] * dt[k++];
        l+=nVols; pLogData = pLogData + d*X[l] * dt[k++];
        l+=nVols; pLogData = pLogData + d*X[l] * dt[k++];
        l+=nVols; pLogData = pLogData + d*X[l] * dt[k++];
        l+=nVols; pLogData = pLogData + d*X[l] * dt[k  ];
        err[j] = d*(data[j]-exp(pLogData));
        err[j] = SQUARE(err[j]);              
        if(err[j] > *maxErr) *maxErr = err[j];      
        if(outlierThresh!=NULL && err[j] > *outlierThresh) nOutliers++;
    }
    return nOutliers;
}

void computeResidualNew(double* err/*out*/, double* pLogData/*out*/, mwSignedIndex nVols, const double* H, const double *W, const double* logData, const double* X, const double* dt){
    mwSignedIndex j,k,l;
    for(j=0; j<nVols; j++){
        pLogData[j] = 0;
        k = 0;
        l=j;      pLogData[j] = pLogData[j] + X[l] * dt[k++];
        l+=nVols; pLogData[j] = pLogData[j] + X[l] * dt[k++];
        l+=nVols; pLogData[j] = pLogData[j] + X[l] * dt[k++];
        l+=nVols; pLogData[j] = pLogData[j] + X[l] * dt[k++];
        l+=nVols; pLogData[j] = pLogData[j] + X[l] * dt[k++];
        l+=nVols; pLogData[j] = pLogData[j] + X[l] * dt[k++];
        l+=nVols; pLogData[j] = pLogData[j] + X[l] * dt[k  ];
	if( H!=NULL && W!=NULL)
	  err[j] = W[j] * (logData[j]-pLogData[j]) / sqrt(1-H[j]);
	else
	  err[j] = (logData[j]-pLogData[j]);

    }
}

void computeHatDiag(double* H/*out*/, mwSignedIndex nVols, const double* X, const double* wXinv, const double* W){
  /* Only computing the diagonal of the Hat matrix. */
    mwSignedIndex j,k,l;
    for(j=0; j<nVols; j++){
        H[j] = 0;
        k = j*7;
        l=j;      H[j] += X[l] * wXinv[k++] * W[j];
        l+=nVols; H[j] += X[l] * wXinv[k++] * W[j];
        l+=nVols; H[j] += X[l] * wXinv[k++] * W[j];
        l+=nVols; H[j] += X[l] * wXinv[k++] * W[j];
        l+=nVols; H[j] += X[l] * wXinv[k++] * W[j];
        l+=nVols; H[j] += X[l] * wXinv[k++] * W[j];
        l+=nVols; H[j] += X[l] * wXinv[k  ] * W[j];
    }
}

void computeWeightDiag(double* W/*out*/, double* wX/*out*/, mwSignedIndex nVols, const double* X, const double* dt){
  double pLogData;
  mwSignedIndex j,k,l;
  
  for(j=0; j<nVols; j++){
    pLogData = 0;
    k = 0;
    l=j;      pLogData = pLogData + X[l] * dt[k++];
    l+=nVols; pLogData = pLogData + X[l] * dt[k++];
    l+=nVols; pLogData = pLogData + X[l] * dt[k++];
    l+=nVols; pLogData = pLogData + X[l] * dt[k++];
    l+=nVols; pLogData = pLogData + X[l] * dt[k++];
    l+=nVols; pLogData = pLogData + X[l] * dt[k++];
    l+=nVols; pLogData = pLogData + X[l] * dt[k  ];
    /*W[j] = SQUARE(exp( pLogData ));*/
    W[j] = exp( pLogData );
    for(l=j; l<j+7*nVols; l+=nVols){
      wX[l] = X[l]*W[j];
    }
  }
}

void handleOutliers(double outlierThresh, double maxErr, mwSignedIndex nVols, 
                    const double* err, mwSignedIndex maxIter, const double* dtTmp,
                    const double* logData, mwSignedIndex maxNumOutliers, 
                    const double* X, const double* wXinv, 
                    const double* data,
                    mwSignedIndex* nOutliers, mwSignedIndex* nVoxOutliers, double* w, 
                    double* wX) {
    mwSignedIndex j,iterNum,k;
    double seven=7;
    
    
        for(j=0; j<nVols; j++){
            if(err[j]>outlierThresh) (*nOutliers)++;
            w[j] = 1;  /* initialize weights to 1 */
        }
        if(maxErr>outlierThresh){
            /* mexPrintf("   Rejecting %d outliers in voxel %d...\n",nOutliers,i); */
            nVoxOutliers++;
        }
        iterNum = 0;
        while(maxErr>outlierThresh && *nOutliers<maxNumOutliers && iterNum<maxIter){
            iterNum++;
            for(j=0; j<nVols; j++){
                if(w[j]==0 || err[j]>outlierThresh) w[j] = 0;
                else                                w[j] = 1;
                for(k=0; k<7; k++){
                    wX[k*nVols+j] = w[j]*X[k*nVols+j];
                }
            }
            pinv(wX, wXinv, nVols, seven);
            dtTensorFit(dtTmp,nVols,w,logData,wXinv);
            /* Why not use wX here? Because pinv modifies it by storing some results there. */
            (*nOutliers)+= computeResidual(&maxErr, err, nVols, w, data, X, dtTmp, &outlierThresh);
            
        } /* end while(maxErr>outlierThresh && nOutliers<maxNumOutliers) ... */
}

void calcTensorSummary(mwSignedIndex N, const double* A, const double* W,
                       const double* WORK, mwSignedIndex INFO, mwSignedIndex LWORK,
                       double sqrtThreeOverTwo, double* md, double* fa,
                       double* pdd_0, double* pdd_1, double* pdd_2) {
    
    /* Eigensystem decomposition */
    dsyev("V", "U", &N, A, &N, W, WORK, &LWORK, &INFO);
    *md = (W[0]+W[1]+W[2])/3;
    if(*md<=0){
        *fa = 0;
    }else{
        *fa = sqrt(SQUARE(W[0]-*md)+SQUARE(W[1]-*md)+SQUARE(W[2]-*md))
        / sqrt(SQUARE(W[0])+SQUARE(W[1])+SQUARE(W[2]))
        * sqrtThreeOverTwo;
    }
    if(*fa<0.0) *fa = 0.0; else if(*fa>1.0) *fa = 1.0;
    *pdd_0 = A[6];
    *pdd_1 = A[7];
    *pdd_2 = A[8];
}

void calcTensorSummaryStats(mwSignedIndex nPermutations, mwSignedIndex N, const double* W, 
                            const double *WORK, mwSignedIndex LWORK, mwSignedIndex INFO,
                            double* A, double* md, double* fa, 
                            double* mdBs, double* faBs, double* pddBs, 
                            double* mdStd, double* faStd, double* pddDisp){
    mwSignedIndex p,n;
    *md = *md/nPermutations;
    *fa = *fa/nPermutations;
    *mdStd = 0;
    *faStd = 0;
    *pddDisp = 0;
    for(p=0; p<nPermutations; p++){
        *mdStd += SQUARE((*md-mdBs[p]));
        *faStd += SQUARE((*fa-faBs[p]));
    }
    *mdStd = sqrt(*mdStd/nPermutations);
    *faStd = sqrt(*faStd/nPermutations);

    /*
     * COMPUTE WATSON DISPERSION:
     *
     * [wVec,wVal] = eig(vec*vec');
     * meanDirection = wVec(:,1);
     * dispersion = n-n*wVal(1);
     * (See: A Schwartzman, RF Dougherty, JE Taylor (2005), MRM 53(6))
     * For a Matlab implementation, see dtiDirMean.m.
     */
    for(n=0; n<9; n++) A[n]=0;
    for(p=0; p<nPermutations; p++){
              /* This implements pdd*pdd', summed across all permutations (the mean scatter matrix) */
        n = p*3;
        A[0] = A[0] + pddBs[n  ] * pddBs[n  ];
        A[4] = A[4] + pddBs[n+1] * pddBs[n+1];
        A[8] = A[8] + pddBs[n+2] * pddBs[n+2];
        A[3] = A[3] + pddBs[n+1] * pddBs[n  ];
        A[6] = A[6] + pddBs[n+2] * pddBs[n  ];
        A[7] = A[7] + pddBs[n+2] * pddBs[n+1];
    }

    for(n=0; n<9; n++) if(A[n]!=0) A[n]=A[n]/nPermutations;
            /* The dispersion is simply the largest eigenvalue of that mean scatter matrix. */
    dsyev("V", "U", &N, A, &N, W, WORK, &LWORK, &INFO);
            /* DSYEV orders the eigenvalues in ascending order. */
            /* Mean direction should be in A[6+[0:2]] */

    *pddDisp = (nPermutations - nPermutations*W[2])/(nPermutations-1);
            /* Convert to an angle (in radians) */
    *pddDisp = asin(sqrt(*pddDisp));
}

/*
 * Entry point for MEX function
 */
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]){
  mwSignedIndex i, j, k, l, m, n, p, bsStride;
  double *permuteMatrix = NULL;
  mwSignedIndex nPermutations = 0;
  mwSignedIndex *dims;
  mwSignedIndex *maskDims;
  mwSignedIndex nDims, nVols, nVox;
  double *dwRaw=NULL;
  unsigned char *mask=NULL;
  double *X, *wX, *Xinv, *wXinv, *Xtmp, *bsX, **bsXinv;
  mwSignedIndex outDims[4],pddDims[4];
  double *dt, dtTmp[7];
  double minVal, logMinVal, maxDatVal, maxErr, d, meanErr;
  double *logData, *data, *err, *w;
  double *pdd, *mdStd, *faStd, *pddDisp, *outliers;
  double *mdBs, *faBs, *pddBs, md, fa;
  const double sqrtThreeOverTwo = sqrt(3/2);
  bool verbose=true;
  double  seven=7;
  /* Vars used by LAPACK's DSYEV */
  mwSignedIndex    N=3;
  double A[3*3];
  double W[3];       /* Eigenvalues */
  double WORK[102];  /* Workspace. Optimal size found by experiment*/
  mwSignedIndex    LWORK = sizeof(WORK) / sizeof(double);
  mwSignedIndex    INFO;
  double outlierThresh;
  mwSignedIndex nOutliers, maxNumOutliers, totalNumOutliers, nVoxOutliers, updateInterval, iterNum, maxIter=100;

  bool bResidualBootstrap;
  double *H, *covWeights, *pLogData;
  double** logDataBs;
  
  /*
   * CHECK INPUT ARGS
   */
  if(nrhs<2 || nrhs>6) {
    /* help */
    mexPrintf("\n[dt,pdd] = dtiFitTensor(dwRaw, X, [bootstrapFlag], [permuteMatrix], [mask], [outlierThreshold])\n");
    mexPrintf("\n  dwRaw: XxYxZxN or PxN double array of raw DW data volumes\n");
    mexPrintf("  X: Nx7 array specifying the DW scheme, where each row of X is:\n");
    mexPrintf("     [1, -b_i gx_i gx_i, -b_i gy_i gy_i, -b_i gz_i gz_i, -2b_i gx_i gy_i, -2b gx_i gz_i, -2b_i gy_i gz_i]\n");
    mexPrintf("     where b_i is the b-value and gx_i,gy_i,gz_i is the vector direction of the ith volume in dwRaw.\n");
    mexPrintf("  bootstrapFlag (optional): 0 indicates residual bootstrap and 1 indicates repetition bootstrap (default).\n");
    mexPrintf("  permuteMatrix (optional): an NxM array of (1-indexed) volume indices into dwRaw specifying the M bootstrap permutations.\n");
    mexPrintf("  mask (optional): an XxYxZ or P binary mask that specifies which voxels you want to fit.\n");
    mexPrintf("Returns:\n");
    mexPrintf("  A: an XxYxZx7 (or Px7) volume of fits, where the first volume is the b=0 insity image and the remaining 6 are the\n");
    mexPrintf("     6 unique tensor elements in [Dx Dy Dz Dxy Dxz Dyz] order.\n");
    mexPrintf("  pdd: the first eigenvector scaled by fa. To show a nice RGB direction map, try\n");
    mexPrintf("       showMontage(abs(pdd)). To recover fa, use fa=sqrt(sum(pdd.^2,4));\n");
    mexPrintf("  If a permute matrix was sent in, you'll also get:\n");
    mexPrintf("     arrays with the bootstrap stats volumes. Currently, we return the following stats:\n");
    mexPrintf("       pdd dispersion, fa stdev, md stdev\n");
    mexPrintf("\n");
    return 0;
  }else if(nlhs<1) {
    mexErrMsgTxt("At least one output required.");
  }else if(!mxIsDouble(prhs[0]) || mxIsComplex(prhs[0]) || (mxGetNumberOfDimensions(prhs[0])!=4 && mxGetNumberOfDimensions(prhs[0])!=2)){
    /* Arg 1 must be a real XxYxZxN or PxN array of raw data */
    mexPrintf("%d\n", mxGetNumberOfDimensions(prhs[0]));
    mexErrMsgTxt("Raw data must be a real XxYxZxN or PxN array of doubles.");
  }

  nDims = mxGetNumberOfDimensions(prhs[0]);
  dims = mxGetDimensions(prhs[0]);
  nVols =  dims[nDims-1];
  nVox = dims[0];
  for(i=1; i<(nDims-1); i++) nVox = nVox*dims[i];
  /* Don't allow more than 10% outliers */
  maxNumOutliers = nVols*0.1+0.5;

  if(!mxIsDouble(prhs[1]) || mxIsComplex(prhs[1]))
    mexErrMsgTxt("X must be a real array.");
  if(mxGetNumberOfDimensions(prhs[1])!=2 || mxGetM(prhs[1])!=nVols || mxGetN(prhs[1])!=7){
    mexPrintf("nVox=%d, nDims=%d, N=%d; X is %dx%d\n", nVox, nDims, nVols, mxGetM(prhs[1]), mxGetN(prhs[1]));
    for(i=0; i<nDims; i++) mexPrintf("dim[%d]=%d\n",i,dims[i]);
    mexErrMsgTxt("X must be an Nx7 array.");
  }
  
  if(nrhs>=3 && !mxIsEmpty(prhs[2])){
    /* Arg 3 must be a single number indicating bootstrap type*/
    if(mxGetNumberOfElements(prhs[2])!=1 || !mxIsNumeric(prhs[2]) || mxIsComplex(prhs[2])){
      mexErrMsgTxt("bootstrapFlag must be empty or a real numeric scalar.");
    }
    bResidualBootstrap = mxGetScalar(prhs[2]) < 1;
  }else{
    bResidualBootstrap = false;
  }

  if(nrhs>=4){
    /* Arg 4 must be a real NxM array of permutations */
    if(!mxIsEmpty(prhs[3]) && (!mxIsDouble(prhs[3]) || mxGetNumberOfDimensions(prhs[3])!=2
			       || mxGetM(prhs[3])!=nVols)){
      mexErrMsgTxt("permuteMatrix must be an NxM array of volume indices into dwRaw.");
    }
    if(!mxIsEmpty(prhs[3])){
      permuteMatrix = (double *)mxGetPr(prhs[3]);
      nPermutations = (mwSignedIndex)mxGetN(prhs[3]);
    }
  }
  
  if(nrhs>=5 && !mxIsEmpty(prhs[4])){
    /* Arg 5 must be a uint8 XxYxZ binary brain mask */
	if(!mxIsClass(prhs[4],"uint8")){
	  mexErrMsgTxt("mask must be empty (no mask) or an XxYxZ (or Px1) uint8 array.");
	}
    if(mxGetNumberOfDimensions(prhs[4])!=(nDims-1))
	  mexErrMsgTxt("mask is not the same dimensionality as a data volume!");
    maskDims = mxGetDimensions(prhs[4]);
    mask = (unsigned char *)mxGetPr(prhs[4]);
    n = maskDims[0];
    for(i=1; i<(nDims-1); i++) n = n*(maskDims[i]);
	if(n!=nVox){
	  mexPrintf("mask = %d, vol = %d.\n",n,nVox);
	  mexErrMsgTxt("mask is not the same size as a data volume!");
	}
    n = 0;
    for(i=0; i<nVox; i++) if(mask[i]!=0) n++;
    mexPrintf("Using data mask to process %d of %d voxels (%0.1f%%).\n",n,nVox,100.0*n/nVox);
  }

  
  if(nrhs>=6 && !mxIsEmpty(prhs[5])){
    /* Arg 6 must be a real double scalar */
    if(mxGetNumberOfElements(prhs[5])!=1 || !mxIsNumeric(prhs[5]) || mxIsComplex(prhs[5])){
      mexErrMsgTxt("outlier threshold must be empty (no outlier rejection) or a real numeric scalar.");
    }
    outlierThresh = SQUARE(mxGetScalar(prhs[5]));
  }else{
    outlierThresh = 0;
  }


  /*
   * SET UP THE DATA FOR PROCESSING
   */
  dwRaw = (double *)mxGetPr(prhs[0]);
  if(dwRaw==NULL) mexErrMsgTxt("no real data in array dwRaw.");

  X = (double *)mxGetPr(prhs[1]);
  if(X==NULL) mexErrMsgTxt("no real data in array X.");

  /* Create the output arrays */
  for(i=0; i<(nDims-1); i++){
    outDims[i] = dims[i];
    pddDims[i] = dims[i];
  }
  outDims[nDims-1] = 7;
  pddDims[nDims-1] = 3;

  /* 
   * Compute the minimum data value that's >0. We'll use this to replace values 
   * <=0 to avoid log(0) issues.
   */
  minVal = 1e-6;
  for(i=0; i<nVox*nVols; i++) if(dwRaw[i]>0&&dwRaw[i]<minVal) minVal=dwRaw[i];
  logMinVal = log(minVal);

  data = (double *)myMalloc(nVols*sizeof(double));
  logData = (double *)myMalloc(nVols*sizeof(double));
  err = (double *)myMalloc(nVols*sizeof(double));
  w = (double *)myMalloc(nVols*sizeof(double));

  /*
   *  INVERT B MATRICES FOR LINEAR LEAST-SQUARES FITTING
   * 
   */
  if(verbose) mexPrintf("Inverting matrix for %d volumes...\n",nVols);
  Xinv = (double *)myMalloc(nVols*7*sizeof(double));
  wXinv = (double *)myMalloc(nVols*7*sizeof(double));
  /* dgelss will overwrite our X-matrix, so make a copy */
  Xtmp = (double *)myMalloc(7*nVols*sizeof(double));
  for(i=0; i<7*nVols; i++) Xtmp[i] = X[i];
  pinv(Xtmp, Xinv, nVols, 7);

  /*
   * Calling matlab's pinv isn't too much slower, but the time difference becomes 
   * non-trivial when we do the bootstrap iterations. (~ 1.5 - 2 X)
   * mxArray *tmp;
   * mexCallMATLAB(1, &tmp, 1, &prhs[1], "pinv");
   * Xinv = (double *)mxGetPr(tmp);
   * if(Xinv==NULL) mexErrMsgTxt("no real data in array Xinv.");
   */

  /* We're done with Xtmp, but we'll need wX below, so just reuse the memory. */
  wX = Xtmp;
  
  /* 
   * Set up the basic output arrays.
   * TO DO: make these contingent on nlhs for better efficiency.
   */
  plhs[0] = mxCreateNumericArray(nDims, outDims, mxDOUBLE_CLASS, mxREAL);
  if(plhs[0]==NULL) mexErrMsgTxt("out of memory.");
  /* mxCreateNumericArray initializes all values to 0 */
  dt = (double *)mxGetPr(plhs[0]);
  
  plhs[1] = mxCreateNumericArray(nDims, pddDims, mxDOUBLE_CLASS, mxREAL);
  if(plhs[1]==NULL) mexErrMsgTxt("out of memory.");
  pdd = (double *)mxGetPr(plhs[1]);


  /*
   * SET UP THE BOOTSTRAP
   */
  setupBootstrapProcData(nlhs, plhs, nrhs, prhs, nDims, dims, outDims, 
                         pddDims, nVox, nVols, nPermutations, verbose, 
                         permuteMatrix, X, &bsX, &bsXinv, &bsStride, &mdBs, 
                         &faBs, &pddBs, &mdStd, &faStd, &pddDisp, &H, &covWeights, &pLogData, 
						 &logDataBs, bResidualBootstrap);
  

  /*
   * MAIN VOXEL LOOP
   */
  mexPrintf("Beginning to process %d voxels.\n",nVox);
  nVoxOutliers = 0;
  totalNumOutliers = 0;
  updateInterval = nVox/10;
  for(i=0; i<nVox; i++){
    /* Weirdest thing is that this code stops any return values */
    if(i%updateInterval==0) mexPrintf("voxel %d of %d...\n",i,nVox);
    
    if(mask!=NULL && mask[i]==0)
      continue;

    /* Prep data- extract relevent chunk, tidy it up, and compute the log */
    maxDatVal = 0;
    for(j=0; j<nVols; j++){
      data[j] = dwRaw[i+j*nVox];
      if(data[j]>maxDatVal) maxDatVal = data[j];
      if(data[j]<=0) logData[j] = logMinVal;
      else logData[j] = log(data[j]);
    }
    
    /* Skip voxels with all degenrate data (all<=0). Note that all return arrays are 
     * initialized to 0, so skipping degenerate voxels will return 0 for these voxels. 
     */
    if(maxDatVal<=logMinVal)
      continue;
    
    /* 
     * LINEAR LEAST-SQUARES TENSOR FIT TO DATA
     * Simply log(dwRaw)*Xinv
     *
     * To do a weighted least-squares, we need to recompute Xinv to solve for dt:
     *    w*X*dt = w*log(dwRaw)
     * 
     * Matlab code:
     *    wXinv = pinv(repmat(w,[1,7).*X));
     *    wdt = wXinv*(w.*logData)
     *
     * Chang, Jones, Peirpaoli's RESTORE can be done with linear fitting, and this
     * should be *much* faster tahn using non-linear methods. But- what weighting 
     * function to use? They just say:
     *   "...designing the proper weighting function for logarithm 
     *    transformed data corrupted by artifacts may be difficult..."
     *
     * Perhaps a simple 'unweighted fit, discard outliers, refit' algorithm would 
     * be a reasonable compromise?
     */
    

    /* dt = Xinv*log(dwRaw). */
    dtTensorFit(dtTmp,nVols,NULL,logData,Xinv);
    for(k=0; k<7; k++) dt[i+k*nVox] = dtTmp[k];
    
    if(nPermutations>0 && bResidualBootstrap) {
      /* Perform weightedLS and find normalized residuals that have
       * approximately the same variance so that we can draw from the
       * residuals with bootstrap as if they are i.i.d. 
       */
      
      /* Variance of each measurement */
      computeWeightDiag(covWeights, wX, nVols, X, dt);
      /* Turn WLS into OLS by replacing X with W*X and Y with W*Y */
      pinv(wX, wXinv, nVols, seven);
      /* H = X*(X'*W^2*X)^-1*X'*W^2 */
      computeHatDiag(H, nVols, X, wXinv, covWeights);
      /* Now we can do tensor fit as normal with Y replaced by W*Y */
      dtTensorFit(dtTmp,nVols,covWeights,logData,wXinv);
      /* Residuals are computed and reweighted to be normalized by their variance */
      computeResidualNew(err, pLogData, nVols, H, covWeights, logData, X, dtTmp);
      
      /*mexPrintf("Residual: "); for(k=0;k<nVols;k++) mexPrintf(" %g",err[k]); mexPrintf("\n");
      mexPrintf("W: "); for(k=0;k<nVols;k++) mexPrintf(" %g",covWeights[k]); mexPrintf("\n");
      mexPrintf("pLogData: "); for(k=0;k<nVols;k++) mexPrintf(" %g",pLogData[k]); mexPrintf("\n");
      mexPrintf("logData:  "); for(k=0;k<nVols;k++) mexPrintf(" %g",logData[k]); mexPrintf("\n");
      */

      /* Now make all the residuals mean zero. */
      meanErr = 0;
      for(k=0;k<nVols;k++) meanErr+=err[k];
      meanErr/=nVols;

      /* Store bootstrapped new log data vector for bootstrap analysis*/
      for(p=0; p<nPermutations; p++){
	bsStride = nVols*p;
	for(j=0;j<nVols; j++){
	  /* Convert from Matlab 1-indexing to C 0-indexing */
	  m = (mwSignedIndex)permuteMatrix[j+bsStride]-1;
	  if(m<0||m>=nVols) {
	    mexPrintf("Out-of-range volume index (%d) in permutation array (%d,%d).",m+1,j+1,p+1);
	    mexErrMsgTxt("Aborting.");
	  }
	  logDataBs[p][j] = pLogData[j] + (1.0/covWeights[j])*(err[m]-meanErr); 
	}
      }
    } 
    else {
      /* Compute residuals
       * The predicted log(data) value is pLogData = X*dt.
       * The residual for a data value is data[j]-exp(pLogData)
       */
      computeResidual(&maxErr, err, nVols, NULL, data, X, dtTmp, NULL);

      nOutliers = 0;
      if(outlierThresh!=0){
	/*
	 * Iterate and reject all outliers
	 */
	handleOutliers(outlierThresh, maxErr, nVols, err, maxIter,
		       dtTmp, logData, maxNumOutliers, X, wXinv, data,
		       &nOutliers, &nVoxOutliers, w, wX);
	if(iterNum==maxIter){
	  mexPrintf("   MAX ITERATIONS REACHED in voxel %d!\n",i);
	}
	for(k=0; k<7; k++) dt[i+k*nVox] = dtTmp[k];
	totalNumOutliers += nOutliers;
      }
    }       
    
    
    /* Assign data to upper-triangular part of A */ 
    k = i;
    A[0] = dt[k+=nVox];
    A[4] = dt[k+=nVox];
    A[8] = dt[k+=nVox];
    A[3] = dt[k+=nVox];
    A[6] = dt[k+=nVox];
    A[7] = dt[k+=nVox];
    /*
     * COMPUTE FA & PDD
     */
    calcTensorSummary(N, A, W, WORK, INFO, LWORK, 
		      sqrtThreeOverTwo, &md, &fa, pdd+i, pdd+i+nVox,
		      pdd+i+2*nVox);
    for(n=0; n<3; n++)
      pdd[i+n*nVox] *= fa;

    if(nPermutations>0){
      /*
       * BOOTSTRAP VARIANCE ESTIMATE
       */
      md = 0;
      fa = 0;
      for(p=0; p<nPermutations; p++){
	for(n=0; n<9; n++) A[n]=0;
	
	if(bResidualBootstrap) {
	  /* Residual bootstrap*/
	  /* All we have to do is compute a new tensor with our
	   * bootstrapped data.  /* Doing this with the WLS tensor
	   * estimate, but have tried * the OLS tensor estimate with the
	   * new data and it also works.
	   */
	  matTensorFit(A, nVols, covWeights, logDataBs[p], wXinv, NULL); 
	  /*matTensorFit(A, nVols, NULL, logDataBs[p], Xinv, NULL);*/
	}
	else {
	  /* Repetition bootstrap*/
	  /* Apply permutation matrix, recompute tensor, then extract stats. */
	  /* Linear least-quares fit */
	  maxDatVal = 0;
	  bsStride = nVols*p;    

	  if(nOutliers>0){
	    /* We have to recompute the weighted Xinv for this permutation. */
	    bsStride = nVols*p;
	    for(j=0;j<nVols; j++){
	      n = (mwSignedIndex)permuteMatrix[j+bsStride]-1;
	      for(k=0; k<7; k++){
		bsX[j+k*nVols] = wX[n+k*nVols];
	      }
	    }
	    pinv(bsX, wXinv, nVols, seven);
	    matTensorFit(A, nVols, w, logData, wXinv, permuteMatrix+bsStride);
	  }else{ /* nOutliers == 0 */
	    /* compute dt for the bootstrap permuatation and store it in a matrix A.
	     * We do this (rather than using the dt6 format) because we want to do
	     * the eigenvalue decomposition below.
	     */
	    matTensorFit(A, nVols, NULL, logData, bsXinv[p], permuteMatrix+bsStride);
	  }
	}
	
	
	/* Note this function does not do the same thing in that fa is 
	   calculated differently than Bob originally wrote */
	calcTensorSummary(N, A, W, WORK, INFO, LWORK, 
			  sqrtThreeOverTwo, mdBs+p, faBs+p, pddBs+p*3, 
			  pddBs+p*3+1, pddBs+p*3+2);
	/*
        mexPrintf("fa: %g\n", faBs[p]);
	mexPrintf("md: %g\n", mdBs[p]);
	mexPrintf("pdd: %g,%g,%g\n", pddBs[p*3],pddBs[p*3+1],pddBs[p*3+2]);
	*/	

	md += mdBs[p];
	fa += faBs[p];
      } /* end for(p=0; p<nPermutations; p++) */
    
      if(md>0){
	calcTensorSummaryStats(nPermutations, N, W, WORK, LWORK, INFO,
			       A, &md, &fa, mdBs, faBs, pddBs, mdStd+i, 
			       faStd+i, pddDisp+i);
      }
    } /* end if(nPermutations>0)...else... */
  } /* end  for(i=0; i<nVox; i++) */
  
  if(outlierThresh>0){
    mexPrintf("Outlier rejection threshold %0.2f rejected %d outliers across %d voxels.\n",outlierThresh,totalNumOutliers,nVoxOutliers);
  }

  /*
   * CLEAN UP
   */
  if(nPermutations>0){
    if( bResidualBootstrap ) {
      for(p=0; p<nPermutations; p++) mxFree(logDataBs[p]);
      mxFree(logDataBs);
      mxFree(H);
      mxFree(covWeights);
      mxFree(pLogData);
    }
    else {
      for(p=0; p<nPermutations; p++) mxFree(bsXinv[p]);
      mxFree(bsXinv);
      mxFree(bsX);
    }
    mxFree(mdBs);
    mxFree(faBs);
    mxFree(pddBs);
  }
  mxFree(Xinv);
  mxFree(wXinv);
  mxFree(data);
  mxFree(logData);
  mxFree(err);
  mxFree(Xtmp);
}
