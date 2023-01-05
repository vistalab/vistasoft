#include <math.h>
#include "mex.h"

#if !defined(max)
#define	max(A, B)	((A) > (B) ? (A) : (B))
#endif

#if !defined(min)
#define	min(A, B)	((A) < (B) ? (A) : (B))
#endif

/* Input Arguments */

#define	INPUT_IN				prhs[0]
#define	EDGES_IN				prhs[1]
#define	EDGEOFFSETS_IN		prhs[2]
#define	NUMNEIGHBORS_IN	prhs[3]


/* Output Arguments */

#define	RESULT_OUT			plhs[0]


static void sumOfNeighbors(
			double	*result,
			double	*input,
         double	*edges,
			double	*edgeOffsets,
         double	*numNeighbors,
         int		numNodes
         )
 {   
	int n, e;            

	for (n=0; n<numNodes; n++)
   	for (e=(edgeOffsets[n]-1), result[n]=0;
            	e<(edgeOffsets[n]-1)+numNeighbors[n]; e++) {
			result[n] += input[(int)edges[e]-1];
		}
}

void mexFunction(
                 int nlhs,       mxArray *plhs[],
                 int nrhs, const mxArray *prhs[]
		 )
{
	double	*result;
	double	*input;
   double	*edges;
   double	*edgeOffsets;
   double	*numNeighbors;
   int		numNodes;
   
   unsigned int	m,n;
  
  /* Check for proper number of arguments */
  
  if (nrhs != 4) {
    mexErrMsgTxt("sumOfNeighbors requires four input arguments.");
  } else if (nlhs > 1) {
    mexErrMsgTxt("sumOfNeighbors requires one output argument.");
  }
  
  /* Check the dimensions of Y.  Y can be 4 X 1 or 1 X 4. */
  
  m = mxGetM(INPUT_IN);
  n = mxGetN(INPUT_IN);
  
  numNodes = max(m,n);
  
  /* Create a matrix for the return argument */
  
  RESULT_OUT = mxCreateDoubleMatrix(numNodes, 1, mxREAL);
  
  
  /* Assign pointers to the various parameters */
  
  result = mxGetPr(RESULT_OUT);
  
  input = mxGetPr(INPUT_IN);
  edges = mxGetPr(EDGES_IN);
  edgeOffsets = mxGetPr(EDGEOFFSETS_IN);
  numNeighbors = mxGetPr(NUMNEIGHBORS_IN);
  
  sumOfNeighbors(result,input,edges,edgeOffsets,numNeighbors,numNodes);

  return;
}

