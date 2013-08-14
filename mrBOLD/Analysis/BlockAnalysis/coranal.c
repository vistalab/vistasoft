#include <stdio.h>
	#include <math.h>
	#include "mex.h"
	
	void ftrans(int n, double *ptTseries, double w, double *Xr, double *Xi, double *c, double *s)
	{
	  int i;
	  double mean,ssq;
	
	  mean=0.0;
	  for(i=0;i<n;i++)
	    mean+=ptTseries[i];
	  mean/=n;
	
	  *Xr=0.0; *Xi=0.0;
	  for(i=0;i<n;i++)
	    {
	      *Xr+=(ptTseries[i]-mean)*c[i];
	      *Xi+=(ptTseries[i]-mean)*s[i];
	    }
	
	  ssq=0.0;
	  for(i=0;i<n;i++)
	    ssq+=(ptTseries[i]-mean)*(ptTseries[i]-mean);
	
	  *Xr/=((double)n)*sqrt(ssq);
	  *Xi/=((double)n)*sqrt(ssq);
	}
	
	void mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[])
	{
	  double *OUTr, *OUTi, *data, *w, *c, *s;
	  int m,n,i,j,k;
	  char mode[2]; /* 2 because mxGetString appends a NULL character to terminate string */
	
	  if(nrhs!=2)
	    mexErrMsgTxt("Two input arguments required!");
	  if(nlhs<1)
	    mexErrMsgTxt("At least one output argument required");
	
	  for(i=0;i<2;i++)
	    if(mxIsEmpty(prhs[i])) mexErrMsgTxt("Input arguments must be nonempty.");
	
	  m=mxGetM(prhs[0]);
	  n=mxGetN(prhs[0]);
	
	  if(mxIsDouble(prhs[0]))
	    data=mxGetPr(prhs[0]);
	  else
	    mexErrMsgTxt("Input must be of type double.");
	
	
	  if((k=mxGetM(prhs[1]))==1)
	    k=mxGetN(prhs[1]);
	
	  w=mxGetPr(prhs[1]);
	
	  plhs[0]=mxCreateDoubleMatrix(n,k,mxCOMPLEX);
	  if(plhs[0]==NULL)
	    mexErrMsgTxt("Allocation of output array failed. Out of memory.");
	 
	  OUTr=mxGetPr(plhs[0]);
	  OUTi=mxGetPi(plhs[0]);
	
	  if((c=mxCalloc(m,sizeof(double)))==NULL)
	    mexErrMsgTxt("Out of memory.");
	  if((s=mxCalloc(m,sizeof(double)))==NULL)
	    mexErrMsgTxt("Out of memory.");
	
	  for(j=0;j<k;j++) {
	    for(i=0;i<m;i++) {
	      c[i]=cos(w[j]*(double)i); s[i]=sin(w[j]*(double)i);
	    }
	    for(i=0;i<n;i++)
	      ftrans(m,&data[i*m],w[j],&OUTr[j*n+i],&OUTi[j*n+i],c,s);
	  }
	}
