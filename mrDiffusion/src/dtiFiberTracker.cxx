/*********************************************************************
 * 
 *
 * To compile, run:
 *    mex -O -I./jama dtiFiberTracker.cxx
 *
 * HISTORY:
 * 2004.06.23 Bob Dougherty: wrote it, based on code from David Akers.
 * 2004.09.13 RFD: added check for seedPointFA>faThresh. We now avoid
 * abort tracking under such conditions.
 *
 */
#include <mex.h>
#include <matrix.h>
#include <math.h>
// #include <iostream>
// #include <stdlib.h>
// #include <windows.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

#ifndef ROUND
#define  ROUND(f)   ((f>=0)?(int)(f + .5):(int)(f - .5)) 
#endif

#include <tnt_array1d.h>
#include <tnt_array2d.h>
#include <tnt_array1d_utils.h>
#include <tnt_array2d_utils.h>
#include <jama_eig.h>

enum DTIInterpAlgorithm {
  DTI_INTERP_NEAREST = 0,
  DTI_INTERP_LINEAR = 1,
};
//
// Stuff pulled from Akers' DTIUtils/typedef.h 
//
enum DTITractAlgorithm {
  DTI_ALGORITHM_STT_EULER = 0,
  DTI_ALGORITHM_STT_RK4 = 1,
  DTI_ALGORITHM_TENSORLINE_EULER = 2,
  DTI_ALGORITHM_TENSORLINE_RK4 = 3,
};
typedef TNT::Array1D<double> DTIVector;
typedef TNT::Array2D<double> DTITensor;

template <class T> TNT::Array1D<T> operator* (const TNT::Array1D<T> &A, const T & B) {
  TNT::Array1D<T> C(A.dim1());
  for (int i = 0; i < A.dim1(); i++) {
    C[i] = A[i] * B;
  }
  return C;
}

template <class T> TNT::Array1D<T> operator* (const T & B, const TNT::Array1D<T> &A) {
  TNT::Array1D<T> C(A.dim1());
  for (int i = 0; i < A.dim1(); i++) {
    C[i] = A[i] * B;
  }
  return C;
}

inline double dproduct (const TNT::Array1D<double> &A, const TNT::Array1D<double> &B) {
  double sum = 0.0;
  for (int i = 0; i < A.dim1(); i++) {
    sum += A[i] * B[i];
    //std::cerr<< "sum: " << sum << std::endl;
  }
  return sum;
}

template <class T> TNT::Array1D<T> operator- (const TNT::Array1D<T> &A) {
  TNT::Array1D<T> B(A.dim1());
  for (int i = 0; i < A.dim1(); i++) {
    B[i] = -A[i];
  }
  return B;
}
template <class T> TNT::Array1D<T> norm (const TNT::Array1D<T> &A) {
  double mag = abs(A);
  TNT::Array1D<T> B(A.dim1());
  for (int i = 0; i < A.dim1(); i++) {
    B[i] = A[i]/mag;
  }
  return B;
}


template <class T> T TNTabs (const TNT::Array1D<T> &A) {
  T mag = 0;
  for (int i = 0; i < A.dim1(); i++) {
    mag += A[i]*A[i];
  }
  return sqrt (mag);
}


//
// The following class was adapted from Akers' DTIUtil/DTIFiberTractInterface
//
#include <vector>

class DTIFiberTract{
public:

  // Append a segment to the path (adds to END of list)
  void append (const DTIVector &vec){
    double *v = new double[3];
    v[0] = vec[0];
    v[1] = vec[1];
    v[2] = vec[2];
    //DTIVector *copy = new DTIVector(3, v);
    _point_vector.push_back(v);
  }

  // Prepend a segment to the path (adds to BEGINNING of list)
  void prepend (const DTIVector &vec){
    double *v = new double[3];
    v[0] = vec[0];
    v[1] = vec[1];
    v[2] = vec[2];
    //DTIVector *copy = new DTIVector(3,v);
    _point_vector.insert(_point_vector.begin(), v);
  }

  // retrieve the x,y,z coords of a point in the pathway, by its index.
  void getPoint (int index, double pt[3]){
    assert (index <= getNumPoints()-1 && index >= 0);
    double *v = (_point_vector[index]);
    pt[0] = v[0];
    pt[1] = v[1];
    pt[2] = v[2];
  }

  bool popPoint (double pt[3]){
    if(getNumPoints()<1) return false;
     double *v = (_point_vector[getNumPoints()-1]);
     pt[0] = v[0];
     pt[1] = v[1];
     pt[2] = v[2];
 		_point_vector.pop_back();
		return(true);
  }

	void clear(){
		// Destroy all elements
		for(int i=0; i<getNumPoints(); i++){
			delete(_point_vector[i]);
		}
		_point_vector.clear();
	}

  // Get number of points in the pathway.
  int getNumPoints(){ return (int)_point_vector.size(); }

  // Sets the index of the seed point:
  void setSeedPointIndex (int index) { _seed_point_index = index; }
  int getSeedPointIndex() { return _seed_point_index; }

protected:
  int _seed_point_index;
  std::vector <double *> _point_vector;
};

//
// Several of the following routines were pulled from Akers' DTIFiberTractTracer class.
//
void getMajorEigenvector(const DTITensor &tensor, DTIVector result){
  // use jama to compute eigenvectors, eigenvalues of tensor.
  // pick the largest magnitude eigenvalue and return corresponding 
  // eigenvector.
  TNT::Array1D<double> eigenvalues;
  JAMA::Eigenvalue<double> eig(tensor);
  eig.getRealEigenvalues (eigenvalues);
  int index = 0;
  double largest = fabs (eigenvalues[0]);
  for (int i = 1; i < 3; i++) {
    if (fabs(eigenvalues[i]) > largest) {
      largest = fabs(eigenvalues[i]);
      index = i;
    }
  }
  TNT::Array2D<double> eigenvectors;
  eig.getV (eigenvectors);
  result[0] = eigenvectors[0][index];
  result[1] = eigenvectors[1][index];
  result[2] = eigenvectors[2][index];
}

double getFa(const DTITensor &tensor){
  TNT::Array1D<double> ev;
  JAMA::Eigenvalue<double> eig(tensor);
  eig.getRealEigenvalues(ev);
  double fa;
  //mexPrintf("eigVal = [ %f %f %f ]\n", ev[0], ev[1], ev[2]);

  // compute norm diffusivity
  double nd = sqrt(ev[0]*ev[0] + ev[1]*ev[1] + ev[2]*ev[2]);
  if(nd<0.000001){
    fa = 0;
  }else{
    // Compute mean and stdev of the diffusivity
    double md = (ev[0]+ev[1]+ev[2])/3.0;
    double sd = sqrt((ev[0]-md)*(ev[0]-md) + (ev[1]-md)*(ev[1]-md) + (ev[2]-md)*(ev[2]-md));
    // 1.2... is sqrt(3/2)
    fa = 1.224744871392*(sd/nd);
  }
  return(fa);
}

void getTensorInterpolate(double *dt6, int dims[], DTIVector seedPoint, DTIInterpAlgorithm interpAlgo, DTITensor result){
  double dt[6];
  int skip3 = dims[0]*dims[1]*dims[2];
  int skip2 = dims[0]*dims[1];
  int skip1 = dims[0];
	int ii;
  if(interpAlgo==DTI_INTERP_NEAREST){
    // Nearest-neighbor
    int	x0, y0, z0;
    
    // Find a good round.  That's what this should be.
		x0 = (int) ROUND(seedPoint[0]);
		y0 = (int) ROUND(seedPoint[1]);
		z0 = (int) ROUND(seedPoint[2]);
		for(ii=0;ii<6;ii++){ dt[ii] = dt6[x0+y0*skip1+z0*skip2+ii*skip3]; }
  }else{
    // Tri-linear
    int	x0, y0, z0, x1, y1, z1;
    double wx, wy, wz, dx00, dx01, dx10, dx11, dxy0, dxy1;
    double d000, d001, d010, d011, d100, d101, d110, d111;

    x0 = (int)floor(seedPoint[0]); 
    wx = seedPoint[0] - x0;
    y0 = (int)floor(seedPoint[1]);
    wy = seedPoint[1] - y0;
    z0 = (int)floor(seedPoint[2]);
    wz = seedPoint[2] - z0;
    x1 = x0 + 1;
    y1 = y0 + 1;
    z1 = z0 + 1;
    // deal with edges.
    if(x0==-1) x0=0; if(y0==-1) y0=0; if(z0==-1) z0=0;
    if(x1==dims[0]) x1=dims[0]-1; if(y1==dims[1]) y1=dims[1]-1; if(z1==dims[2]) z1=dims[2]-1;
    
    if (x0>=0 && x1<dims[0] && y0>=0 && y1<dims[1] && z0>=0 && z1<dims[2]){
      for(ii=0;ii<6;ii++){
				d000 = dt6[x0+y0*skip1+z0*skip2+ii*skip3];
				d100 = dt6[x1+y0*skip1+z0*skip2+ii*skip3];
				d010 = dt6[x0+y1*skip1+z0*skip2+ii*skip3];
				d110 = dt6[x1+y1*skip1+z0*skip2+ii*skip3];
				d011 = dt6[x0+y1*skip1+z1*skip2+ii*skip3];
				d111 = dt6[x1+y1*skip1+z1*skip2+ii*skip3];
				d001 = dt6[x0+y0*skip1+z1*skip2+ii*skip3];
				d101 = dt6[x1+y0*skip1+z1*skip2+ii*skip3];
				// take weighted mean
				// To save a few ops, we use l+w*(h-l), which is equivalent to (w*h)+((1-w)*l)
				dx00 = d000 + wx*(d100-d000);
				dx01 = d001 + wx*(d101-d001);
				dx10 = d010 + wx*(d110-d010);
				dx11 = d011 + wx*(d111-d011);
				dxy0 = dx00 + wy*(dx10-dx00);
				dxy1 = dx01 + wy*(dx11-dx01);
				dt[ii] = dxy0 + wz*(dxy1-dxy0);
      }
    }else{
      for(ii=0;ii<6;ii++) dt[ii] = 0;
      // *** FIX ME: deal with out-of-range requests more elegantly!
    }
  }
  result[0][0] = dt[0];
  result[1][1] = dt[1];
  result[2][2] = dt[2];
  result[0][1] = dt[3];
  result[0][2] = dt[4];
  result[1][2] = dt[5];
  result[1][0] = dt[3];
  result[2][0] = dt[4];
  result[2][1] = dt[5];
}

bool inBounds(const DTIVector &pt, int dims[]){
  if (pt[0] < 0 || pt[0] > dims[0]-1 ||
      pt[1] < 0 || pt[1] > dims[1]-1 ||
      pt[2] < 0 || pt[2] > dims[2]-1)
    return false;
  else 
    return true;
}

bool checkAngle(const DTIVector &a, const DTIVector &b, double angleThresh, int &direction, double &angle){
  // Checks the angle between 2 vectors, returns if angle is less than thresh
  // The angle between two vectors is given by acos(aDOTb/{mag(a)*mag(b)})  
  // Also returns a direction-flip flag. Remember- we have vectors but PDDs 
  // are really axes ([x,y,z] is equivalent to -[x,y,z]), so if the angle is
  // >90 deg, we indicate that the direction of one of the vectors should be
  // flipped by setting direction to -1. 
  // Finally, the actual angle is returned, in case you care. (Note that the
  // returned angle assumes that you will heed the direction flip flag- ie, it
  // is always <90.)

  double dprod = dproduct(a,b);
  if (dprod > 1.0) dprod = 1.0;
  if (dprod < -1.0) dprod = -1.0;

  bool angleCheck;
  angle = 180*acos(dprod)/M_PI; // In degrees; both vectors are unit vectors
  if(angle>90){
    angle = 180-angle;
    direction = -1;
  }else{
    direction = 1;
  }
 
  if(angle<=angleThresh) {
    angleCheck = true; // Angle is within permissable range
  }else{
    angleCheck = false;
  }
  return angleCheck;
}

void getRK4(double *dt6, int dims[], DTIInterpAlgorithm interpAlgo, DTIVector &k1Dir, const DTIVector &k1Position, const DTIVector &stepSize){
  // Do 4th order Runge-Kutta path integration.
	// Result is returned in k1Dir.
  DTIVector k2Position(3);
  DTIVector k3Position(3);
  DTIVector k4Position(3);
	DTIVector k2Dir(3);
	DTIVector k3Dir(3);
	DTIVector k4Dir(3);
	DTITensor tensor(3,3);

  k2Position = k1Position + stepSize*k1Dir*0.5;
	getTensorInterpolate(dt6, dims, k2Position, interpAlgo, tensor);
  getMajorEigenvector(tensor, k2Dir);
  int direction;
  double angle;
  if (checkAngle(k1Dir, k2Dir, 90.0, direction, angle) && direction == -1) {
    k2Dir = -k2Dir;
    //printf("k2angle=%0.2f\n",angle);
  }
  k3Position = k1Position + stepSize*k2Dir*0.5;
	getTensorInterpolate(dt6, dims, k3Position, interpAlgo, tensor);
  getMajorEigenvector(tensor, k3Dir);
  if (checkAngle(k1Dir, k3Dir, 90.0, direction, angle) && direction == -1) {
    k3Dir = -k3Dir;
  }
  k4Position = k1Position + stepSize*k3Dir;
	getTensorInterpolate(dt6, dims, k4Position, interpAlgo, tensor);
  getMajorEigenvector(tensor, k4Dir);
  if (checkAngle(k1Dir, k4Dir, 90.0, direction, angle) && direction == -1) {
    k4Dir = -k4Dir;
  }
  // In RK4, the step vector is a weighted average of the four derivatives
  k4Dir = 1.0/6.0 * (k1Dir + k2Dir*2.0 + k3Dir*2.0 + k4Dir);
  //printf("k4Dir=[%0.4f %0.4f %0.4f]; angle=%0.2f\n",k4Dir[0],k4Dir[1],k4Dir[2],angle);
	// Return the result 
	k1Dir = k4Dir.copy();
}


/*************************************************************************
 * Function Name: trackFiber
 * Returns: DTIFiberTract *fiberPath
 * Effects: Step size is in mm, vox size is in mm (each dimension) seed point
 *          is in voxel space.
 * Note that maxNumSteps specifies the maximum number of fiber steps to take in each direction (<=0 for no limit).
 *************************************************************************/
void trackFiber(int dims[], double *dt6, const DTIVector &seedPoint, const DTIVector &voxSize, double faThresh, double angleThresh, double stepSizeMm, double wPuncture, DTITractAlgorithm algo, DTIInterpAlgorithm interpAlgo, DTIFiberTract *fiberPath, int maxNumSteps){
  static int tractCounter = 0;
  tractCounter++;
  int seedPointIndex = 0;
  fiberPath->append(seedPoint);

	if(maxNumSteps<=0) maxNumSteps = 1000; 

	DTIVector stepSize(3);
	DTITensor seedPointTensor(3,3);
	DTIVector originalDir(3);
	DTIVector currentPosition(3);
	DTIVector nextDir(3);
	DTIVector dir(3);
	DTIVector nextPosition(3);
	DTITensor nextTensor(3,3);
	DTIVector sttDir(3);
	TNT::Array2D<double> dirArray2D(3,1);
	TNT::Array2D<double> tendDir2D(3,1);
	DTIVector tendDir(3);
  for (int directionToTrace = 0; directionToTrace < 2; directionToTrace++) {
    int iter = 0;
    bool done = false;
    int x, y, z;
    x = dims[0]; y = dims[1]; z = dims[2];
    
    if(!inBounds(seedPoint, dims)) return;

    stepSize = voxSize.copy();
    
    stepSize[0] = stepSizeMm / stepSize[0];
    stepSize[1] = stepSizeMm / stepSize[1];
    stepSize[2] = stepSizeMm / stepSize[2];
    
    getTensorInterpolate(dt6, dims, seedPoint, interpAlgo, seedPointTensor);
    if(getFa(seedPointTensor)<=faThresh) return;

    getMajorEigenvector(seedPointTensor, originalDir);
    
    if (directionToTrace == 0){
      nextDir = originalDir.copy();
    }else{
      nextDir = -originalDir.copy();
    }
    if(algo==DTI_ALGORITHM_STT_RK4 || algo==DTI_ALGORITHM_TENSORLINE_RK4){
      getRK4(dt6, dims, interpAlgo, nextDir, seedPoint, stepSize);
    }
    
    nextPosition = seedPoint.copy();

    double curFa;
    nextTensor = seedPointTensor.copy();
    
    int direction;
    double angle;
    bool smallAngle;
    static const double EPSILON = 0.001;
    while (!done && iter < maxNumSteps) {
      dir = nextDir.copy();
      currentPosition = nextPosition.copy();
      if (!inBounds (currentPosition, dims)) {
				done = true;
      }
      else {
	// Get the FA for this point (nextTensor is initialized above and gets updated below)
	curFa = getFa(nextTensor);
	if (curFa <= faThresh || fabs(dir[0]) + fabs(dir[1]) + fabs(dir[2]) < EPSILON) {
	  done = true;
	  break;
	}

	nextPosition = currentPosition + dir*stepSize;
	getTensorInterpolate(dt6, dims, nextPosition, interpAlgo, nextTensor);

	// Begin with an Euler method estimate of the path direction
	getMajorEigenvector(nextTensor, sttDir);

	// Make sure we're going in the right direction 
	smallAngle = checkAngle(dir, sttDir, angleThresh, direction, angle);
	if (smallAngle && direction == -1) {
	  sttDir = -sttDir;
	}

	// If requested, use 4th order Runge-Kutta to refine path estimate
	if(algo==DTI_ALGORITHM_STT_RK4 || algo==DTI_ALGORITHM_TENSORLINE_RK4){
	  getRK4(dt6, dims, interpAlgo, sttDir, nextPosition, stepSize);
	}

	if (algo==DTI_ALGORITHM_TENSORLINE_EULER || algo==DTI_ALGORITHM_TENSORLINE_RK4) {
	  // Need to convert dir to an Array2D
	  dirArray2D[0][0] = dir[0];
	  dirArray2D[1][0] = dir[1];
	  dirArray2D[2][0] = dir[2];
	  tendDir2D = TNT::matmult(nextTensor, dirArray2D);
				
	  tendDir[0] = tendDir2D[0][0];
	  tendDir[1] = tendDir2D[0][1];
	  tendDir[2] = tendDir2D[0][2];
				
	  double mag = TNTabs(tendDir);
				
	  if (mag > EPSILON) {
	    tendDir[0] /= mag;
	    tendDir[1] /= mag;
	    tendDir[2] /= mag;
	  }
	  tendDir = tendDir*stepSize;	
	  double tendAngle = 180*acos(dproduct(tendDir,dir))/M_PI; 
	  if (!smallAngle) {
	    nextDir = (1-wPuncture)*dir + wPuncture * tendDir;
	  }
	  else {
	    nextDir = curFa*sttDir + (1-curFa)* ((1-wPuncture)*dir + wPuncture*tendDir);
	  }
	}
	else if (algo==DTI_ALGORITHM_STT_EULER || algo==DTI_ALGORITHM_STT_RK4) {
	  // pure STT
	  if (!smallAngle) {
	    done = true;
	    //	std::cerr << "Tracking terminated: angle (" << angle << ") exceeds threshold." << std::endl;
	  }
	  else {
	    nextDir = sttDir.copy();
	    //double sttAngle = 180*acos(dproduct(sttDir,dir))/M_PI; 
	  }
	}
	if (directionToTrace == 0 && inBounds(nextPosition, dims)) {
	  fiberPath->append(nextPosition);
	}
	else if (directionToTrace == 1 && inBounds (nextPosition, dims)) {
	  fiberPath->prepend(nextPosition);
	  seedPointIndex++;
	}
	iter++;
      }
    }
  }
  fiberPath->setSeedPointIndex(seedPointIndex);
}



/*********************************************************************
 * MEX FUNCTION
 *
 * Entry point for MEX function
 */
extern "C" void mexFunction(int nlhs, mxArray *plhs[],
                            int nrhs, const mxArray *prhs[]){
  /* Check number of arguments */
  if(nrhs < 9 || nrhs > 11){
    mexErrMsgTxt("9-11 inputs required.");
    return;
  }
  if(nlhs != 1){
    mexErrMsgTxt("Exactly one output required.");
    return;
  }

	// CHECK ARG 1
  if(!mxIsDouble(prhs[0]) || mxIsComplex(prhs[0]) || mxGetNumberOfDimensions(prhs[0]) != 4){
     mexErrMsgTxt("Arg 1 must be a real XxYxZx6 array (not real|double|dims).");
    return;
  }
	// CHECK ARG 2
  if(!mxIsDouble(prhs[1]) || mxIsComplex(prhs[1]) || mxGetNumberOfDimensions(prhs[1]) != 2 
     || mxGetM(prhs[1])!=3){
    mexErrMsgTxt("Arg 2 must be a *real* *3xN*  *double* array of seed points.");
    return;
  }
	// CHECK ARG 3
  if(!mxIsDouble(prhs[2]) || mxIsComplex(prhs[2]) || mxGetNumberOfDimensions(prhs[2])!=2 || 
     mxGetM(prhs[2])!=3 || mxGetN(prhs[2])!=1){
    mexPrintf("dims = %d, rows = %d\n", mxGetNumberOfDimensions(prhs[2]), mxGetM(prhs[2]));
    mexErrMsgTxt("Arg 3 must be a *real* 3x1 *double* array specifying the voxel size (in mm).");
    return;
  }
  // CHECK ARG 4
  if(!mxIsNumeric(prhs[3]) || mxGetNumberOfDimensions(prhs[3])!=2 || mxGetM(prhs[3])!=1 || 
     mxGetN(prhs[3])!=1 || (mxGetScalar(prhs[3])<0 || mxGetScalar(prhs[3])>3)){
    mexErrMsgTxt("Arg 4 must be a scalar specifying the algorithm type (0 for STT_EULER, 1 for STT_RK4, 2 for TL_EULER, 3 for TL_RK4).");
    return;
  }
  // CHECK ARG 5
  if(!mxIsNumeric(prhs[4]) || mxGetNumberOfDimensions(prhs[4])!=2 || mxGetM(prhs[4])!=1 || mxGetN(prhs[4])!=1 
     || (mxGetScalar(prhs[4])!=DTI_INTERP_NEAREST && mxGetScalar(prhs[4])!=DTI_INTERP_LINEAR)){
    mexErrMsgTxt("Arg 5 must be a scalar specifying the interpolation type (0 for NN, 1 for linear).");
    return;
  }
  // CHECK ARG 6
  if(!mxIsDouble(prhs[5]) || mxIsComplex(prhs[5]) || mxGetNumberOfDimensions(prhs[5])!=2 
     || mxGetM(prhs[5])!=1 || mxGetN(prhs[5])!=1){
    mexErrMsgTxt("Arg 6 must be a real scalar specifying the step size in mm (eg. 1.0).");
    return;
  }
  // CHECK ARG 7
  if(!mxIsDouble(prhs[6]) || mxIsComplex(prhs[6]) || mxGetNumberOfDimensions(prhs[6])!=2 
     || mxGetM(prhs[6])!=1 || mxGetN(prhs[6])!=1){
    mexErrMsgTxt("Arg 7 must be a real scalar specifying the FA threshold (eg. 0.15).");
    return;
  }
  // CHECK ARG 8
  if(!mxIsDouble(prhs[7]) || mxIsComplex(prhs[7]) || mxGetNumberOfDimensions(prhs[7])!=2 
     || mxGetM(prhs[7])!=1 || mxGetN(prhs[7])!=1){
    mexErrMsgTxt("Arg 8 must be a real scalar specifying the angle threshold in degrees (eg. 45.0).");
    return;
  }
  // CHECK ARG 9
  if(!mxIsDouble(prhs[8]) || mxIsComplex(prhs[8]) || mxGetNumberOfDimensions(prhs[8])!=2 
     || mxGetM(prhs[8])!=1 || mxGetN(prhs[8])!=1){
    mexErrMsgTxt("Arg 9 must be a real scalar specifying the puncture threshold (for TensorLines only, eg. 0.20).");
    return;
  }
	// CHECK & GET ARG 9 (optional)
	double minFiberLength;
	double maxFiberLength;
  double *tmpPtr;
	if(nrhs < 10){
		minFiberLength = 20;
		maxFiberLength = 0;
	}else{
		if(!mxIsDouble(prhs[9]) || mxIsComplex(prhs[9]) || mxGetNumberOfDimensions(prhs[9])!=2 || mxIsEmpty(prhs[9])){
			mexErrMsgTxt("Arg 10 must be a real scalar specifying the minimum fiber length or a 1x2 specifying the minimum and maximum fiber lengths in mm (eg. [20.0 100.0]).");
			return;
		}
		minFiberLength = mxGetScalar(prhs[9]);
		if(mxGetM(prhs[9])>1 || mxGetN(prhs[9])>1){
			tmpPtr = (double*)mxGetPr(prhs[9]);
			maxFiberLength = tmpPtr[1];
		}else{
			maxFiberLength = 0;
		}
	}
	// CHECK & GET ARG 10 (optional)
	double *fiberCoordXform;
	if(nrhs < 11){
		fiberCoordXform = NULL;
	}else{
		if(!mxIsDouble(prhs[10]) || mxIsComplex(prhs[10]) || mxGetNumberOfDimensions(prhs[10])!=2 
       || mxGetM(prhs[10])!=4 || mxGetN(prhs[10])!=4){
			mexErrMsgTxt("Arg 11 must be a 4x4 Affine transform matrix to be applied to each fiber coord.");
			return;
		}
		fiberCoordXform = (double*)mxGetPr(prhs[10]);
	}

  /* Input matrices */
  const int *dt6Dims = mxGetDimensions(prhs[0]);
  const int *seedDims = mxGetDimensions(prhs[1]);
  double *dt6Ptr = (double*)mxGetPr(prhs[0]);
  double *seedPtr = (double*)mxGetPr(prhs[1]);
	
  int ii, jj;
	
  /* Double-check the input size */
  if(dt6Dims[3] != 6){
    mexErrMsgTxt("First arg must be a real XxYxZx6 array (dim(4) not 6).");
    return;
  }
  if(seedPtr!=NULL && seedDims[0]!=3){
    mexErrMsgTxt("Second arg must be a real *3xN* array (or empty, to seed all voxels).");
    return;
  }
	
  int numFibers=0;
  int dims[3] = {dt6Dims[0],dt6Dims[1],dt6Dims[2]};
  DTIVector seedPoint;
  double *mmScale = (double*)mxGetPr(prhs[2]);
  DTIVector voxSize(3, mmScale);
  DTITractAlgorithm algo = (DTITractAlgorithm) ROUND(mxGetScalar(prhs[3]));
  DTIInterpAlgorithm interp = (DTIInterpAlgorithm)ROUND(mxGetScalar(prhs[4]));
  double stepSizeMm = mxGetScalar(prhs[5]);
  double faThresh = mxGetScalar(prhs[6]);
  double angleThresh = mxGetScalar(prhs[7]);
  double wPuncture = mxGetScalar(prhs[8]);
	int progressStep = (int)ceil(seedDims[1]/80.0);
	int minFiberLengthSeg = (int)ceil(minFiberLength/stepSizeMm);
	if(minFiberLengthSeg<=1) minFiberLengthSeg = 3;
	// Max number of steps to take in each direction is half of maxLen
	int maxNumSteps = (int)ceil(maxFiberLength/2.0/stepSizeMm);
  mexPrintf("\nscale=[%0.1f,%0.1f,%0.1f]mm, track=%d, interp=%d, step=%0.1fmm, fa=%0.2f, angle=%0.1fdeg, puncture=%0.2f, minLength=%0.1fmm, maxLength=%0.1fmm\n",
	    mmScale[0],mmScale[1],mmScale[2],(int)algo,(int)interp,stepSizeMm,faThresh,angleThresh,wPuncture,minFiberLength,maxFiberLength);
  if(seedPtr!=NULL){
		mexPrintf("Tracking %d fibers (%d fibers per tick):\n", seedDims[1], progressStep);
		DTIFiberTract *fibers = new DTIFiberTract;
    plhs[0] = mxCreateCellArray(1, &seedDims[1]);
		DTIVector seed(3);
    for (ii = 0; ii < seedDims[1]; ii++) {
			if(ii%progressStep==0){ //mexPrintf("\b\b\b%0.0f", ii/progressStep*100.0);
				//mexPrintf("Tracked %d out of %d...\n", ii, seedDims[1]);
				mexEvalString("fprintf('.'); drawnow;");
			}
			seed[0] = seedPtr[ii*3]; seed[1] = seedPtr[ii*3+1]; seed[2] = seedPtr[ii*3+2];
      trackFiber(dims, dt6Ptr, seed, voxSize, faThresh, angleThresh, stepSizeMm, wPuncture, algo, interp, fibers, maxNumSteps);
      if(fibers->getNumPoints()>=minFiberLengthSeg){
				mxArray *tmpArray = mxCreateDoubleMatrix(3, fibers->getNumPoints(), mxREAL);
				tmpPtr = mxGetPr(tmpArray);
				if(fiberCoordXform==NULL){
					for (jj=0; jj<fibers->getNumPoints(); jj++) {
						fibers->getPoint(jj, tmpPtr);
						tmpPtr+=3;
					}
				}else{
				  static double transformedPoint[3];
				  
					for (jj=0; jj<fibers->getNumPoints(); jj++) {
						fibers->getPoint(jj, tmpPtr);
						// We have to convert from c-style zero-indexing to matlab's 1-indexing of the
						// image coords before applying the transform.
						tmpPtr[0]++; tmpPtr[1]++; tmpPtr[2]++;
						// Simple matrix multiplication (pre-multiply convention)
						transformedPoint[0] = fiberCoordXform[0]*tmpPtr[0] + fiberCoordXform[4]*tmpPtr[1] 
							        + fiberCoordXform[8]*tmpPtr[2] + fiberCoordXform[12];
						transformedPoint[1] = fiberCoordXform[1]*tmpPtr[0] + fiberCoordXform[5]*tmpPtr[1] 
							        + fiberCoordXform[9]*tmpPtr[2] + fiberCoordXform[13];
						transformedPoint[2] = fiberCoordXform[2]*tmpPtr[0] + fiberCoordXform[6]*tmpPtr[1] 
							        + fiberCoordXform[10]*tmpPtr[2] + fiberCoordXform[14];
						tmpPtr[0] = transformedPoint[0];
						tmpPtr[1] = transformedPoint[1];
						tmpPtr[2] = transformedPoint[2];
						tmpPtr+=3;
					}
				}
				mxSetCell(plhs[0],ii,tmpArray);
				numFibers++;
      }
			fibers->clear();
    }
    mexPrintf("\n%d fibers passed length threshold of %0.1f (out of %d seeds).\n", numFibers, minFiberLength, seedDims[1]);
		delete fibers;
  }
}
