#include <math.h>
#include "mex.h"

#if !defined(max)
#define	max(A, B)	((A) > (B) ? (A) : (B))
#endif

#if !defined(min)
#define	min(A, B)	((A) < (B) ? (A) : (B))
#endif

/* Input Arguments */
#define	X               prhs[0]
#define	Y               prhs[1]
#define	W               prhs[2]
#define	EDGES_IN	       prhs[3]
#define	EDGEOFFSETS_IN	       prhs[4]
#define	NUMNEIGHBORS_IN	       prhs[5]


/* Output Arguments */
#define	VAR			plhs[0]
#define MEANX			plhs[1]
#define MEANY			plhs[2]
#define W_OUT			plhs[3]

static void varOfNeighbors(
double	*var,
double       *meanX,
double       *meanY,
double       *weightOut,
double	*x,
double	*y,
double	*weight,
double	*edges,
double	*edgeOffsets,
double	*numNeighbors,
int		numNodes
)
{
    int n, e, allN;
    double sumWeights, weightedSumOfValuesX, weightedSumOfValuesY, weightedSumOfMeanValues, distanceSquared;
    
    for (n=0; n<numNodes; n++)
      /* center point itself */
    {
        allN                 = 0;
        sumWeights           = weight[n];
        weightedSumOfValuesX = x[n]*weight[n];
        weightedSumOfValuesY = y[n]*weight[n];
        if (sumWeights>0)
        {
            allN += 1;
        }
        
      /* first loop compute mean*/
        for (e=(edgeOffsets[n]-1); e<(edgeOffsets[n]-1)+numNeighbors[n]; e++)
        {
            if (weight[(int)edges[e]]>0)
            {
                weightedSumOfValuesX += x[(int)edges[e]]*weight[(int)edges[e]];
                weightedSumOfValuesY += y[(int)edges[e]]*weight[(int)edges[e]];
                sumWeights += weight[(int)edges[e]];   
                allN += 1;
            }
        }
      /* sanity check */
        if (sumWeights==0)
        {
            meanX[n] = x[n];
            meanY[n] = y[n];
            var[n]   = 0;
            weightOut[n] = 0;
        }
        else
        {
            meanX[n] = weightedSumOfValuesX/sumWeights;
            meanY[n] = weightedSumOfValuesY/sumWeights;
            weightOut[n] = sumWeights/allN;
            
            distanceSquared = pow(x[n]-meanX[n],(double)2) + pow(y[n]-meanY[n],(double)2);
            weightedSumOfMeanValues = weight[n]*distanceSquared;
      /* second loop to compute variance */
            for (e=(edgeOffsets[n]-1), weightedSumOfMeanValues=0; e<(edgeOffsets[n]-1)+numNeighbors[n]; e++)
            {
                if (weight[(int)edges[e]]>0)
                {
                    distanceSquared = pow(x[(int)edges[e]]-meanX[n],(double)2) + pow(y[(int)edges[e]]-meanY[n],(double)2);
                    weightedSumOfMeanValues += weight[(int)edges[e]]*distanceSquared;
                }
            }
            var[n] = weightedSumOfMeanValues/(((allN-1)*sumWeights)/allN);
        }
    }
}

void mexFunction(
int nlhs,       mxArray *plhs[],
int nrhs, const mxArray *prhs[]
)
{
    double	*var;
    double	*meanX;
    double	*meanY;
    double        *weightOut;
    double	*x;
    double        *y;
    double        *weight;
    double	*edges;
    double	*edgeOffsets;
    double	*numNeighbors;
    int		numNodes;
    
    unsigned int	m,n;
    
  /* Check for proper number of arguments */
    if (nrhs != 6) {
        mexErrMsgTxt("sumOfNeighbors requires six input arguments.");
    } else if (nlhs > 4) {
        mexErrMsgTxt("sumOfNeighbors requires three output argument.");
    }
    
  /* Check the dimensions of Y.  Y can be 4 X 1 or 1 X 4. */
    m = mxGetM(X);
    n = mxGetN(X);
    
    numNodes = max(m,n);
    
  /* Create a matrix for the return argument */
    VAR   = mxCreateDoubleMatrix(numNodes, 1, mxREAL);
    MEANX = mxCreateDoubleMatrix(numNodes, 1, mxREAL);
    MEANY = mxCreateDoubleMatrix(numNodes, 1, mxREAL);
    W_OUT = mxCreateDoubleMatrix(numNodes, 1, mxREAL);
    
  /* Assign pointers to the various parameters */
    var   = mxGetPr(VAR);
    meanX = mxGetPr(MEANX);
    meanY = mxGetPr(MEANY);
    weightOut = mxGetPr(W_OUT);
    
    x      = mxGetPr(X);
    y      = mxGetPr(Y);
    weight = mxGetPr(W);
    edges  = mxGetPr(EDGES_IN);
    edgeOffsets = mxGetPr(EDGEOFFSETS_IN);
    numNeighbors = mxGetPr(NUMNEIGHBORS_IN);
    
  /* Function call */
    varOfNeighbors(var,meanX,meanY,weightOut,x,y,weight,edges,edgeOffsets,numNeighbors,numNodes);
    
    return;
}

