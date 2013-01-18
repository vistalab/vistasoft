/*********************************************************************
 *
 * intersect = dtiFiberIntersectMesh(fibers, triangles, vertices)
 *
 * Given a set of 'fibers' and a surface mesh (defined by 
 * triangles/vertices), will find every triangle in the surface mesh
 * that is intersected by the fibers.
 *
 * ARGUMENTS:
 * 
 * fibers = an Nx1 cell array of fibers, where each cell contains a 
 *          3xN real array of points (XYZ order) that specify a fiber 
 *          path. A fiber must contain more than 1 point (or be empty).
 *
 * triangles = a 3xN uint32 array of triangles, where each entry is
 *             an index into the vertices array.
 *
 * vertices = a 3xN double array of vertices in YXZ order.
 *
 * NOTE! We assume that the mesh vertices are X-Y swapped relative to
 * the fiber vertices. (Because they are in our data representations.)
 *
 * RETURNS:
 *
 * intersect = an Nx1 cell array, where N = the number of fibers
 *             (ie. length(fibers)). Each cell contains a 5xN array
 *             where N is the number of intersections. It has the 
 *             following structure: [triangleIndex  fiberIndex X Y Z]
 *
 * NOTES:
 * The hard work is done by the RAPID collision detection library. This 
 * is only free for non-commercial use, so you'll need to get the library
 * from its maintainer if you want to rebuild the mex file. See: 
 * http://www.cs.unc.edu/~geom/OBB/OBBT.html or search google for
 * "Robust and Accurate Polygon Interference Detection".
 *
 * To compile:
 *    mex -O -I. dtiFiberIntersectMesh.cxx libRAPID.a
 *
 * HISTORY:
 * 2004.07.28 Bob Dougherty: wrote it.
 *
 */
#include <mex.h>
#include <matrix.h>
#include <math.h>
#include <RAPID.H>

#ifndef ROUND
#define  ROUND(f)   ((f>=0)?(int)(f + .5):(int)(f - .5)) 
#endif


/*********************************************************************
 * MEX FUNCTION
 *
 * Entry point for MEX function
 */
extern "C" void mexFunction(int nlhs, mxArray *plhs[],
                            int nrhs, const mxArray *prhs[]){
  /* Check number of arguments */
  if(nrhs < 3){
    mexErrMsgTxt("USAGE: intersectPts = dtiFiberIntersectMesh(fibers, triangles, vertices);");
    return;
  }
  if(nlhs != 1){
    mexErrMsgTxt("USAGE: intersectPts = dtiFiberIntersectMesh(fibers, triangles, vertices);");
    return;
  }

  if(!mxIsCell(prhs[0]) || mxGetNumberOfDimensions(prhs[0])!=2 || mxGetN(prhs[0])!=1){
    mexErrMsgTxt("Arg 1 must be an Nx1 cell array of fibers.");
    return;
  }

  if(!mxIsUint32(prhs[1]) || mxIsComplex(prhs[1]) || mxGetNumberOfDimensions(prhs[1])!=2 || mxGetM(prhs[1])!=3){
    mexErrMsgTxt("Arg 2 must be a *3xN* uint32 array of triangles.");
    return;
  }

  if(!mxIsDouble(prhs[2]) || mxIsComplex(prhs[2]) || mxGetNumberOfDimensions(prhs[2])!=2 || mxGetM(prhs[2])!=3){
    mexErrMsgTxt("Arg 3 must be a *real* *3xN* *double* array of vertices.");
    return;
  }

  /* Input matrices */
  const int nFibers = mxGetM(prhs[0]);
  const int nTriangles = mxGetN(prhs[1]);
  const int nVertices = mxGetN(prhs[2]);
  int nFiberPts;
  double tmpDbl;
  unsigned long *triPtr = (unsigned long *)mxGetPr(prhs[1]);
  double *vertPtr = (double*)mxGetPr(prhs[2]);
  double *fiberPtr;
  double *tmpPtr;
  mxArray *tmpArray;

  mexPrintf("nFibers=%d, nTriangles=%d\n", nFibers, nTriangles);

  plhs[0] = mxCreateCellMatrix(1, nFibers);

  int ii,jj;

  // Build the surface mesh model
  mexPrintf("Building surface mesh model...\n");
  RAPID_model *surfMesh = new RAPID_model;
  double p1[3], p2[3], p3[3];
	
  surfMesh->BeginModel();
  for (ii = 0; ii < nTriangles; ii++) {
			// *** WARNING! XY swap!
    p1[1] = vertPtr[*triPtr*3];
    p1[0] = vertPtr[(*triPtr)*3+1];
    p1[2] = vertPtr[(*triPtr++)*3+2];
    p2[1] = vertPtr[*triPtr*3];
    p2[0] = vertPtr[(*triPtr)*3+1];
    p2[2] = vertPtr[(*triPtr++)*3+2];
    p3[1] = vertPtr[*triPtr*3];
    p3[0] = vertPtr[(*triPtr)*3+1];
    p3[2] = vertPtr[(*triPtr++)*3+2];
    surfMesh->AddTri(p1, p2, p3, ii);
    //printf("%d: %.1f,%.1f,%.1f; %.1f,%.1f,%.1f; %.1f,%.1f,%.1f;\n\n",
    //	   ii, p1[0],p1[1],p1[2],p2[0],p2[1],p2[2],p3[0],p3[1],p3[2]);
  }
  surfMesh->EndModel();

  double epsilon=0.1;
  double R1[3][3], R2[3][3], T1[3], T2[3];
  RAPID_model *fiberModel = new RAPID_model;
  for (ii = 0; ii < nFibers; ii++) {
    //if(ii%100==0)
      //mexPrintf("Processing fiber %d...\n", ii);

			RAPID_model *fiberModel = new RAPID_model;
		
    // Get a pointer to the current set of fiber points
    // (prhs[0] is a cell array of fibers- a "fiber group")
    tmpArray = mxGetCell(prhs[0], ii);
    // Fiber points are stored as an 3xN array. 
    fiberPtr = (double *)mxGetPr(tmpArray);
    nFiberPts = mxGetN(tmpArray);

		if(!mxIsEmpty(tmpArray)){
			if(!mxIsDouble(tmpArray) || mxIsComplex(tmpArray) || mxGetNumberOfDimensions(tmpArray)!=2 || mxGetM(tmpArray)!=3){
				mexErrMsgTxt("All fibers must be 3xN real arrays!.");
				return;
			}
			
			// Build the fiber model
			fiberModel->BeginModel();
			tmpPtr = fiberPtr;
			for (jj = 0; jj < nFiberPts-1; jj+=2) {
				p1[0] = *tmpPtr++;
				p1[1] = *tmpPtr++;
				p1[2] = *tmpPtr++;
				p2[0] = *tmpPtr++;
				p2[1] = *tmpPtr++;
				p2[2] = *tmpPtr++;
				p3[0] = (p1[0]+p2[0])/2+epsilon;
				p3[1] = (p1[1]+p2[1])/2-epsilon;
				p3[2] = (p1[2]+p2[2])/2+epsilon;
				fiberModel->AddTri(p1, p2, p3, jj);
			}
			fiberModel->EndModel();
			
			R1[0][0] = R1[1][1] = R1[2][2] = 1.0;
			R1[0][1] = R1[1][0] = R1[2][0] = 0.0;
			R1[0][2] = R1[1][2] = R1[2][1] = 0.0;
			
			R2[0][0] = R2[1][1] = R2[2][2] = 1.0;
			R2[0][1] = R2[1][0] = R2[2][0] = 0.0;
			R2[0][2] = R2[1][2] = R2[2][1] = 0.0;
			
			T1[0] = 0.0;  T1[1] = 0.0; T1[2] = 0.0;
			T2[0] = 0.0;  T2[1] = 0.0; T2[2] = 0.0;
			RAPID_Collide(R1, T1, surfMesh, R2, T2, fiberModel, RAPID_ALL_CONTACTS);
			
			// 		printf("All contacts between overlapping models:\n");
			// 		printf("Num box tests: %d\n", RAPID_num_box_tests);
			// 		printf("Num contact pairs: %d\n", RAPID_num_contacts);
			// for(jj=0; jj<RAPID_num_contacts; jj++){
			//   printf("\t contact %4d: tri %4d and tri %4d\n", jj, RAPID_contact[jj].id1, RAPID_contact[jj].id2);
			// }
			
			// Create the array that will store the intersection points
			tmpArray = mxCreateNumericMatrix(5, RAPID_num_contacts, mxDOUBLE_CLASS, mxREAL);
			tmpPtr = (double *)mxGetPr(tmpArray);
			for (jj = 0; jj < RAPID_num_contacts; jj++) {
				// We add 1 to convert to matlab indices
				*tmpPtr++ = RAPID_contact[jj].id1+1;
				*tmpPtr++ = RAPID_contact[jj].id2+1;
				*tmpPtr++ = fiberPtr[RAPID_contact[jj].id2*3];
				*tmpPtr++ = fiberPtr[RAPID_contact[jj].id2*3+1];
				*tmpPtr++ = fiberPtr[RAPID_contact[jj].id2*3+2];
			}
			mxSetCell(plhs[0],ii,tmpArray);
			delete fiberModel;
		}
  }
  delete surfMesh;
}
