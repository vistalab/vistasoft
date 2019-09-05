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

// KdPointList: Linked list of destination points, along with the
// original index of each point.
//
/*
template<typename T>
struct KdPoint {
    T xyz[3];	
};
*/

template<class T>
struct KdPointList {
    T point[3];
    int     index;
    KdPointList<T> *next;
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
template<class T>
class KdNode {
public:
    ~KdNode();
    void getNearestPoint(const T target[3], int *bestIndex, T *bestSqDistance);
    T getSqDistance(const T target[3]);
protected:
    KdNode() {};
    void init(KdPointList<T> *aPointList);
    void expand();
    T      corners[2][3];    // Diametric corners of this node's box
    bool         isExpanded;    // Node has not been expanded yet
    KdPointList<T> *pointList;     // List of points in the node.  Used
                                // by leaf nodes & unexpanded nodes)
    KdNode<T>      *children;      // Child nodes, if expanded non-leaf node
};

template<class T>
class KdTree : public KdNode<T> {
public:
    KdTree(T destPoints[][3], int numDestPoints);
    ~KdTree();
    void getNearestPoint(const T target[3], int *bestIndex, T *bestSqDistance);
private:
    KdPointList<T> *pointArray;
};

/*********************************************************************
 * KdNode destructor
 */
template <class T>
KdNode<T>::~KdNode()
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
template <class T>
void KdNode<T>::getNearestPoint(const T target[3], int *bestIndex, T *bestSqDistance)
{
    expand();
    if (children == NULL) {
        // Leaf node
        *bestIndex      = pointList->index;
        *bestSqDistance = getSqDistance(target);
    } else {
        // non-leaf node
        T childSqDistance[2];
        childSqDistance[0] = children[0].getSqDistance(target);
        childSqDistance[1] = children[1].getSqDistance(target);

        int closerChild  = (childSqDistance[0] < childSqDistance[1]) ? 0 : 1;
        if (childSqDistance[closerChild] < *bestSqDistance) {
            children[closerChild].getNearestPoint(target, bestIndex, bestSqDistance);
        }

        int furtherChild  = 1 - closerChild;
        if (childSqDistance[furtherChild] < *bestSqDistance) {
            children[furtherChild].getNearestPoint(target, bestIndex, bestSqDistance);
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
template <class T>
T KdNode<T>::getSqDistance(const T target[3])
{
    T sqDistance = 0;
    for (int ii = 0; ii < 3; ii++) {
        T delta;
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
template <class T>
void KdNode<T>::init(KdPointList<T> *aPointList)
{
    int ii;

    // Find the corners
    //
    for (ii = 0; ii < 3; ii++) {
        corners[0][ii] = aPointList->point[ii];
        corners[1][ii] = aPointList->point[ii];
    }
    for (KdPointList<T> *pt = aPointList->next; pt != NULL; pt = pt->next) {
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
template <class T>
void KdNode<T>::expand()
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
        T tmpWidth = corners[1][axis] - corners[0][axis];
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
    T axisMidpoint = corners[0][widestAxis] + axisWidth/2;
    KdPointList<T> *subList[2] = {NULL, NULL};
    while (pointList != NULL) {
        KdPointList<T> *nextPoint = pointList->next;
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
template <class T>
KdTree<T>::KdTree(T destPoints[][3], int numDestPoints)
{
    // Allocate the points as an array, and convert the array into a
    // linked list.
    //
    pointArray = new KdPointList<T>[numDestPoints];
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
    this->init(pointArray);
}

template <class T>
KdTree<T>::~KdTree()
{
    delete[] pointArray;
}

/*********************************************************************
 * KdTree::getNearestPoint(): Thin wrapper around
 * KdNode::getNearestPoint() that initializes *bestIndex and
 * *bestSqDistance to legal values before.
 */
template <class T>
void KdTree<T>::getNearestPoint(const T target[3], int *bestIndex, T *bestSqDistance)
{
    T deltaX = target[0] - pointArray[0].point[0];
    T deltaY = target[1] - pointArray[0].point[1];
    T deltaZ = target[2] - pointArray[0].point[2];
    *bestIndex = 0;
    *bestSqDistance = deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ;
    KdNode<T>::getNearestPoint(target, bestIndex, bestSqDistance);
}

/*********************************************************************
 * Entry point for MEX function
*/
extern "C" void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    /* Check number of arguments */
    if (nrhs != 2) {
        mexErrMsgTxt("Two inputs required.");
    } else if (nlhs != 1 && nlhs != 2) {
        mexErrMsgTxt("One or two outputs required.");
    } else if (mxIsComplex(prhs[0]) || mxGetNumberOfDimensions(prhs[0]) != 2) {
        mexErrMsgTxt("First arg must be a real 3xM array.");
    } else if (mxIsComplex(prhs[1]) || mxGetNumberOfDimensions(prhs[1]) != 2) {
        mexErrMsgTxt("Second arg must be a real 3xN array.");
    } else {
        /* Input matrices */
        const mwSize *srcDims = mxGetDimensions(prhs[0]);
        const mwSize *destDims = mxGetDimensions(prhs[1]);

        bool isdouble = false;
        double (*srcPtr)[3];
        double (*destPtr)[3];
        float (*srcPtr32)[3];
        float (*destPtr32)[3];

        if(mxIsDouble(prhs[0])) {
            mexPrintf("nearpoints: using 64bits version\n");
            isdouble = true;
            srcPtr = (double (*)[3])mxGetPr(prhs[0]);
            destPtr = (double (*)[3])mxGetPr(prhs[1]);
        } else {
            mexPrintf("nearpoints: using 32bits version\n");
            srcPtr32 = (float (*)[3])mxGetPr(prhs[0]);
            destPtr32 = (float (*)[3])mxGetPr(prhs[1]);
        }

        /* Output vector */
        int *indices;
        double *tmpPtr;
        float *tmpPtr32;
        double *sqDist;
        float *sqDist32;

        /* Loop variables */
        int ii;

        /* Double-check the input size */
        if (srcDims[0] != 3) {
            mexErrMsgTxt("First arg must be a real 3xM array");
        } else if (destDims[0] != 3) {
            mexErrMsgTxt("Second arg must be a real 3xN array");
        }

        /* Create the first output */
        indices = (int *)mxMalloc(srcDims[1] * sizeof(int));

        if(isdouble) {
            sqDist = (double *)mxMalloc(srcDims[1] * sizeof(double));
            KdTree<double> kdTree(destPtr, destDims[1]);
            for (ii = 0; ii < srcDims[1]; ii++) {
                kdTree.getNearestPoint(srcPtr[ii], &indices[ii], &sqDist[ii]);	
            }
            plhs[0] = mxCreateNumericMatrix(1, srcDims[1], mxDOUBLE_CLASS, mxREAL);
            tmpPtr = (double*)mxGetData(plhs[0]);
            for (ii = 0; ii < srcDims[1]; ii++) {
                tmpPtr[ii] = indices[ii] + 1;
            }
        } else {
            sqDist32 = (float *)mxMalloc(srcDims[1] * sizeof(float));
            KdTree<float> kdTree(destPtr32, destDims[1]);
            for (ii = 0; ii < srcDims[1]; ii++) {
                kdTree.getNearestPoint(srcPtr32[ii], &indices[ii], &sqDist32[ii]);	
            }
            //tmpPtr = mxGetPr(plhs[0]);
            plhs[0] = mxCreateNumericMatrix(1, srcDims[1], mxSINGLE_CLASS, mxREAL);
            tmpPtr32 = (float*)mxGetData(plhs[0]);
            for (ii = 0; ii < srcDims[1]; ii++) {
                tmpPtr32[ii] = indices[ii] + 1;
            }
        }

        /* Create the second output */
        if (nlhs > 1) {
            plhs[1] = mxCreateNumericMatrix(1, srcDims[1], isdouble?mxDOUBLE_CLASS:mxSINGLE_CLASS, mxREAL);
            if(isdouble) {
                tmpPtr = (double *)mxGetPr(plhs[1]);
                for (ii = 0; ii < srcDims[1]; ii++) {
                tmpPtr[ii] = sqDist[ii];
                }	
            } else {
                tmpPtr32 = (float *)mxGetPr(plhs[1]);
                for (ii = 0; ii < srcDims[1]; ii++) {
                tmpPtr32[ii] = sqDist32[ii];
                }	
            }
        }

        mxFree(indices);
        if(isdouble) mxFree(sqDist);
        else mxFree(sqDist32);
    }
}
