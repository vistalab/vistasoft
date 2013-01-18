/*
 * Compute joint histogram for two uint8 image volumes. Parts of this code
 * were copied from SPM5's 'spm_hist2.c'. I added the Rohde eddy-cuurent coordinate
 * transform. I also added some performance enhancements, like the data caching
 * and loop optimization.
 *
 * The version of spm_hist2.c: "2005-10-04 17:20:34Z guillaume"
 * 
 *
 * HISTORY:
 *
 * 2005.10.04: Original spm version, written by "Guillaume" (?)
 * 2007.05.11: RFD: added Rohde transform and data cache.
 */

#include <math.h>
#include "mex.h"

typedef struct
{
  unsigned char *dataPtr;     /* Pointer to data. */
  int dim1;            	/* dimensions */
  int dim2;
  int dim3;
} volume;

/* Globals for the current volume and coords */
volume srcVol;
volume trgVol;

/*
 * Simple wrapper for memory allocation.
 */
void *myrealloc(unsigned char *ptr, int newSize){
  ptr = realloc(ptr,newSize);
  if(ptr==NULL && newSize>0)
    mexErrMsgTxt("Internal out of memory!");
  return ptr;
}

/*
 * Called when matlab decides to unload this mex file 
 */
void cleanUpMex(void){
  if(srcVol.dataPtr!=NULL)
    free(srcVol.dataPtr);
  if(trgVol.dataPtr!=NULL)
    free(trgVol.dataPtr);
}


float samp(const int d[3], unsigned char f[], float x, float y, float z){
  int ix, iy, iz;
  float dx1, dy1, dz1, dx2, dy2, dz2;
  int k111,k112,k121,k122,k211,k212,k221,k222;
  float vf;
  unsigned char *ff;

  ix = floor(x); dx1=x-ix; dx2=1.0-dx1;
  iy = floor(y); dy1=y-iy; dy2=1.0-dy1;
  iz = floor(z); dz1=z-iz; dz2=1.0-dz1;

  ff   = f + ix-1+d[0]*(iy-1+d[1]*(iz-1));
  k222 = ff[   0]; k122 = ff[     1];
  k212 = ff[d[0]]; k112 = ff[d[0]+1];
  ff  += d[0]*d[1];
  k221 = ff[   0]; k121 = ff[     1];
  k211 = ff[d[0]]; k111 = ff[d[0]+1];

  vf = (((k222*dx2+k122*dx1)*dy2       +
	 (k212*dx2+k112*dx1)*dy1))*dz2 +
    (((k221*dx2+k121*dx1)*dy2       +
      (k211*dx2+k111*dx1)*dy1))*dz1;
  return(vf);
}

void hist2(float xform[15], volume* trgVol, volume* srcVol, double H[65536], float s[3]){

  static float ran[] = {0.656619,0.891183,0.488144,0.992646,0.373326,0.531378,0.181316,0.501944,0.422195,
			0.660427,0.673653,0.95733,0.191866,0.111216,0.565054,0.969166,0.0237439,0.870216,
			0.0268766,0.519529,0.192291,0.715689,0.250673,0.933865,0.137189,0.521622,0.895202,
			0.942387,0.335083,0.437364,0.471156,0.14931,0.135864,0.532498,0.725789,0.398703,
			0.358419,0.285279,0.868635,0.626413,0.241172,0.978082,0.640501,0.229849,0.681335,
			0.665823,0.134718,0.0224933,0.262199,0.116515,0.0693182,0.85293,0.180331,0.0324186,
			0.733926,0.536517,0.27603,0.368458,0.0128863,0.889206,0.866021,0.254247,0.569481,
			0.159265,0.594364,0.3311,0.658613,0.863634,0.567623,0.980481,0.791832,0.152594,
			0.833027,0.191863,0.638987,0.669,0.772088,0.379818,0.441585,0.48306,0.608106,
			0.175996,0.00202556,0.790224,0.513609,0.213229,0.10345,0.157337,0.407515,0.407757,
			0.0526927,0.941815,0.149972,0.384374,0.311059,0.168534,0.896648};
  int iran=0;
  float x, y, z, rx, ry, rz, xp, yp, zp;
  float rot[9], *r, *t, *c, b_eddy, ySq, xSq;
  int phaseDir;
  unsigned char *g = trgVol->dataPtr;
  unsigned char *f = srcVol->dataPtr;
  int dg[3];
  int df[3];
  float vf;
  int   ivf, ivg;
  
  dg[0] = trgVol->dim1; dg[1] = trgVol->dim2; dg[2] = trgVol->dim3;
  df[0] = srcVol->dim1; df[1] = srcVol->dim2; df[2] = srcVol->dim3;
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
  /*printf("rot=[ "); int i;for(i=0;i<9;i++){printf("%0.4f ",rot[i]);}printf(" ]\n");*/
  /*printf("trans=[ %0.4f %0.4f %0.4f ]\n",t[0],t[1],t[2]);*/
  /*printf("dg=[%d %d %d]; df=[%d %d %d]; s=[%f %f %f];\n",dg[0],dg[1],dg[2],df[0],df[1],df[2],s[0],s[1],s[2]);*/

  for(z=1.0; z<dg[2]-s[2]; z+=s[2]){
    for(y=1.0; y<dg[1]-s[1]; y+=s[1]){
      for(x=1.0; x<dg[0]-s[0]; x+=s[0]){
	rx  = x + ran[iran = (iran+1)%97]*s[0];
	ry  = y + ran[iran = (iran+1)%97]*s[1];
	rz  = z + ran[iran = (iran+1)%97]*s[2];
	/* Apply coordinate transform */
	/* rotation & translation*/
	xp = rx*rot[0]+ry*rot[1]+rz*rot[2] + t[0];
	yp = rx*rot[3]+ry*rot[4]+rz*rot[5] + t[1];
	zp = rx*rot[6]+ry*rot[7]+rz*rot[8] + t[2];
	if(phaseDir>0&&phaseDir<4){
	  /* warping */
	  xSq = xp*xp;
	  ySq = yp*yp;
	  b_eddy = c[0]*xp + c[1]*yp + c[2]*zp + c[3]*xp*yp + c[4]*xp*zp + c[5]*yp*zp + c[6]*(xSq-ySq) + c[7]*(zp*zp*2-xSq-ySq);
	  if(phaseDir==1) xp = xp-b_eddy;
	  else if(phaseDir==3) zp = zp-b_eddy;
	  else yp = yp-b_eddy;
	}
	/* xp  = M[0]*rx + M[4]*ry + M[ 8]*rz + M[12]; */
	/* yp  = M[1]*rx + M[5]*ry + M[ 9]*rz + M[13]; */
	/* zp  = M[2]*rx + M[6]*ry + M[10]*rz + M[14]; */

	if (zp>=1.0 && zp<df[2] && yp>=1.0 && yp<df[1] && xp>=1.0 && xp<df[0]){
	  vf  = samp(df, f, xp,yp,zp);
	  ivf = floor(vf);
	  ivg = floor(samp(dg, g, rx,ry,rz)+0.5);
	  H[ivf+ivg*256] += (1-(vf-ivf));
	  if (ivf<255)
	    H[ivf+1+ivg*256] += (vf-ivf);

	  /*
	    float vf, vg;
	    int ivf, ivg;
	    vg  = samp(dg, g, rx,ry,rz);
	    vf  = samp(df, f, xp,yp,zp);
	    ivg = floor(vg);
	    ivf = floor(vf);
	    H[ivf+ivg*256] += (1-(vf-ivf))*(1-(vg-ivg));
	    if (ivf<255)
	    H[ivf+1+ivg*256] += (vf-ivf)*(1-(vg-ivg));
	    if (ivg<255)
	    {
	    H[ivf+(ivg+1)*256] += (1-(vf-ivf))*(vg-ivg);
	    if (ivf<255)
	    H[ivf+1+(ivg+1)*256] += (vf-ivf)*(vg-ivg);
	    }
	  */
	}
      }
    }
  }
}


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  const int *dims;
  register int i, n;
  float s[3], xformParams[15];
  unsigned char *vol;

  mexAtExit(cleanUpMex);

  if (nrhs==0) { /* help */
    printf("dtiJointHist(trgVol, srcVol, xformParams, sampDensity)\n");
    printf("\n  trgVol, srcVol: uint8 image volumes\n");
    printf("  xformParams: 1x15 parameter Rohde coordiante tranformation params.\n");
    printf("     0-2 translations, 3-5 Euler angle rotations, 6-14 warp params, 15 phase-encode direction (1, 2 or 3).\n");
    printf("     This transforms trgVol coords into srcVol coords.\n");
    printf("  sampDensity:  vol sample density for each dim (1x3)\n");
    return;
  }
  if(nrhs>4 || nrhs<3 || nlhs>1) mexErrMsgTxt("dtiJointHist needs 3 or 4 arguments.");
  if(!mxIsEmpty(prhs[0]) && (!mxIsClass(prhs[0],"uint8") || mxGetNumberOfDimensions(prhs[0])!=3))
    mexErrMsgTxt("Arg 1 must be a uint8 XxYxZ array or empty.");
  if(!mxIsEmpty(prhs[1]) && (!mxIsClass(prhs[1],"uint8") || mxGetNumberOfDimensions(prhs[1])!=3))
    mexErrMsgTxt("Arg 2 must be a uint8 XxYxZ array or empty.");
  if(!mxIsDouble(prhs[2]) || mxIsComplex(prhs[2]) || (mxGetNumberOfElements(prhs[2])!=15 && mxGetNumberOfElements(prhs[2])!=6))
    mexErrMsgTxt("Arg 3 must be a *real* *1x6* or *1x15*  *double* array of tranform params (6 for ridid-body or 14 for Rohde)."); 
  if(mxGetNumberOfElements(prhs[2])==6){
    for(i=0;i<6;i++) xformParams[i] = (float)mxGetPr(prhs[2])[i];
    for(i=6;i<15;i++) xformParams[i] = (float)0.0;
  }else{
    for(i=0;i<15;i++) xformParams[i] = (float)mxGetPr(prhs[2])[i];
  }

  if (nrhs >= 4){
    if (!mxIsNumeric(prhs[3]) || !mxIsDouble(prhs[3]) || mxIsComplex(prhs[3]) ||
	mxGetM(prhs[3])*mxGetN(prhs[3]) != 3)
      mexErrMsgTxt("Invalid sample density.");
    s[0] = (float)mxGetPr(prhs[3])[0];
    s[1] = (float)mxGetPr(prhs[3])[1];
    s[2] = (float)mxGetPr(prhs[3])[2];
  }else{
    s[0] = s[1] = s[2] = 1.0;
  }

  /* Check to see if we should reinitialze our data cache */
  if(mxIsEmpty(prhs[0])&&trgVol.dataPtr==NULL)
    mexErrMsgTxt("Arg 1 is empty, but I have no stored data- please reinitialize.");
  if(!mxIsEmpty(prhs[0])){
    vol = (unsigned char *)mxGetPr(prhs[0]);
    if(vol==NULL) mexErrMsgTxt("dtiJointHist: null ptr for input matrix 1.");
    n = mxGetNumberOfElements(prhs[0]);
    dims = mxGetDimensions(prhs[0]);
    trgVol.dataPtr = (unsigned char *)myrealloc(trgVol.dataPtr, n*sizeof(unsigned char));
    for(i=0;i<n;i++) trgVol.dataPtr[i] = vol[i];
    trgVol.dim1 = (int)dims[0];
    trgVol.dim2 = (int)dims[1];
    trgVol.dim3 = (int)dims[2];
  }
  if(mxIsEmpty(prhs[1])&&srcVol.dataPtr==NULL)
    mexErrMsgTxt("Arg 2 is empty, but I have no stored data- please reinitialize.");
  if(!mxIsEmpty(prhs[1])){
    vol = (unsigned char *)mxGetPr(prhs[1]);
    if(vol==NULL) mexErrMsgTxt("dtiJointHist: null ptr for input matrix 2.");
    n = mxGetNumberOfElements(prhs[1]);
    dims = mxGetDimensions(prhs[1]);
    srcVol.dataPtr = (unsigned char *)myrealloc(srcVol.dataPtr, n*sizeof(unsigned char));
    for(i=0;i<n;i++) srcVol.dataPtr[i] = vol[i];
    srcVol.dim1 = (int)dims[0];
    srcVol.dim2 = (int)dims[1];
    srcVol.dim3 = (int)dims[2];
  }
  plhs[0] = mxCreateDoubleMatrix(256,256,mxREAL);

  hist2(xformParams, &trgVol, &srcVol, mxGetPr(plhs[0]), s);

}


