/*
   mrManDist.c

   AUTHOR:  Engel, Wandell
   DATE:    Nov., 1994
   PURPOSE:
   This code is used to create a mex-file for matlab for the routine
   of the same name, mrManDist().
   
   The input is an array of sample point coordinates that should form
   a connected manifold in three-space.

   The point of the routine is to compute the distances between a point 
   in three-space and a set of other points in three-space.  The distance
   is measured through the connected space of points. 

   DESCRIPTION:

    dist = mrManDist(grayNodes,grayEdges,startPt,[noVal],[radius])

   ARGUMENTS:
    startPt:   node index defining where to start the flood fill

   OPTIONAL ARGUMENTS:
    dimdist:Array of y,x and z separations between points.
    noVal:  The value returned for unreached locations (default 0)
    radius: The max distance to flood out
     (default 0 == flood as far as can)

   RETURNS:
    dist:  distances to each point from startPt -- same size as grayM
    nPntsReached:  The number of points reached from the start point.
   
   MODIFIED:  Completely re-written by Patrick Teo, 1996

              08.05.98 Started to re-write for sub-Graph computations and new unfolding.
	      We updated for the new format of Matlab 5.2 in the mexFunction prototype
	      and we changed the obsolete calls to mxCreateFull.
	      SJC/BW
	      
	      2007.03.20 Bob Dougherty: Copied contents of the long-lost pqueue.h into 
	      this file to simplify compilation. pqueue.h had been lost, but Genevieve 
	      Heckman from the Engel lab kindly sent an old version that they had lying
	      around. Also changed code to force the user to provide dimDist (4th arg).

   TO COMPILE:

      To simplify compilation, we have inserted pqueue.c into the mrManDist.c source code. 
      To compile, try:

           mex mrManDist.c

*/

#include "mex.h"

#include <stdio.h>
#include <sys/types.h>
#include <ctype.h>
#include <math.h>

/* #include <assert.h>*/
#define assert(arg)

/* Constants. */
#define POINT_UNREACHED -1

/* Attributes of NodeArray */
#define NUM_ATTRS	8

#define XCOORD 		0
#define YCOORD 		1
#define ZCOORD 		2
#define NUM_NBHRS	3
#define	NBHRS		4
#define	LAYER		5
#define	DIST		6
#define	PQINDEX		7

/* 2007.03.20 RFD: These are no longer needed as we now force the user to provide dimDist.
#define XSEPARATION .9375
#define YSEPARATION .9375
#define ZSEPARATION .70
*/

/* Data structures. */
typedef double *PQueueNode;
typedef struct {
  int	     max_size;
  int	     size;
  PQueueNode *array;
} PQueue;

/* Functions. */
#define NODEN(nodeArray,n)	((nodeArray)+(n)*NUM_ATTRS)
#define EDGEN(edgeArray,n)	((edgeArray)+(n)*3)

extern PQueue 	  *make_pqueue(int max_size);
extern void	  free_pqueue(PQueue *pqueue);
extern void	  pqueue_insert(PQueue *pqueue, PQueueNode node);
extern void	  pqueue_deckey(PQueue *pqueue, PQueueNode node);
extern PQueueNode pqueue_extract_min(PQueue *pqueue);	
#define pqueue_empty_p(pqueue)	((pqueue)->size <= 0)


/**********************************************************************/

/*
 * Computes distance between two adjacent nodes.
 */
double node_dist(double *node1, double *node2, double dimdist[3])
{
  double	dist, tmp;

  tmp = (node1[XCOORD]-node2[XCOORD])*dimdist[XCOORD];
  dist = tmp*tmp;

  tmp = (node1[YCOORD]-node2[YCOORD])*dimdist[YCOORD];
  dist += tmp*tmp;

  tmp = (node1[ZCOORD]-node2[ZCOORD])*dimdist[ZCOORD];
  dist += tmp*tmp;

  return( sqrt(dist) );
}


/**********************************************************************/

/*
 * Single source shortest path algorithm (Dijkstra's algorithm).
 */
static int shortest_path(double *nodeArray, int num_nodes, double *edgeArray, int num_edges,
			 int start_index, double dimdist[3], double radius, double *lastNodeList, int geoflag)
{
  int		i, cnt, num_nbhrs, curNodeIdx, curNhbrIdx, firstNodeOffset;
  double	*node, *new_node, *nbhrs, *nbhrdists, new_dist;
  PQueue	*PQ;

  /* Initialize distance to HUGE_VAL. */
  for (i=0, node=&nodeArray[DIST]; i<num_nodes; 
       i++, node+=NUM_ATTRS) *node = HUGE_VAL;

  /* Allocate priority queue and insert start_index as first node. */
  PQ = make_pqueue(num_nodes);
  node = NODEN(nodeArray,start_index-1);
  node[DIST] = 0.0;
  if (lastNodeList != NULL) {
    lastNodeList[start_index-1] = 0;
  }
  pqueue_insert(PQ, (PQueueNode)node);
  
  firstNodeOffset = ((int)NODEN(nodeArray,0));

  /* Dijkstra's algorithm. */
  cnt = 0;
  while (!pqueue_empty_p(PQ)) {
    node = (double *) pqueue_extract_min(PQ);
    curNodeIdx = (int)(((int)(node) - firstNodeOffset) / (8*NUM_ATTRS)) + 1;
    node[DIST] = -node[DIST]; 		/* computed */ 
    cnt++;
    
    /* Relax all the neighboring nodes. */
    num_nbhrs = (int) node[NUM_NBHRS];

    /* Get the geodesic distances to the neighbors. */
    if (geoflag == 1) {
      nbhrs = EDGEN(edgeArray,(((int)node[NBHRS])-1));
      nbhrdists = EDGEN(edgeArray,(((int)node[NBHRS])-1)) + 1;
    } else {
      nbhrs = &edgeArray[((int)node[NBHRS])-1];
    }

    for (i=0; i<num_nbhrs; i++) {
      if (geoflag == 1) {
        curNhbrIdx = ((int)nbhrs[2*i]);
        new_node = NODEN(nodeArray,((int)nbhrs[2*i])-1);
      } else {
        curNhbrIdx = (((int)nbhrs[i]));
        new_node = NODEN(nodeArray,((int)nbhrs[i])-1);
      }
      if (new_node[DIST]>=0) {	/* not computed yet */
	/* node[DIST] has been negated a couple of lines above.
	 * so, we need to negate it again to get the actual
	 * (positive) distance. 
	 * -node[DIST] is the distance from our working node
	 * to the start point.  node_dist() is the distance
	 * between our working node and its ith neighbor. */
        /* 08.05.98 SJC
 	 * If geoflag == 1, use the geodesic edge distance. */
        if (geoflag == 1) {
          new_dist = -node[DIST] + nbhrdists[2*i];
        } else {
  	  new_dist = -node[DIST] + node_dist(node, new_node, dimdist);
        }

	if (new_dist<radius) {
	  /* If this is the first time that we've gotten here, we
	   * use this new distance and add the node into the
	   * priority queue. */
	  if (new_node[DIST]==HUGE_VAL) {
	    new_node[DIST] = new_dist;
            if (lastNodeList != NULL) {
              lastNodeList[curNhbrIdx - 1] = curNodeIdx;
            }
	    pqueue_insert(PQ, (PQueueNode)new_node);
	  } 
	  /* Otherwise, if the new distance is less than
	   * the previously computed distance, then we pick
	   * the new (shorter) distance and adjust its
	   * position in the priority queue. */
	  else {
	    if (new_dist<new_node[DIST]) {
	      new_node[DIST] = new_dist;
              if (lastNodeList != NULL) {
		lastNodeList[curNhbrIdx - 1] = curNodeIdx;
              }
	      pqueue_deckey(PQ, (PQueueNode)new_node);
	    }
	  }
	}
      }
    }
  }
  free_pqueue(PQ);

  return(cnt);
}

/**********************************************************************/

/*
 * pqueue.c
 *
 * Implements a priority queue using a static heap.
 */

#if !defined(__APPLE__)
#include <malloc.h>
#endif

#define PARENT(i)	(((i)-1) >> 1)
#define LEFT(i)		(((i) << 1) + 1)
#define RIGHT(i)	(((i)+1) << 1)

PQueue *make_pqueue(int max_size)
{
     PQueue	*pqueue;

     pqueue = (PQueue*) malloc(sizeof(PQueue));
     assert(pqueue);
     
     pqueue->max_size = max_size;
     pqueue->size = 0;

     pqueue->array = (PQueueNode*)malloc(sizeof(PQueueNode)*max_size);
     assert(pqueue->array);

     return(pqueue);
}

/*
 * Free memory allocated by priority queue.
 */
void free_pqueue(PQueue *pqueue)
{
     free(pqueue->array);
     free(pqueue);
}

/*
 * Inserts new element into priority queue.
 */
void pqueue_insert(PQueue	*pqueue,
		   PQueueNode	node)
{
     int	i, p;
     PQueueNode	*arr = pqueue->array;

     assert(pqueue->size<pqueue->max_size);

     i = pqueue->size++;
     while ((i>0) && (node[DIST]<arr[p=PARENT(i)][DIST])) {
	  arr[i] = arr[p];
	  arr[i][PQINDEX] = (double) i;
	  i = p;
     }
     arr[i] = node;
     arr[i][PQINDEX] = (double) i;
}

/*
 * Decrease key.  Since the priority queue is in ascending
 * order, this pushes the element towards the front of the
 * queue.  The queue will be invalid if the key is increased
 * and this function called.
 */
void pqueue_deckey(PQueue	*pqueue,
		   PQueueNode	node)
{
     int	i, p;
     PQueueNode	*arr = pqueue->array;

     assert((((int)node[PQINDEX])>=0) && 
	    (((int)node[PQINDEX])<pqueue->size));

     i = (int) node[PQINDEX];
     while ((i>0) && (node[DIST]<arr[p=PARENT(i)][DIST])) {
	  arr[i] = arr[p];
	  arr[i][PQINDEX] = (double) i;
	  i = p;
     }
     arr[i] = node;
     arr[i][PQINDEX] = (double) i;
}

/*
 * Assumes left and right subtree of root are heaps only 
 * that the root node may not be the largest element in the
 * heap and therefore needs to be "sunked" to the right position
 * in the heap.  Runs in O(lg n).
 */
static void pqueue_heapify(pqueue, i)
     PQueue	*pqueue;
     int	i;
{
     int	l, r, smallest;
     int	size = pqueue->size;
     PQueueNode	*arr=pqueue->array, tmp;

     for (;;) {
	  l = LEFT(i); r = RIGHT(i);
	  smallest = ((l<size) && (arr[l][DIST]<arr[i][DIST])) ? l : i;
	  if ((r<size) && (arr[r][DIST]<arr[smallest][DIST]))
	       smallest = r;
	  if (smallest == i) break;
	  else {
	       tmp = arr[i];
	       arr[i] = arr[smallest]; arr[i][PQINDEX] = (double) i;
	       arr[smallest] = tmp; 
	       arr[smallest][PQINDEX] = (double) smallest;
	       i = smallest;
	  }
     }
}

/*
 * Extracts the smallest element in the priority queue.
 */
PQueueNode pqueue_extract_min(PQueue *pqueue)
{
     PQueueNode	*arr = pqueue->array, min;

     if (pqueue->size<=0) return( NULL );
     min = arr[0];
     arr[0] = arr[--pqueue->size];
     arr[0][PQINDEX] = (double) 0;
     pqueue_heapify(pqueue, 0);
     
     return( min );
}

/**********************************************************************/

void mexFunction(int nlhs,		        /* # arguments on lhs */
		 mxArray        *plhs[], 	/* Matrices on lhs */
		 int nrhs,		        /* # arguments on rhs */
		 const mxArray	*prhs[]		/* Matrices on rhs */
		 )
{
  double *dist, *lastNodeList, *nodeArray, *edgeArray, *nPointsReached, *tmp;
  double dimdist[3], num_dist, radius, nuldist;
  int	 num_nodes, num_edges, size_edges, start_index, count, i, geoflag;

  /* Check for proper number of arguments */
  if (nrhs == 0) {
       mexErrMsgTxt("[dist nPntsReached lastNodeList] = mrManDist(grayNodes,grayEdges,startPt,dimDist,[noVal],[radius])\n");
  } else {

    /* Create space for return arguments on the lhs */

    /* The size of dist is equal to the size of grayNodes */
    plhs[0] = mxCreateDoubleMatrix(1,mxGetN(prhs[0]),mxREAL);
    dist = mxGetPr(plhs[0]);

    /* If there are at least 2 output arguments, create space for nPointsReached */
    if (nlhs > 1) {
      plhs[1] = mxCreateDoubleMatrix(1,1,mxREAL);
      nPointsReached = mxGetPr(plhs[1]);
    } else {
      nPointsReached = NULL;
    }

    /* 08.07.98 SJC
     * lastNodeList keeps track of the last node in the geodesic
     * path taken to get the shortest distance to a given node.
     * To get the geodesic path, go backwards through the lastNodeList
     * until you reach the startPoint index.
     */
    /* If there are at least 3 output arguments, create space for lastNodeList,
     * which has the same size as dist. */
    if (nlhs > 2) {
      plhs[2] = mxCreateDoubleMatrix(1,mxGetN(prhs[0]),mxREAL);
      lastNodeList = mxGetPr(plhs[2]);
    } else {
      lastNodeList = NULL;
    }

    /* Interpret the input arguments on the rhs */
    if (nrhs < 4) {
      mexErrMsgTxt("mrManDist: At least four arguments are needed.");
    }
    
    /* Arg 1.  'nodes' */
    nodeArray = mxGetPr(prhs[0]);
    num_nodes = mxGetN(prhs[0]);
    assert(mxGetM(prhs[0])==8);

    /* Arg 2.  'edges' */
    edgeArray = mxGetPr(prhs[1]);
    num_edges = mxGetN(prhs[1]);
    size_edges = mxGetM(prhs[1]);
    /*assert(mxGetM(prhs[1])==1);*/
    /* 08.05.98  SJC Check the size of the edgeArray to see if it includes the geodesic
     * length of each edge. */
    if (size_edges == 2) {
      geoflag = 1;  /* Use the supplied geodesic length of each edge to calculate distances */
    } else {
      geoflag = 0;  /* Use dimdist and node locations to calculate distance between two nodes */
    }

    /* Arg 3.  'start_index' */
    tmp = mxGetPr(prhs[2]);
    start_index = (int) tmp[0];

    /* Analyze the optional arguments */

    /* Arg 4.  The physical distances between nodes. */
    /* 2007.03.20 RFD: We should not blindly assume a particular dimdist! We now force the user to provide this. */
    tmp = mxGetPr(prhs[3]);
    dimdist[0] = tmp[0]; /* y, x, z distances */
    dimdist[1] = tmp[1];
    dimdist[2] = tmp[2];

    /* Arg 5.  Choose the default value when points are unreached. */
    if (nrhs < 5) {
      nuldist = POINT_UNREACHED;
    }
    else {
      tmp = mxGetPr(prhs[4]);
      nuldist = tmp[0];
    }

    /* Arg 6.   'radius' */
    if (nrhs >= 6) {
      tmp = mxGetPr(prhs[5]);
      radius = tmp[0];

      /* 08.10.98  SJC
       * mrManDist comments say that if given an input radius of 0,
       * it should find all distances, but code did not do that, so
       * I added the following 3 lines.
       */
      if (radius == 0) {
        radius = HUGE_VAL;
      }
    }
    else {
      radius = HUGE_VAL;
    }
    /* mexPrintf("radius:  %f\n",radius); */

    /* Compute shortest path distances. */
    count = shortest_path(nodeArray, num_nodes,
			  edgeArray, num_edges,
			  start_index, dimdist, radius,
			  lastNodeList, geoflag);
    /* mexPrintf("count:  %d\n",count); */

    /* Copy distances to the output that is always returned. */
    for (i=0, tmp=&nodeArray[DIST]; i<num_nodes; i++, tmp+=NUM_ATTRS)
      dist[i] = (*tmp==HUGE_VAL) ? nuldist : -(*tmp);

    /* If there is a second argument, then return nPointsReached */
    if (nlhs == 2) {
      plhs[1] = mxCreateDoubleMatrix(1,1,mxREAL);
      nPointsReached = mxGetPr(plhs[1]);
      *nPointsReached = (double) count;
      /* mexPrintf("nPointsReached:  %f\n", *nPointsReached); */
    }

    /* lastNodeList will be returned if there is a third argument. */
  }
}


