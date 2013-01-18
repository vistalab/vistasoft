/*  Matlab MEX file.


*/

/* #define Storage */
/* #define CAP */
/* #include "machine.h" */
/* #include "debug.h" */

#include "mex.h"
#include <stdio.h>
#include <ctype.h>
#include <math.h>
#include <sys/types.h>

void myCinterp3(double *vol,int nslice,int size1,int size2,int npts,
            double *x, double *f,double badval)
	    
{
   register int  i, saglen,index;
   double wa,wb,wc;
   double a,b,c;

   saglen=size1*size2;

   for (i=0;i<npts;i++) {
     wa=modf(*(x+i),&a);a--;
     wb=modf(*(x+npts+i),&b);b--;
     wc=modf(*(x+2*npts+i),&c);c--;   

   if (a<0 || a>=size2-1 || 
	 b<0 || b>=size1-1 ||
         c<0 || c>=nslice-1 ) f[i]=badval;
     else { 
      
     index=c*saglen+a*size1+b;


       f[i]=(1-wc)*   ( (1-wb)* ( (1-wa)*(*(vol+index)) 
                                 + wa *(*(vol+index+1)) )
                     +  wb  * ( (1-wa)*(*(vol+index+size1))
                                 + wa *(*(vol+index+size1+1)) ) )
           +  wc  * ( (1-wb)* ( (1-wa)*(*(vol+index+saglen)) 
                                 + wa *(*(vol+index+saglen+1)) ) 
                     +  wb  * ( (1-wa)*(*(vol+index+saglen+size1))
                                 + wa *(*(vol+index+saglen+size1+1)) ) ); 


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
  int npts = 0;
  double *vol,*nslice,*size1,*size2,*x,*f,badval;
  double *sagSize;

  /* Check for proper number of arguments */

  if (nrhs==0) { /* help */
   printf("myCinterp3(volume,sagSize,numSlices,samp,badval)\n");
   printf("\n  volume: volume anatomy data with size 1xprod(sagSize)*numSlices\n");
   printf("  sagSize: size of sagittal anatomy slices\n");
   printf("  numSlices: number of sagittal anatomy slices\n");
   printf("  samp:  data points to interpolate with size prod(sagSize)x3\n");
   printf("  badval (optional): returned for points outside anatomy cube.  0.0 is default\n");
   
   
 }
 
  else {
    if (nrhs < 4) {
      mexErrMsgTxt("myInterp3.c needs at least four arguments.");
  }
  if( (x = mxGetPr(prhs[0])) == NULL) {
    mexErrMsgTxt("myCinterp3: null ptr for input matrix.");
  }
    
  /* Call our routine to read the cap stuff */
  vol=mxGetPr(prhs[0]);
  sagSize=mxGetPr(prhs[1]);
  nslice=mxGetPr(prhs[2]);
  x=mxGetPr(prhs[3]);
  npts=mxGetM(prhs[3]);
  if (nrhs==5) {
    badval=*mxGetPr(prhs[4]);
  }
  else {
    badval=0.0;
  }

  plhs[0] = mxCreateDoubleMatrix(1,npts,mxREAL);

  f = mxGetPr(plhs[0]);

  myCinterp3(vol,(int) *nslice,(int) *sagSize,(int) *(sagSize+1),npts,x,f,badval);
  }      

}
