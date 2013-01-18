/*
   edgesCross2d.c
   
   AUTHOR:	Chial
   DATE:	09.17.98
   PURPOSE:	Function returns 1 if the edges cross, 0 if they don't.
   
   ARGUMENTS:	edge1		indices of the two vertices on the first edge
   		edge2		indices of the two vertices on the second edge
   		nodeArray	locations and connection info for all vertices
   		
   RETURNS:	1 if edges cross in 2D, 0 if they don't.
*/

#include <math.h>
#include "mex.h"

#define assert(arg)
#define NODEN(nodeArray,n)      ((nodeArray)+(n)*8)

/****************************************************************************/

void mexFunction(int		nlhs,		/* # arguments on lhs */
                 mxArray	*plhs[],        /* Matrices on lhs */
                 int		nrhs,		/* # arguments on rhs */
                 const mxArray	*prhs[]		/* Matrices on rhs */
                 )
{
   double		*edge1, *edge2;
   double		*nodeArray;
   double		*vertA, *vertB, *vertC, *vertD;
   double		Ax, Ay, Bx, By, Cx, Cy, Dx, Dy;
   double		slope1, slope2, s, t;
   double		a, b, c, d, e, f, det;
   unsigned short	crit1, crit2;
   int			crossFlag = 0;

   double		*result;
   
   if (nrhs != 3 ) {
      mexErrMsgTxt( "Incorrect number of input arguments: crossFlag = edgesCross2d(edge1,edge2,nodes)" );
   }

   /*if (nlhs > 1 ) {
      mexErrMsgTxt( "Too many output arguments: crossFlag = edgesCross2d(edge1,edge2,nodes)" );
   }*/

   /* Arg 1.  'edge1' */
   edge1 = mxGetPr(prhs[0]);
   assert(mxGetN(prhs[0]) == 2);
   
   /* Arg 2.  'edge2' */
   edge2 = mxGetPr(prhs[1]);
   assert(mxGetN(prhs[1]) == 2);
   
   /* Arg 3.  'nodes' */
   nodeArray = mxGetPr(prhs[2]);
   assert(mxGetM(prhs[2]) == 8);

   /* Begin function */
   
   vertA = NODEN(nodeArray,(int)edge1[0]-1);
   vertB = NODEN(nodeArray,(int)edge1[1]-1);
   vertC = NODEN(nodeArray,(int)edge2[0]-1);
   vertD = NODEN(nodeArray,(int)edge2[1]-1);
   
   Ax = vertA[0];	Ay = vertA[1];
   Bx = vertB[0];	By = vertB[1];
   Cx = vertC[0];	Cy = vertC[1];
   Dx = vertD[0];	Dy = vertD[1];
  
   /* First criterion is that the edges are not parallel */ 
   slope1 = (Ay - By) / (Ax - Bx);
   slope2 = (Cy - Dy) / (Cx - Dx);
   crit1 = (slope1 != slope2);
  
   /* Second criterion is that edges do not have a vertex in common */
   crit2 = ((vertA != vertC) & (vertA != vertD) & (vertB != vertC) & (vertB != vertD));
  
   if (crit1 & crit2) {
     /* Find the intersection of the two edges */
     a = Bx - Ax;	b = Cx - Dx;
     c = By - Ay;	d = Cy - Dy;
     e = Cx - Ax;	f = Cy - Ay;
    
     det = a*d - c*b;
    
     s = (d*e - b*f)/det;
     t = (-c*e + a*f)/det;
    
     /* If the intersection occurs along the line segments, then the edges cross */
     if ((s > 0) & (s < 1) & (t > 0) & (t < 1)) {
       crossFlag = 1;
     }
   }

   plhs[0] = mxCreateDoubleMatrix(1, 1, mxREAL);
   result = mxGetPr(plhs[0]);
   *result = crossFlag;
  
   return;
}
