/*
 *
 * initInvDiagsInC.c
 *
 * (c) 2002 Stefan Wirtz
 *
 */

#include "mex.h"
#include "matrix.h"
#include <math.h>

#define invD(l,k,j,p) invD[j+n1*(k+n2*(l+n3*p))]


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]){
  /* 
     Aufruf: D = initDiagsInC(lambda,mu,n1,n2,n3);
     
     Rueckgabe ist eine 4-D Matrix der Groesse n1 x n2 x n3 x 6,
     wobei D(:,:,:,1) = D11,
           D(:,:,:,2) = D12,
	   D(:,:,:,3) = D13,
	   D(:,:,:,4) = D22,
	   D(:,:,:,5) = D23,
	   D(:,:,:,6) = D33.
     D21=D12, D31=D13, D32=D23 und muessen daher nicht zusaetzlich
     berechnet und im Speicher behalten werden.
  */

  const double pi=acos(0)*2;
  double lambda,mu;
  int* dims;
  int n1,n2,n3,j,k,l;
  double *invD;
  double cj,ck,cl,sj,sk,sl,aj,ak,al;
  double d11,d12,d13,d22,d23,d33;
  double detD;
  double lp2m, mlpm, m2lp4m;

  if(nrhs!=5) 
    mexErrMsgTxt("Five inputs required!");

  dims = (int*)mxMalloc(4 * sizeof(int));

  lambda = mxGetScalar(prhs[0]);
  mu     = mxGetScalar(prhs[1]);

  lp2m   = lambda + 2*mu;
  mlpm   = -(lambda + mu);
  m2lp4m = -2*(lambda + 4*mu);

  n1 = dims[0] = (int)mxGetScalar(prhs[2]);
  n2 = dims[1] = (int)mxGetScalar(prhs[3]);
  n3 = dims[2] = (int)mxGetScalar(prhs[4]);
  dims[3] = 6;

  plhs[0] = mxCreateNumericArray(4, dims, mxDOUBLE_CLASS, mxREAL);
  invD = mxGetPr(plhs[0]);
  
  for (l=0;l<n3;l++){
    for (k=0;k<n2;k++){
      for (j=0;j<n1;j++){
	aj = 2*pi*j/n1;
	ak = 2*pi*k/n2;
	al = 2*pi*l/n3;
	
	cj = 2*cos(aj);
	ck = 2*cos(ak);
	cl = 2*cos(al);

	sj = sin(aj);
	sk = sin(ak);
	sl = sin(al);
	
	d11 = m2lp4m + lp2m*cj + mu*(ck + cl); 
	d12 = mlpm * sj * sk;                  
	d13 = mlpm * sj * sl;                  
	d22 = m2lp4m + lp2m*cl + mu*(cj + ck); 
	d23 = mlpm * sk * sl;                  
	d33 = m2lp4m + lp2m*ck + mu*(cj + cl); 

	

	/* Determinante ausrechnen */
	detD = d11*d22*d33 - d11*d23*d23 - d12*d12*d33 + d12*d13*d23 + d12*d13*d23 - d13*d13*d22;

	if (fabs(detD) < 1e-15){
	  /* dann ist die Inverse Null */
	  invD(l,k,j,0) = 0;
	  invD(l,k,j,1) = 0;
	  invD(l,k,j,2) = 0;
	  invD(l,k,j,3) = 0;
	  invD(l,k,j,4) = 0;
	  invD(l,k,j,5) = 0;
	} 
	else{
	  /*
	    %        ( D11 D12 D13 )^-1             ( H11 H12 H13 )
	    % D^-1 = ( D12 D22 D23 )     = 1/det(D) ( H12 H22 H23 )
	    %        ( D13 D23 D33 )                ( H13 H23 H33 )
	    % mit Hilfsvariablen Hij, i,j=1,2,3
	    % H11 = D22 * D33 - D23 * D32  =  D22 * D33 - D23 * D23;
	    % H12 = D13 * D32 - D12 * D33  =  D13 * D23 - D12 * D33;
	    % H13 = D12 * D23 - D13 * D22  =  D12 * D23 - D13 * D22;
	    % H22 = D11 * D33 - D13 * D31  =  D11 * D33 - D13 * D13;
	    % H23 = D13 * D21 - D11 * D23  =  D12 * D13 - D11 * D23;
	    % H33 = D11 * D22 - D12 * D21  =  D11 * D22 - D12 * D12;
	  */

	  invD(l,k,j,0) = ( d22 * d33 - d23 * d23 ) / detD;
	  invD(l,k,j,1) = ( d13 * d23 - d12 * d33 ) / detD;
	  invD(l,k,j,2) = ( d12 * d23 - d13 * d22 ) / detD;
	  invD(l,k,j,3) = ( d11 * d33 - d13 * d13 ) / detD;
	  invD(l,k,j,4) = ( d12 * d13 - d11 * d23 ) / detD;
	  invD(l,k,j,5) = ( d11 * d22 - d12 * d12 ) / detD;
	} 	
      }
    }
  }

} /* end mexFunction */
