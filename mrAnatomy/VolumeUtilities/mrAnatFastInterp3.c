/*  Matlab MEX file.

05/04/99 - ON - Corrected bug in interpolation (switched wa and wb)
                and some changes to improve speed (register variables,
                and avoiding calling function modf in the loop).
 *
 * 2007.05.07 RFD: copied Oscar's code and modified it to do fast 
 * linear interpolation on uint8 data. I also simplified the input 
 * args (volume size is now gleaned from the array dims). I also
 * swapped a and b in fastInterp3 so that the implicit voxel order
 * is now [rows,cols,planes], like the spm routines. (If you used 
 * meshgrid to generate sample points for myCinterp3, use ndgrid for 
 * this function.)  I also changed the size of the sample array 
 * from Nx3 to 3xN. Since our coordinate transofrms are all assumed 
 * to be pre-multiply format, 3xN is better since it avoids unecessary 
 * transposes. And, we now assume that the samples are specified in 
 * Matlab's 1-indexed convention and thus use samplePts-1 in the C code.
 *
 * to compile, try:
 * mex -O mrAnatFastInterp3.c
 *
 */


#include "mex.h"
#include <stdio.h>
#include <ctype.h>
#include <math.h>
#include <sys/types.h>

typedef struct
{
    unsigned char *dataPtr;       /* Pointer to data. */
    float *dataPtrF;       /* Pointer to float data. */
    int dim1;            /* dimensions */
    int dim2;
    int dim3;
    double pixdim1;
    double pixdim2;
    double pixdim3;
    double origin1;
    double origin2;
    double origin3;
} volume;
typedef struct
{
    double *coordPtr;       /* Pointer to coords. */
    int nCoords;            /* number of coords */
} coordinates;

/* Globals for the current volume and coords */
volume curVol;
coordinates curCoords;

/*
 * Simple wrapper for memory allocation.
 */
void *myrealloc(unsigned char *ptr, int newSize)
{
    ptr = realloc(ptr,newSize);
    if(ptr==NULL && newSize>0)
	mexErrMsgTxt("Internal out of memory!");
    return ptr;
}

/*
 * Called when matlab decides to unload this mex file 
 */
void cleanUpMex(void)
{
    if(curVol.dataPtr!=NULL)
        free(curVol.dataPtr);
    if(curVol.dataPtrF!=NULL)
        free(curVol.dataPtrF);
    if(curCoords.coordPtr!=NULL)
        free(curCoords.coordPtr);
}


/*
 * Trilinear interpolation. Here's where it all happens.
 */
void fastInterp3(volume *vol, coordinates *coords, unsigned char *f, unsigned char badval, double xform[]){
    int  i;
    unsigned char *volR = vol->dataPtr;
    double *ptsR   = coords->coordPtr;
    double tmpVal;
    int    nptsR = coords->nCoords;
    unsigned char badvalR = badval;
    int size1R = vol->dim1;
    int size2R = vol->dim2;
    int size3R = vol->dim3;
    int skip2 = size1R*size2R;

    /* Tri-linear */
    int	x0, y0, z0, x1, y1, z1;
    double x, y, z, wx, wy, wz, dx00, dx01, dx10, dx11, dxy0, dxy1;
    double d000, d001, d010, d011, d100, d101, d110, d111;
    double rot[9], *r, *t, *c, xSq, ySq, b_eddy;
    int phaseDir;
    
    if(xform!=NULL){
        t = xform; /* the 3 translations are xform[0,1,2] */
        r = xform+3; /* the 3 Euler angles are xform[3,4,5] */
        c = xform+6; /* the 8 warp params are xform[6-13] */
        phaseDir = (int)*(xform+14); /* the phase dir is in xform[14] */
        /* precompute rotation matrix */
        rot[0] = cos(r[1])*cos(r[2]);
        rot[1] = cos(r[1])*sin(r[2]);
        rot[2] = sin(r[1]);
        rot[3] = sin(r[0])*-sin(r[1])*cos(r[2])+cos(r[0])*-sin(r[2]);
        rot[4] = sin(r[0])*-sin(r[1])*sin(r[2])+cos(r[0])*cos(r[2]);
        rot[5] = sin(r[0])*cos(r[1]);
        rot[6] = cos(r[0])*-sin(r[1])*cos(r[2])+-sin(r[0])*-sin(r[2]);
        rot[7] = cos(r[0])*-sin(r[1])*sin(r[2])+-sin(r[0])*cos(r[2]);
        rot[8] = cos(r[0])*cos(r[1]);
        /*for(i=0;i<9;i++){ printf("%0.4f ",rot[i]);if(i==2||i==5||i==8) printf("\n"); }*/
    }
    for (i=0;i<nptsR;i++) {
        x = *ptsR;ptsR++;
        y = *ptsR;ptsR++;
        z = *ptsR;ptsR++;
        if(xform!=NULL){
            /* Apply coordinate transform */
            wx = x; wy = y; /* temporarily save old values */
            /* rotation & translation*/
            x = wx*rot[0]+wy*rot[1]+z*rot[2] + t[0];
            y = wx*rot[3]+wy*rot[4]+z*rot[5] + t[1];
            z = wx*rot[6]+wy*rot[7]+z*rot[8] + t[2];
            /* warping */
            xSq = x*x;
            ySq = y*y;
            b_eddy = c[0]*x + c[1]*y + c[2]*z + c[3]*x*y + c[4]*x*z + c[5]*y*z + c[6]*(xSq-ySq) + c[7]*(z*z*2-xSq-ySq);
            if(phaseDir==1) x = x-b_eddy;
            else if(phaseDir==3) z = z-b_eddy;
            else y = y-b_eddy;
        }
        /* The '-1's convert matlab 1-indexed coords to C zero-indexed.*/
        x = x-1;
        y = y-1;
        z = z-1;
        x0 = (int)x;
        wx = x - x0;
        y0 = (int)y;
        wy = y - y0;
        z0 = (int)z;
        wz = z - z0;
        x1 = x0 + 1;
        y1 = y0 + 1;
        z1 = z0 + 1;
        /* deal with edges by duplicating edge data. */
        if(x0==-1) x0=0; if(y0==-1) y0=0; if(z0==-1) z0=0;
        if(x1==size1R) x1=size1R-1; if(y1==size2R) y1=size2R-1; if(z1==size3R) z1=size3R-1;
        
        if (x0>=0 && x1<size1R && y0>=0 && y1<size2R && z0>=0 && z1<size3R){
            d000 = volR[x0+y0*size1R+z0*skip2];
            d100 = volR[x1+y0*size1R+z0*skip2];
            d010 = volR[x0+y1*size1R+z0*skip2];
            d110 = volR[x1+y1*size1R+z0*skip2];
            d011 = volR[x0+y1*size1R+z1*skip2];
            d111 = volR[x1+y1*size1R+z1*skip2];
            d001 = volR[x0+y0*size1R+z1*skip2];
            d101 = volR[x1+y0*size1R+z1*skip2];
            /* take weighted mean. */
            /* To save a few ops, we use l+w*(h-l), which is equivalent to (w*h)+((1-w)*l) */
            dx00 = d000 + wx*(d100-d000);
            dx01 = d001 + wx*(d101-d001);
            dx10 = d010 + wx*(d110-d010);
            dx11 = d011 + wx*(d111-d011);
            dxy0 = dx00 + wy*(dx10-dx00);
            dxy1 = dx01 + wy*(dx11-dx01);
            tmpVal = dxy0 + wz*(dxy1-dxy0);
            if(tmpVal<0) tmpVal=0; if(tmpVal>255) tmpVal=255;
            f[i] = (unsigned char)tmpVal;
        }else{
            f[i] = badvalR;
        }
    }
}

void fastInterp3F(volume *vol, coordinates *coords, float *f, float badval, double xform[]){
    int  i;
    float *volR = vol->dataPtrF;
    double *ptsR   = coords->coordPtr;
    int    nptsR = coords->nCoords;
    float badvalR = badval;
    int size1R = vol->dim1;
    int size2R = vol->dim2;
    int size3R = vol->dim3;
    int skip2 = size1R*size2R;

    /* Tri-linear */
    int	x0, y0, z0, x1, y1, z1;
    double x, y, z, wx, wy, wz, dx00, dx01, dx10, dx11, dxy0, dxy1;
    double d000, d001, d010, d011, d100, d101, d110, d111;
    double rot[9], *r, *t, *c, xSq, ySq, b_eddy;
    int phaseDir;
    
    if(xform!=NULL){
        t = xform; /* the 3 translations are xform[0,1,2] */
        r = xform+3; /* the 3 Euler angles are xform[3,4,5] */
        c = xform+6; /* the 8 warp params are xform[6-13] */
        phaseDir = (int)*(xform+14); /* the phase dir is in xform[14] */
        /* precompute rotation matrix */
        rot[0] = cos(r[1])*cos(r[2]);
        rot[1] = cos(r[1])*sin(r[2]);
        rot[2] = sin(r[1]);
        rot[3] = sin(r[0])*-sin(r[1])*cos(r[2])+cos(r[0])*-sin(r[2]);
        rot[4] = sin(r[0])*-sin(r[1])*sin(r[2])+cos(r[0])*cos(r[2]);
        rot[5] = sin(r[0])*cos(r[1]);
        rot[6] = cos(r[0])*-sin(r[1])*cos(r[2])+-sin(r[0])*-sin(r[2]);
        rot[7] = cos(r[0])*-sin(r[1])*sin(r[2])+-sin(r[0])*cos(r[2]);
        rot[8] = cos(r[0])*cos(r[1]);
        /*for(i=0;i<9;i++){ printf("%0.4f ",rot[i]);if(i==2||i==5||i==8) printf("\n"); }*/
    }
    for (i=0;i<nptsR;i++) {
        x = *ptsR;ptsR++;
        y = *ptsR;ptsR++;
        z = *ptsR;ptsR++;
        if(xform!=NULL){
            /* Apply coordinate transform */
            wx = x; wy = y; /* temporarily save old values */
            /* rotation & translation*/
            x = wx*rot[0]+wy*rot[1]+z*rot[2] + t[0];
            y = wx*rot[3]+wy*rot[4]+z*rot[5] + t[1];
            z = wx*rot[6]+wy*rot[7]+z*rot[8] + t[2];
            /* warping */
            xSq = x*x;
            ySq = y*y;
            b_eddy = c[0]*x + c[1]*y + c[2]*z + c[3]*x*y + c[4]*x*z + c[5]*y*z + c[6]*(xSq-ySq) + c[7]*(z*z*2-xSq-ySq);
            if(phaseDir==1) x = x-b_eddy;
            else if(phaseDir==3) z = z-b_eddy;
            else y = y-b_eddy;
        }
        /* The '-1's convert matlab 1-indexed coords to C zero-indexed.*/
        x = x-1;
        y = y-1;
        z = z-1;
        x0 = (int)x;
        wx = x - x0;
        y0 = (int)y;
        wy = y - y0;
        z0 = (int)z;
        wz = z - z0;
        x1 = x0 + 1;
        y1 = y0 + 1;
        z1 = z0 + 1;
        /* deal with edges by duplicating edge data. */
        if(x0==-1) x0=0; if(y0==-1) y0=0; if(z0==-1) z0=0;
        if(x1==size1R) x1=size1R-1; if(y1==size2R) y1=size2R-1; if(z1==size3R) z1=size3R-1;
        
        if (x0>=0 && x1<size1R && y0>=0 && y1<size2R && z0>=0 && z1<size3R){
            d000 = volR[x0+y0*size1R+z0*skip2];
            d100 = volR[x1+y0*size1R+z0*skip2];
            d010 = volR[x0+y1*size1R+z0*skip2];
            d110 = volR[x1+y1*size1R+z0*skip2];
            d011 = volR[x0+y1*size1R+z1*skip2];
            d111 = volR[x1+y1*size1R+z1*skip2];
            d001 = volR[x0+y0*size1R+z1*skip2];
            d101 = volR[x1+y0*size1R+z1*skip2];
            /* take weighted mean. */
            /* To save a few ops, we use l+w*(h-l), which is equivalent to (w*h)+((1-w)*l) */
            dx00 = d000 + wx*(d100-d000);
            dx01 = d001 + wx*(d101-d001);
            dx10 = d010 + wx*(d110-d010);
            dx11 = d011 + wx*(d111-d011);
            dxy0 = dx00 + wy*(dx10-dx00);
            dxy1 = dx01 + wy*(dx11-dx01);
            f[i] = (float)(dxy0 + wz*(dxy1-dxy0));
        }else{
            f[i] = badvalR;
        }
    }
}


/* #define output plhs[0]; */

void mexFunction(int nlhs,   /* number of arguments on lhs */
		 mxArray	*plhs[],   /* Matrices on lhs      */
		 int nrhs,	   /* no. of mat on rhs    */
		 const mxArray	*prhs[]    /* Matrices on rhs      */
		 )
{
  int i;
  int n;
  unsigned char *vol, badVal;
  float *volF, badValF;
  double *tmpDbl;
  const int *dims;
  double *xformParams;
  
  mexAtExit(cleanUpMex);
    
  /* Check input args */

  if (nrhs==0) { /* help */
   printf("mrAnatFastInterp3(volume,samp,xformParams)\n");
   printf("\n  volume: uint8 or single-precision image volume\n");
   printf("  samp:  data points to interpolate (Nx3)\n");
   printf("  xformParams (optional): 1x15 parameter Rohde coordiante tranformation params.\n");
   printf("     0-2 translations, 3-5 Euler angle rotations, 6-14 warp params, 15 phase-encode direction (1, 2 or 3).\n");
   return;
  }
  if(nrhs < 2) mexErrMsgTxt("mrAnatFastInterp3.c needs at least two arguments.");
  if(!mxIsEmpty(prhs[0]) && ((!mxIsClass(prhs[0],"uint8") && !mxIsClass(prhs[0],"single")) || mxGetNumberOfDimensions(prhs[0])!=3))
     mexErrMsgTxt("Arg 1 must be a uint8 or single XxYxZ array or empty.");
  if(!mxIsEmpty(prhs[1]) && (!mxIsDouble(prhs[1]) || mxIsComplex(prhs[1]) || mxGetNumberOfDimensions(prhs[1]) != 2 || mxGetM(prhs[1])!=3))
     mexErrMsgTxt("Arg 2 must be a *real* *3xN*  *double* array of sample points or empty.");
  if (nrhs>=3) {
     if(!mxIsEmpty(prhs[2]) && (!mxIsDouble(prhs[2]) || mxIsComplex(prhs[2]) || mxGetNumberOfElements(prhs[2])!=15))
        mexErrMsgTxt("Arg 3 must be a *real* *1x15*  *double* array of Rohde tranform params.");  
     xformParams = (double *)mxGetPr(prhs[2]);
  }else{
     xformParams = NULL;
  }
  
  /* Check to see if we should reinitialze our data/coords cache */
  if(mxIsEmpty(prhs[0])&&curVol.dataPtr==NULL)
    mexErrMsgTxt("Arg 1 is empty, but I have no stored data- please reinitialize.");
  if(!mxIsEmpty(prhs[0])){
    n = mxGetNumberOfElements(prhs[0]);
    dims = mxGetDimensions(prhs[0]);
    curVol.dim1 = (int)dims[0];
    curVol.dim2 = (int)dims[1];
    curVol.dim3 = (int)dims[2];
    if(mxIsClass(prhs[0],"uint8")){
      vol = (unsigned char *)mxGetPr(prhs[0]);
      if(vol==NULL) mexErrMsgTxt("mrAnatFastInterp3: null ptr for input matrix 1.");
      n = mxGetNumberOfElements(prhs[0]);
      dims = mxGetDimensions(prhs[0]);
      curVol.dataPtr = (unsigned char *)myrealloc(curVol.dataPtr, n*sizeof(unsigned char));
      for(i=0;i<n;i++) curVol.dataPtr[i] = vol[i];
    }else{
      volF = (float *)mxGetPr(prhs[0]);
      if(volF==NULL) mexErrMsgTxt("mrAnatFastInterp3: null ptr for input matrix 1.");
      n = mxGetNumberOfElements(prhs[0]);
      dims = mxGetDimensions(prhs[0]);
      curVol.dataPtrF = (float *)myrealloc((unsigned char *)curVol.dataPtrF, n*sizeof(float));
      for(i=0;i<n;i++) curVol.dataPtrF[i] = volF[i];
    }
  }
  if(mxIsEmpty(prhs[1])&&curCoords.coordPtr==NULL)
    mexErrMsgTxt("Arg 2  is empty, but I have no stored coordinates- please reinitialize.");
  if(!mxIsEmpty(prhs[1])){
    tmpDbl = (double *)mxGetPr(prhs[1]);
    if(tmpDbl==NULL) mexErrMsgTxt("mrAnatFastInterp3: null ptr for input matrix 2.");
    curCoords.nCoords = mxGetN(prhs[1]);
    n = curCoords.nCoords*3;
    curCoords.coordPtr = (double *)myrealloc((unsigned char *)curCoords.coordPtr, n*sizeof(double));
    for(i=0;i<n;i++) curCoords.coordPtr[i] = tmpDbl[i];
  }

  if(mxIsClass(prhs[0],"uint8")){
  	if(nrhs==4) badVal=(unsigned char)mxGetScalar(prhs[3]); else badVal=0;
    plhs[0] = mxCreateNumericMatrix(1,curCoords.nCoords,mxUINT8_CLASS,mxREAL);
    vol = (unsigned char *)mxGetPr(plhs[0]);
    fastInterp3(&curVol, &curCoords, vol, badVal, xformParams);
  }else{
    if(nrhs==4) badValF=(float)mxGetScalar(prhs[3]); else badValF=0;
    plhs[0] = mxCreateNumericMatrix(1,curCoords.nCoords,mxSINGLE_CLASS,mxREAL);
    volF = (float *)mxGetPr(plhs[0]);
    fastInterp3F(&curVol, &curCoords, volF, badValF, xformParams);
  }

}
