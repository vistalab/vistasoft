/*********************************************************************
 * Efficiently finds the closest (3-space) point from a list of points 
 * to any given point.
 *
 * To compile, run:
 *    mex -O nearpoints.cxx
 *
 * HISTORY:
 * 2004.02.07 Dan Merget: wrote it.
 * 2004.02.09 Bob Dougherty: now also returns best (squared) distance.
 * I also added some comments.
 *
 */
#include <stdlib.h>
#include <mex.h>
#include <matrix.h>



/*********************************************************************
 * C++ CLASS DECLARATIONS
 ********************************************************************/



// KdPoint:  Contains the coordinates of a point in 3D space
//
typedef double KdPoint[3];

// KdPointList: Linked list of destination points, along with the
// original index of each point.
//
struct KdPointList {
    KdPoint point;
    int     index;
    KdPointList *next;
};

// KdTree/KdNode: This is a binary tree that holds a set of KdPoints.
// Each node contains (roughly) half of the points of its parent.
// 
// In order to optimize the search, each node indicates the smallest
// box in 3D-space that will hold all of the KdPoints in the subtree.
// The box indicated by a node should be a subset of the parent's box,
// and should not overlap with the sibling's box.

// Each box is indicated by two diametric corners.  Each leaf node
// contains a single KdPoint, such that corners[0] == corners[1] ==
// point.
//
// As an optimization, a subtree is not expanded until it is needed.
// This can save significant time if nearpoints is called with more
// destination points than source points, since most subtrees will not
// need to be expanded.
//
class KdNode {
public:
    ~KdNode();
    void getNearestPoint(const KdPoint &target,
                         int *bestIndex, double *bestSqDistance);
    double getSqDistance(const KdPoint &target);
protected:
    KdNode() {};
    void init(KdPointList *pointList);
    void expand();
    KdPoint      corners[2];    // Diametric corners of this node's box
    bool         isExpanded;    // Node has not been expanded yet
    KdPointList *pointList;     // List of points in the node.  Used
                                // by leaf nodes & unexpanded nodes)
    KdNode      *children;      // Child nodes, if expanded non-leaf node
};

class KdTree: public KdNode {
public:
    KdTree(double destPoints[][3], int numDestPoints);
    ~KdTree();
    void getNearestPoint(const KdPoint &target,
                         int *bestIndex, double *bestSqDistance);
private:
    KdPointList *pointArray;
};



/*********************************************************************
 * C++ FUNCTIONS
 ********************************************************************/



/*********************************************************************
 * KdNode destructor
 */
KdNode::~KdNode()
{
    if (children != NULL) {
        delete[] children;
    }
}

/*********************************************************************
 * KdNode::getNearestPoint(): If we can find a point in the subtree
 * closer to target than bestSqDistance, then store the index of the
 * closest point in *bestIndex and the distance in *bestSqDistance.
 */
void KdNode::getNearestPoint(const KdPoint &target,
                             int *bestIndex, double *bestSqDistance)
{
    expand();
    if (children == NULL) {
        // Leaf node
        *bestIndex      = pointList->index;
        *bestSqDistance = getSqDistance(target);
    } else {
        // non-leaf node
        double childSqDistance[2];
        childSqDistance[0] = children[0].getSqDistance(target);
        childSqDistance[1] = children[1].getSqDistance(target);

        int closerChild  = (childSqDistance[0] < childSqDistance[1]) ? 0 : 1;
        if (childSqDistance[closerChild] < *bestSqDistance) {
            children[closerChild].getNearestPoint(target,
                                                  bestIndex, bestSqDistance);
        }

        int furtherChild  = 1 - closerChild;
        if (childSqDistance[furtherChild] < *bestSqDistance) {
            children[furtherChild].getNearestPoint(target,
                                                   bestIndex, bestSqDistance);
        }
    }
}


/*********************************************************************
 * getSqDistance(): Get the squared distance from this box to the
 * target.
 *
 * The "distance" is actually the square of the Euclidean distance.
 * (Why waste time taking all those square roots?)  The distance is
 * measured from the target point to the nearest point on the box, so
 * the distance will be 0 if the target lies inside the box.
 */
double KdNode::getSqDistance(const KdPoint &target)
{
    double sqDistance = 0;
    for (int ii = 0; ii < 3; ii++) {
        double delta;
        if (corners[0][ii] >= target[ii]) {
            delta = corners[0][ii] - target[ii];
        } else if (corners[1][ii] <= target[ii]) {
            delta = target[ii] - corners[1][ii];
        } else {
            delta = 0;
        }
        sqDistance += delta * delta;
    }

    return sqDistance;
}

/*********************************************************************
 * KdNode::init(): Initialize a KdNode.
 */
void KdNode::init(KdPointList *aPointList)
{
    int ii;

    // Find the corners
    //
    for (ii = 0; ii < 3; ii++) {
        corners[0][ii] = aPointList->point[ii];
        corners[1][ii] = aPointList->point[ii];
    }
    for (KdPointList *pt = aPointList->next; pt != NULL; pt = pt->next) {
        for (ii = 0; ii < 3; ii++) {
            if (corners[0][ii] > pt->point[ii]) {
                corners[0][ii] = pt->point[ii];
            } else if (corners[1][ii] < pt->point[ii]) {
                corners[1][ii] = pt->point[ii];
            }
        }
    }

    // Set up the unexpanded node
    //
    isExpanded = false;
    pointList  = aPointList;
    children  = NULL;
}

/*********************************************************************
 * KdNode::expand(): Expand the node, i.e. determine whether or not it
 * is a leaf node, and create its children if it is a non-leaf node.
 */
void KdNode::expand()
{
    // If the node was already expanded, then return immediately
    //
    if (isExpanded) {
        return;
    }

    // Find the widest axis.
    //
    int    widestAxis = 0;
    double axisWidth  = 0;
    for (int axis = 0; axis < 3; axis++) {
        double tmpWidth = corners[1][axis] - corners[0][axis];
        if (axisWidth < tmpWidth) {
            axisWidth  = tmpWidth;
            widestAxis = axis;
        }
    }

    // If all the axes have length 0, then this is a leaf node.
    //
    if (axisWidth == 0) {
        isExpanded = true;
        return;
    }

    // Cut the widest axis at the midpoint, by dividing pointList into
    // two sub-lists.
    //
    double axisMidpoint = corners[0][widestAxis] + axisWidth/2;
    KdPointList *subList[2] = {NULL, NULL};
    while (pointList != NULL) {
        KdPointList *nextPoint = pointList->next;
        int subListNum = (pointList->point[widestAxis] < axisMidpoint) ? 0 : 1;
        pointList->next = subList[subListNum];
        subList[subListNum] = pointList;
        pointList = nextPoint;
    }

    // Create two children, containing the sub-lists.
    //
    children = new KdNode[2];
    children[0].init(subList[0]);
    children[1].init(subList[1]);
    isExpanded = true;
}

/*********************************************************************
 * KdTree constructor: Allocate the KdPoints that will be used in this
 * tree, and initialize the root node.
 */
KdTree::KdTree(double destPoints[][3], int numDestPoints)
{
    // Allocate the points as an array, and convert the array into a
    // linked list.
    //
    pointArray = new KdPointList[numDestPoints];
    for (int ii = 0; ii < numDestPoints; ii++) {
        pointArray[ii].point[0] = destPoints[ii][0];
        pointArray[ii].point[1] = destPoints[ii][1];
        pointArray[ii].point[2] = destPoints[ii][2];
        pointArray[ii].index    = ii;
        pointArray[ii].next     = &pointArray[ii + 1];
    }
    pointArray[numDestPoints - 1].next = NULL;

    // Initialize the root node
    //
    init(pointArray);
}

/*********************************************************************
 * KdTree destructor
 */
KdTree::~KdTree()
{
    delete[] pointArray;
}

/*********************************************************************
 * KdTree::getNearestPoint(): Thin wrapper around
 * KdNode::getNearestPoint() that initializes *bestIndex and
 * *bestSqDistance to legal values before.
 */
void KdTree::getNearestPoint(const KdPoint &target,
                             int *bestIndex, double *bestSqDistance)
{
    double deltaX = target[0] - pointArray[0].point[0];
    double deltaY = target[1] - pointArray[0].point[1];
    double deltaZ = target[2] - pointArray[0].point[2];
    *bestIndex = 0;
    *bestSqDistance = deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ;
    KdNode::getNearestPoint(target, bestIndex, bestSqDistance);
}



/*********************************************************************
 * MEX FUNCTION
 ********************************************************************/



/*********************************************************************
 * Entry point for MEX function
*/
extern "C" void mexFunction(int nlhs, mxArray *plhs[],
                            int nrhs, const mxArray *prhs[])
{
    /* Check number of arguments */
    if (nrhs != 2) {
        mexErrMsgTxt("Two inputs required.");
    } else if (nlhs != 1 && nlhs != 2) {
        mexErrMsgTxt("One or two outputs required.");
    } else if (!mxIsDouble(prhs[0]) || mxIsComplex(prhs[0]) ||
               mxGetNumberOfDimensions(prhs[0]) != 2)
    {
        /* First arg must be a real 3xM array */
        mexErrMsgTxt("First arg must be a real 3xM array.");
    } else if (!mxIsDouble(prhs[1]) || mxIsComplex(prhs[1]) ||
               mxGetNumberOfDimensions(prhs[1]) != 2)
    {
        /* Second arg must be a real 3xN array */
        mexErrMsgTxt("First arg must be a real 3xN array.");
    } else {
        /* Input matrices */
        const int *srcDims      = mxGetDimensions(prhs[0]);
        double    (*srcPtr)[3]  = (double (*)[3])mxGetPr(prhs[0]);
        const int *destDims     = mxGetDimensions(prhs[1]);
        double    (*destPtr)[3] = (double (*)[3])mxGetPr(prhs[1]);

        /* Output vector */
        int *indices;
        double *tmpPtr;
        double *sqDist;

        /* Loop variables */
        int ii, jj;

        /* Double-check the input size */
        if (srcDims[0] != 3) {
            mexErrMsgTxt("First arg must be a real 3xM array");
        } else if (destDims[0] != 3) {
            mexErrMsgTxt("Second arg must be a real 3xN array");
        }

        /* Create the first output */
        indices = (int *)mxMalloc(srcDims[1] * sizeof(int));
        sqDist = (double *)mxMalloc(srcDims[1] * sizeof(double));
        KdTree kdTree(destPtr, destDims[1]);
        for (ii = 0; ii < srcDims[1]; ii++) {
            kdTree.getNearestPoint(srcPtr[ii], &indices[ii], &sqDist[ii]);
        }

        plhs[0] = mxCreateNumericMatrix(1, srcDims[1], mxDOUBLE_CLASS, mxREAL);
        tmpPtr = mxGetPr(plhs[0]);
        for (ii = 0; ii < srcDims[1]; ii++) {
            tmpPtr[ii] = indices[ii] + 1;
        }

        /* Create the second output */
        if (nlhs > 1) {
            double (*nearestDestPtr)[3];
            plhs[1] = mxCreateNumericMatrix(1, srcDims[1],
                                            mxDOUBLE_CLASS, mxREAL);
            tmpPtr = (double *)mxGetPr(plhs[1]);
            for (ii = 0; ii < srcDims[1]; ii++) {
                tmpPtr[ii] = sqDist[ii];
            }
        }

        mxFree(indices);
        mxFree(sqDist);
    }
}
