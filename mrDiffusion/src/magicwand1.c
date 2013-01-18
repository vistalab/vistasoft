/*******************************************************************************/
/*                                                                             */
/* MAGICWAND						                                                       */
/*	Given an image and a pixel cooridinate, this function isolates all         */
/*	neighboring pixels with values within a preset tolerance. This function    */
/*  mimics the behavoir of Adobe's Photoshop magic wand tool.                  */
/*                                                                             */
/* Synopsis:                                                                   */
/*	Y=magicwand(X, m, n);                                                      */
/*		Y=output image of type uint8(logical)			                               */
/*		X=input image of type double				                                     */
/*		m=pixel cooridinate(row)				                                         */
/*		n=pixel cooridinate(col)				                                         */
/*                                                                             */
/*	Y=magicwand(X, m, n, Tol);					                                       */
/*		Tol=Tolerance value for locating pixel neighbors(default=0.01)           */
/*                                                                             */
/*	Y=magicwand(X, m, n, Tol, eight_or_four);			                             */
/*		eight_or_four=string such that if =='eigh', magicwand locates            */
/*		all eight-neighborhood pixels (default=four-neighborhood)                */
/*                                                                             */
/* Daniel Leo Lau                                                              */
/* lau@ece.udel.edu                                                            */
/*                                                                             */
/* Copyright April 7, 1997                                                     */
/*                                                                             */
/*                                                                             */
/* HISTORY:                                                                    */
/*                                                                             */
/* June 30 2003                                                                */
/* ------------                                                                */
/* Adapted to   MATLAB 6.5   (sorry, no backward compatibility)                */
/* Some changes in the main function due to the change in the definition of    */
/* logical variables in v6.5.                                                  */
/*                                                                             */
/* Yoram Tal                                                                   */
/* yoramtal123@yahoo.com                                                       */
/*                                                                             */
/*                                                                             */
/* November 18 2003                                                            */
/* ------------                                                                */
/* Added support for RGB images, fixed support for uint8 inputs.               */
/*                                                                             */
/* To compile under linux, try:                                                */
/*    mex -O COPTIMFLAGS='-O3 -march=i686 -DNDEBUG' magicwand1.c               */
/*                                                                             */
/* Bob Dougherty                                                               */
/* bobd@stanford.edu                                                           */
/*******************************************************************************/

#include <math.h>
#include <string.h>
#include "mex.h"

void rgb2opp(double r, double g, double b, double opp[]){
	/* Convert rgb dac value to relative luminance (assume gamma of 2.1) in range [-.5,+.5]*/
	/* 0.4762 = 1/2.1 */
/* 	r = pow(r, 0.4762) - 0.5; */
/* 	g = pow(g, 0.4762) - 0.5; */
/* 	b = pow(b, 0.4762) - 0.5; */
  /* rgb2lms = [-0.5524   -0.7035   -0.3015
                 0.9662    0.8124   -0.2952
                 0.1176    0.1833    1.0000];
   opp = rgb*rgb2opp;
	*/
/* 	opp[0] = r*-0.5524 + g* 0.9662 + b*0.1176; */
/*  opp[1] = r*-0.7035 + g* 0.8124 + b*0.1833; */
/* 	opp[2] = r*-0.3015 + g*-0.2952 + b; */

	opp[0] = r; opp[1] = g; opp[2] = b;
}

/*******************************************************************************/
/*                                                                             */
/* MAGICWAND: performs the search of all neighboring pixels to the top, left,  */
/*	      bottom, and right of pixel(m,n). This one assumes greyscale input    */	
/*                                                                             */
/*******************************************************************************/
void magic_wand(unsigned char Y[], double X[], int M, int N, int m, int n, double Tol)
{
	int r,s,t, *pixel_list_M, *pixel_list_N, length_pixel_list;
	int first_previous_iteration, last_previous_iteration, next_available_slot;
    double fixed_level;

	length_pixel_list = M*N;
	pixel_list_M = (int*)mxCalloc(length_pixel_list, sizeof(int));
	pixel_list_N = (int*)mxCalloc(length_pixel_list, sizeof(int));
	Y[m+n*M] = 1;

	pixel_list_M[0] = m;
	pixel_list_N[0] = n;
	first_previous_iteration = 0;
	last_previous_iteration = 0;
	next_available_slot = 1;
    fixed_level = X[m+n*M];
	while(1){
		for (r=first_previous_iteration; r<=last_previous_iteration; r++){
			s=pixel_list_M[r]-1; t=pixel_list_N[r];
			if (s>=0 && Y[s+t*M]!=1 && (fabs(fixed_level-X[s+t*M])<=Tol)){
				pixel_list_M[next_available_slot]=s;
				pixel_list_N[next_available_slot]=t;
				Y[s+t*M]=1;
				next_available_slot++;
				if (next_available_slot==length_pixel_list) break;
			}
			s=pixel_list_M[r]; t=pixel_list_N[r]-1;
			if (t>=0 && Y[s+t*M]!=1 && fabs(fixed_level-X[s+t*M])<=Tol){
				pixel_list_M[next_available_slot]=s;
				pixel_list_N[next_available_slot]=t;
				Y[s+t*M]=1;
				next_available_slot++;
				if (next_available_slot==length_pixel_list) break;
			}
			s=pixel_list_M[r]+1; t=pixel_list_N[r];
			if (s<M && Y[s+t*M]!=1 && fabs(fixed_level-X[s+t*M])<=Tol){
				pixel_list_M[next_available_slot]=s;
				pixel_list_N[next_available_slot]=t;
				Y[s+t*M]=1;
				next_available_slot++;
				if (next_available_slot==length_pixel_list) break;
			}
			s=pixel_list_M[r]; t=pixel_list_N[r]+1;
			if (t<N && Y[s+t*M]!=1 && fabs(fixed_level-X[s+t*M])<=Tol){
				pixel_list_M[next_available_slot]=s;
				pixel_list_N[next_available_slot]=t;
				Y[s+t*M]=1;
				next_available_slot++;
				if (next_available_slot==length_pixel_list) break;
			}

		}
		if (next_available_slot==length_pixel_list) break;
		if (last_previous_iteration==next_available_slot-1) break;
		first_previous_iteration=last_previous_iteration+1;
		last_previous_iteration=next_available_slot-1;
	}
	mxFree(pixel_list_M);
	mxFree(pixel_list_N);
	return;
}

/*******************************************************************************/
/*                                                                             */
/* MAGICWAND: performs the search of all neighboring pixels to the top, left,  */
/*	      bottom, and right of pixel(m,n). This one assumes RGB input.         */	
/*                                                                             */
/*******************************************************************************/
void magic_wand_rgb(unsigned char Y[], double X[], int M, int N, int m, int n, double Tol)
{
	int r,s,t, *pixel_list_M, *pixel_list_N, length_pixel_list;
	int first_previous_iteration, last_previous_iteration, next_available_slot;
	double pixDiff;
	double tmpRgb[3];
	double seedRgb[3]; /*{X[m+n*M], X[s+t*M+N*M], X[s+t*M+2*N*M]};*/
	int gOffset;
	int bOffset;
    
	length_pixel_list = M*N;
	pixel_list_M = (int*)mxCalloc(length_pixel_list, sizeof(int));
	pixel_list_N = (int*)mxCalloc(length_pixel_list, sizeof(int));
	Y[m+n*M] = 1;

	pixel_list_M[0] = m;
	pixel_list_N[0] = n;
	first_previous_iteration = 0;
	last_previous_iteration = 0;
	next_available_slot = 1;

    gOffset = length_pixel_list;
	bOffset = 2*length_pixel_list;
	rgb2opp(X[m+n*M], X[m+n*M+gOffset], X[m+n*M+bOffset], seedRgb);
/* 	mexPrintf("rgb = [%f %f %f]", X[m+n*M], X[m+n*M+gOffset], X[m+n*M+bOffset]);  */
/* 	mexErrMsgTxt("exiting"); */
	while(1){
		for(r=first_previous_iteration; r<=last_previous_iteration; r++){
			s = pixel_list_M[r]-1; t = pixel_list_N[r];
			if(s>=0 && Y[s+t*M]!=1){
				rgb2opp(X[s+t*M], X[s+t*M+gOffset], X[s+t*M+bOffset], tmpRgb);
				pixDiff = (fabs(seedRgb[0]-tmpRgb[0])+fabs(seedRgb[1]-tmpRgb[1])+fabs(seedRgb[2]-tmpRgb[2]))/3;
				if(pixDiff<=Tol){
					pixel_list_M[next_available_slot]=s;
					pixel_list_N[next_available_slot]=t;
					Y[s+t*M]=1;
					next_available_slot++;
					if (next_available_slot==length_pixel_list) break;
				}
			}
			s = pixel_list_M[r]; t = pixel_list_N[r]-1;
			if(t>=0 && Y[s+t*M]!=1){
				rgb2opp(X[s+t*M], X[s+t*M+gOffset], X[s+t*M+bOffset], tmpRgb);
				pixDiff = (fabs(seedRgb[0]-tmpRgb[0])+fabs(seedRgb[1]-tmpRgb[1])+fabs(seedRgb[2]-tmpRgb[2]))/3;
				if(pixDiff<=Tol){
					pixel_list_M[next_available_slot]=s;
					pixel_list_N[next_available_slot]=t;
					Y[s+t*M]=1;
					next_available_slot++;
					if (next_available_slot==length_pixel_list) break;
				}
			}
			s=pixel_list_M[r]+1; t=pixel_list_N[r];
			if(s<M && Y[s+t*M]!=1){
				rgb2opp(X[s+t*M], X[s+t*M+gOffset], X[s+t*M+bOffset], tmpRgb);
				pixDiff = (fabs(seedRgb[0]-tmpRgb[0])+fabs(seedRgb[1]-tmpRgb[1])+fabs(seedRgb[2]-tmpRgb[2]))/3;
				if(pixDiff<=Tol){
					pixel_list_M[next_available_slot]=s;
					pixel_list_N[next_available_slot]=t;
					Y[s+t*M]=1;
					next_available_slot++;
					if (next_available_slot==length_pixel_list) break;
				}
			}
			s=pixel_list_M[r]; t=pixel_list_N[r]+1;
			if(t<N && Y[s+t*M]!=1){
				rgb2opp(X[s+t*M], X[s+t*M+gOffset], X[s+t*M+bOffset], tmpRgb);
				pixDiff = (fabs(seedRgb[0]-tmpRgb[0])+fabs(seedRgb[1]-tmpRgb[1])+fabs(seedRgb[2]-tmpRgb[2]))/3;
				if(pixDiff<=Tol){
					pixel_list_M[next_available_slot]=s;
					pixel_list_N[next_available_slot]=t;
					Y[s+t*M]=1;
					next_available_slot++;
					if (next_available_slot==length_pixel_list) break;
				}
			}

		}
		if (next_available_slot==length_pixel_list) break;
		if (last_previous_iteration==next_available_slot-1) break;
		first_previous_iteration=last_previous_iteration+1;
		last_previous_iteration=next_available_slot-1;
	}
	mxFree(pixel_list_M);
	mxFree(pixel_list_N);
	return;
}

/*******************************************************************************/
/*                                                                             */
/* MAGICWAND8: performs the search of all neighboring pixels to the top, left, */
/*	      bottom, right, and diagonals of pixel(m,n). C is the number of color */
/*        planes (1 or 3).                                                     */		 
/*                                                                             */
/*******************************************************************************/
void magic_wand_8(unsigned char Y[], double X[], int M, int N, int m, int n, double Tol)
{
	int r,s,t, *pixel_list_M, *pixel_list_N, length_pixel_list;
	int first_previous_iteration, last_previous_iteration, next_available_slot;
	double fixed_level;

	mexPrintf("MAGIC WAND *\n");
	length_pixel_list=M*N;
	fixed_level=X[m+n*M];
	pixel_list_M=(int*)mxCalloc(length_pixel_list, sizeof(int));
	pixel_list_N=(int*)mxCalloc(length_pixel_list, sizeof(int));
	Y[m+n*M]=1;

	pixel_list_M[0]=m;
	pixel_list_N[0]=n;
	first_previous_iteration=0;
	last_previous_iteration=0;
	next_available_slot=1;
	while(1){
		for (r=first_previous_iteration; r<=last_previous_iteration; r++){
			s=pixel_list_M[r]-1; t=pixel_list_N[r]-1;
			if (s>=0 && t>=0 && Y[s+t*M]!=1 && (fabs(fixed_level-X[s+t*M])<=Tol)){
				pixel_list_M[next_available_slot]=s;
				pixel_list_N[next_available_slot]=t;
				Y[s+t*M]=1;
				next_available_slot++;
				if (next_available_slot==length_pixel_list) break;
			}
			s=pixel_list_M[r]-1; t=pixel_list_N[r];
			if (s>=0 && Y[s+t*M]!=1 && (fabs(fixed_level-X[s+t*M])<=Tol)){
				pixel_list_M[next_available_slot]=s;
				pixel_list_N[next_available_slot]=t;
				Y[s+t*M]=1;
				next_available_slot++;
				if (next_available_slot==length_pixel_list) break;
			}
			s=pixel_list_M[r]-1; t=pixel_list_N[r]+1;
			if (s>=0 && t<N && Y[s+t*M]!=1 && (fabs(fixed_level-X[s+t*M])<=Tol)){
				pixel_list_M[next_available_slot]=s;
				pixel_list_N[next_available_slot]=t;
				Y[s+t*M]=1;
				next_available_slot++;
				if (next_available_slot==length_pixel_list) break;
			}
			s=pixel_list_M[r]; t=pixel_list_N[r]-1;
			if (t>=0 && Y[s+t*M]!=1 && fabs(fixed_level-X[s+t*M])<=Tol){
				pixel_list_M[next_available_slot]=s;
				pixel_list_N[next_available_slot]=t;
				Y[s+t*M]=1;
				next_available_slot++;
				if (next_available_slot==length_pixel_list) break;
			}
			s=pixel_list_M[r]; t=pixel_list_N[r]+1;
			if (t<N && Y[s+t*M]!=1 && fabs(fixed_level-X[s+t*M])<=Tol){
				pixel_list_M[next_available_slot]=s;
				pixel_list_N[next_available_slot]=t;
				Y[s+t*M]=1;
				next_available_slot++;
				if (next_available_slot==length_pixel_list) break;
			}
			s=pixel_list_M[r]+1; t=pixel_list_N[r]-1;
			if (s<M && t>=0 && Y[s+t*M]!=1 && fabs(fixed_level-X[s+t*M])<=Tol){
				pixel_list_M[next_available_slot]=s;
				pixel_list_N[next_available_slot]=t;
				Y[s+t*M]=1;
				next_available_slot++;
				if (next_available_slot==length_pixel_list) break;
			}
			s=pixel_list_M[r]+1; t=pixel_list_N[r];
			if (s<M && Y[s+t*M]!=1 && fabs(fixed_level-X[s+t*M])<=Tol){
				pixel_list_M[next_available_slot]=s;
				pixel_list_N[next_available_slot]=t;
				Y[s+t*M]=1;
				next_available_slot++;
				if (next_available_slot==length_pixel_list) break;
			}
			s=pixel_list_M[r]+1; t=pixel_list_N[r]+1;
			if (s<M && t<N && Y[s+t*M]!=1 && fabs(fixed_level-X[s+t*M])<=Tol){
				pixel_list_M[next_available_slot]=s;
				pixel_list_N[next_available_slot]=t;
				Y[s+t*M]=1;
				next_available_slot++;
				if (next_available_slot==length_pixel_list) break;
			}
		}
		if (next_available_slot==length_pixel_list) break;
		if (last_previous_iteration==next_available_slot-1) break;
		first_previous_iteration=last_previous_iteration+1;
		last_previous_iteration=next_available_slot-1;
	}
	mxFree(pixel_list_M);
	mxFree(pixel_list_N);
	return;
}

/*******************************************************************************/
/*                                                                             */
/* MAGICWAND8: performs the search of all neighboring pixels to the top, left, */
/*	      bottom, right, and diagonals of pixel(m,n). C is the number of color */
/*        planes (1 or 3). This one assumes RGB input.                         */		 
/*                                                                             */
/*******************************************************************************/
void magic_wand_8_rgb(unsigned char Y[], double X[], int M, int N, int m, int n, double Tol)
{

}

/*******************************************************************************/
/* mexFUNCTION                                                                 */
/* Gateway routine for use with MATLAB.                                        */
/*******************************************************************************/
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	int M, N, C, m, n, output_dims[2];
	double *input_data, Tol;
	unsigned char *output_data, *int_input_data;
	char neighborhood[5];
    int number_of_dims;
    const int  *dim_array;

	if (nrhs<3 || nrhs>5)
		mexErrMsgTxt("MAGICWAND requires three to five input arguments!");
	else if (nlhs>1)
		mexErrMsgTxt("MAGICWAND returns exactly one output argument!");
	else if (!mxIsNumeric(prhs[0]) ||
					 mxIsComplex(prhs[0]) ||
					 mxIsSparse(prhs[0]))
		mexErrMsgTxt("Input X must be a real matrix!");
	else if (!mxIsNumeric(prhs[1]) ||
					 mxIsComplex(prhs[1]) ||
					 mxIsSparse(prhs[1])  ||
					 !mxIsDouble(prhs[1]))
		mexErrMsgTxt("Input m must be a real scalar of type double!");
	else if (!mxIsNumeric(prhs[2]) ||
					 mxIsComplex(prhs[2]) ||
					 mxIsSparse(prhs[2])  ||
					 !mxIsDouble(prhs[2]))
		mexErrMsgTxt("Input n must be a real scalar of type double!");
	else if (nrhs>3 && !mxIsEmpty(prhs[3]) && (!mxIsNumeric(prhs[3]) ||
			mxIsComplex(prhs[3]) ||
			mxIsSparse(prhs[3])  ||
			!mxIsDouble(prhs[3])))
		mexErrMsgTxt("Input TOL must be a real scalar!");
	else if (nrhs==5 && !mxIsChar(prhs[4]))
		mexErrMsgTxt("Input Neighborhood must be the string 'four' or 'eigh'!");


	number_of_dims = mxGetNumberOfDimensions(prhs[0]);
	dim_array = mxGetDimensions(prhs[0]);
  M = dim_array[0];
	N = dim_array[1];
  if(number_of_dims==2)
		C = 1;
	else
		C = dim_array[2];
	if(C!=1 && C!=3) mexErrMsgTxt("Input X must be MxNx1 or MxNx3."); 
	/*M=mxGetM(prhs[0]);*/
	/*N=mxGetN(prhs[0]);*/
	if (mxIsDouble(prhs[0]))
		input_data=mxGetPr(prhs[0]);
	else if (mxIsUint8(prhs[0])){
		input_data=(double*)mxCalloc(M*N*C, sizeof(double));
		int_input_data=(unsigned char*)mxGetPr(prhs[0]);
		for (m=0; m<M*N*C; m++) input_data[m]=(double)int_input_data[m]/255.0;
		/* RFD: added "/255.0" to the above line so that uint8 inputs work properly. */
	}
	else    
		mexErrMsgTxt("Input X must be of type double or uint8!");

	m = mxGetScalar(prhs[1])-1;
	n = mxGetScalar(prhs[2])-1;
	if (m<0 || m>=M || n<0 || n>=N)
		mexErrMsgTxt("Invalid cooridinates m and n!");
	if (nrhs==3 || mxIsEmpty(prhs[3])) Tol=0.01; 
	else Tol=mxGetScalar(prhs[3]);

	output_dims[0] = M;
	output_dims[1] = N;
	/*  plhs[0]=mxCreateNumericArray(2, output_dims, mxUINT8_CLASS, mxREAL);
			mxSetLogical(plhs[0]); */
	plhs[0] = mxCreateLogicalMatrix(M, N);
	output_data = (unsigned char*)mxGetLogicals(plhs[0]);

	if(nrhs==5){
		mxGetString(prhs[4], neighborhood, 5);
	}else{
		strcpy(neighborhood, "four");
	}
	if(C==3){
		if(strncmp(neighborhood, "eigh", 4)==0)
			magic_wand_8_rgb(output_data, input_data, M, N, m, n, Tol);
		else
			magic_wand_rgb(output_data, input_data, M, N, m, n, Tol);
	}else{
		if(strncmp(neighborhood, "eigh", 4)==0)
			magic_wand_8(output_data, input_data, M, N, m, n, Tol);
		else
			magic_wand(output_data, input_data, M, N, m, n, Tol);
	}
	return;
}
