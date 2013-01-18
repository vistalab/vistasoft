/* 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  File: convolve.h
;;;  Author: Simoncelli
;;;  Description: Header file for convolve.c
;;;  Creation Date:
;;;  ----------------------------------------------------------------
;;;    Object-Based Vision and Image Understanding System (OBVIUS),
;;;      Copyright 1988, Vision Science Group,  Media Laboratory,  
;;;              Massachusetts Institute of Technology.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
*/

#include <stdio.h>
#include <stdlib.h> 

#define ABS(x)	  (((x)>=0) ? (x) : (-(x)))
#define ROOT2 1.4142135623730951
#define REDUCE 0
#define EXPAND 1
#define IS    ==
#define ISNT  !=
#define AND &&
#define OR ||

typedef  int (*fptr)();

typedef struct 
  {
  char *name;
  fptr func;
  } EDGE_HANDLER;

fptr edge_function();

int internal_expand(double *image,double  *filt,double * temp,int x_fdim,int y_fdim,int x_start,int x_step,int x_stop,int y_start,int y_step,int y_stop, double *result,int x_dim,int y_dim,char *edges);
int internal_reduce(double *image,int x_dim,int  y_dim,double * filt,double * temp,int x_fdim, int y_fdim,int x_start, int x_step, int x_stop,int y_start, int y_step, int y_stop, double * result, char * edges);
int internal_wrap_expand (double *image, double *filt,int  x_fdim, int y_fdim,int x_start,int x_step,int x_stop,int  y_start,int  y_step,int y_stop,double *result, int x_dim, int y_dim);
int internal_wrap_reduce(double *image,int x_dim, int y_dim,double * filt, int x_fdim,int  y_fdim, int x_start, int x_step, int x_stop, int y_start,int y_step,int y_stop, double *result);
