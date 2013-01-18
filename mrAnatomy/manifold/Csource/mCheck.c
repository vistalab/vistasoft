/* mrCheckNodeIntersections.c
 *  
 * AUTHOR:	Chial
 * DATE:	09.18.98
 * PURPOSE:	Function returns 1 if any of the node's edges cause intersections,
 *		0 if they don't.
 * 
 * ARGUMENTS:	curNode		index of node to check
 * 		nodes		locations and offsets into edges array of all nodes
 *		edges		connections array
 * 		
 * RETURNS:	1 if edges cross in 2D, 0 if they don't.
 *
 * MODIFICATIONS:
 * 01.02.98 SJC	Added one more layer of checking for intersections.  For nodes that
 *		have very few (3 or 2) neighbors, only checking intersections with
 *		the neighbors' connections was not enough to detect all intersections.
 */

#ifndef ARRAY_ACCESS_INLINING
#error You must use the -inline option when compiling MATLAB compiler generated code with MEX or MBUILD
#endif
#ifndef MATLAB_COMPILER_GENERATED_CODE
#define MATLAB_COMPILER_GENERATED_CODE
#endif

#include <math.h>
#include "mex.h"
#include "mcc.h"

#define assert(arg)

#define NODEN(nodeArray,n)      ((nodeArray)+(n)*8)
#define EDGEN(edgeArray,n)      ((edgeArray)+(n)*2)

/****************************************************************************/
int edgesCross2d(	int	edge1[2],
			int	edge2[2],
			double	*nodeArray)
{
   int			crossFlag = 0;
   double		*vertA, *vertB, *vertC, *vertD;
   double		Ax, Ay, Bx, By, Cx, Cy, Dx, Dy;
   double		slope1, slope2, s, t;
   double		a, b, c, d, e, f, det;
   unsigned short	crit1, crit2;

   
   vertA = NODEN(nodeArray,edge1[0]-1);
   vertB = NODEN(nodeArray,edge1[1]-1);
   vertC = NODEN(nodeArray,edge2[0]-1);
   vertD = NODEN(nodeArray,edge2[1]-1);
   
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
   
   return(crossFlag);
}

/****************************************************************************/
int mrCheckNode2dIntersect(	int	curNode,
				double	*nodeArray,
				double	*edgeArray)
{
   int		intersectFlag = 0;
   int		jj;
   int		numOfEdges, edgesOffset, nextNode;
   double	*node,*curEdge;

   /* Get a pointer to the node whose intersections we are checking */
   node = NODEN(nodeArray,curNode-1);
   
   /* Get the connections for the current node */
   numOfEdges = (int) node[3];
   edgesOffset = (int) node[4];

   if (curNode > 0) {
     /* Check the connections of each of the neighbor nodes */
     for (jj = 0; jj < numOfEdges;  jj++, edgesOffset++) {
       curEdge = EDGEN(edgeArray,edgesOffset-1);
       nextNode = (int)curEdge[0];
       intersectFlag = mrCheckNodeIntersections(nextNode,nodeArray,edgeArray);
       if (intersectFlag) { jj = numOfEdges; }
     }
   }
   return(intersectFlag);
}

/****************************************************************************/
int mrCheckNodeIntersections(	int	curNode,
				double	*nodeArray,
				double	*edgeArray)
{
   int		intersectFlag = 0;
   int		jj, kk, ll;
   int		numOfEdgesC, edgesOffsetC;
   int		numOfEdgesN, edgesOffsetN;
   double 	*nodeC, *nodeN, *curEdge, *nhbrEdge, *tmpEdge;
   int		edge1[2], edge2[2];
   
   /* C refers to the current node, N refers to the neighbor node */
   nodeC = NODEN(nodeArray,curNode-1);
   
   /* Get the connections for the current node */
   numOfEdgesC = (int) nodeC[3];
   edgesOffsetC = (int) nodeC[4];

   /* The first edge always starts at the current ndoe */
   edge1[0] = curNode;
   
   if (curNode > 0) {
     /* Check the connections of each of the neighbor nodes */
     for (jj = 0; jj < numOfEdgesC;  jj++, edgesOffsetC++) {
       curEdge = EDGEN(edgeArray,edgesOffsetC-1);

       /* Get the connections for this neighbor node */
       nodeN = NODEN(nodeArray,(int)curEdge[0]-1);
       numOfEdgesN = (int) nodeN[3];
       edgesOffsetN = (int) nodeN[4];
     
       /* Compare the connections of this neighbor node to each of the
          connections of the current node */
       for (kk = 0; kk < numOfEdgesN; kk++, edgesOffsetN++) {
         /* This is the edge on the neighbor node */
         nhbrEdge = EDGEN(edgeArray,edgesOffsetN-1);
         edge2[0] = (int) curEdge[0];
         edge2[1] = (int) nhbrEdge[0];
       
         for (ll = 0; ll < numOfEdgesC; ll++) {
           /* This is the from the current node to a neighbor node */
           tmpEdge = EDGEN(edgeArray,(int) nodeC[4] + ll - 1);
           edge1[1] = (int) tmpEdge[0];
         
           /* If the two edges cross, set the intersect flag and terminate all loops */
           mexPrintf("Checking edges %d %d and %d %d.\n",edge1[0],edge1[1],edge2[0],edge2[1]);
           if (edgesCross2d(edge1,edge2,nodeArray)) {
             mexPrintf("  Intersection!!\n");
             intersectFlag = 1;
             ll = numOfEdgesC;
           }
         }
         if (intersectFlag) { kk = numOfEdgesN; }
       }
       if (intersectFlag) { jj = numOfEdgesC; }
     }
   }
   
   return(intersectFlag);
}
/****************************************************************************/
void mexFunction(int		nlhs,		/* # arguments on lhs */
                 mxArray	*plhs[],        /* Matrices on lhs */
                 int		nrhs,		/* # arguments on rhs */
                 const mxArray	*prhs[]		/* Matrices on rhs */
                 )

{
   int		curNode, crossFlag;
   double	*nodeArray, *edgeArray;
   double	*tmp;
   
   /* Check for correct number if input and output arguments */
   if (nrhs != 3 ) {
      mexErrMsgTxt( "Incorrect number of input arguments: crossFlag = mrCheckNodeIntersections(curNode,nodes,edges)" );
   }
   
   if (nlhs > 1) {
      mexErrMsgTxt( "Incorrect number of output arguments: crossFlag = mrCheckNodeIntersections(curNode,nodes,edges)" );
   }

   /* Arg 1.  'curNode' */
   tmp = mxGetPr(prhs[0]);
   curNode = (int) tmp[0];
   
   /* Arg 2.  'nodes' */
   nodeArray = mxGetPr(prhs[1]);
   assert(mxGetM(prhs[1]) == 8);
   
   /* Arg 3.  'edges' */
   edgeArray = mxGetPr(prhs[2]);
   assert(mxGetM(prhs[2]) == 2);
   
   /* Call mrCheckNodeIntersections */
   crossFlag = mrCheckNode2dIntersect(curNode,nodeArray,edgeArray);

   /* Return output*/
   goto MretR;
   MretR: ;
   mccReturnScalar(&plhs[0], crossFlag, 0., mccREAL, 0);

   return;
}
