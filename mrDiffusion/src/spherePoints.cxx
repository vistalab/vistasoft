/* C-Mex implementation for spherePoints.cxx
 *
 * To compile on most platforms, run:
 *    mex -O spherePoints.cxx
 *
 * To compile under linux with gcc, run:
 *    mex -O COPTIMFLAGS='-O3 -march=i686 -DNDEBUG' spherePoints.cxx
 *
 * Original code was lifted from;
 * http://www.math.niu.edu/~rusin/known-math/96/repulsion
 * Vladimir Bulatov <V.Bulatov@ic.ac.uk>
 * Newsgroups: comp.graphics.algorithms,sci.math
 * Subject: Re: ANNOUNCE: Point repulsion / sphere tesselation code available
 * Date: 12 Feb 1996 12:45:28 GMT
 * 
 * 2004.?? RFD: mexified the core algorithm and added rotation to place the
 *         first point at 1,0,0.
 * 2005.11.29 RFD: added code to do dipoles rather than points. We can now
 *            properly avoid colinear directions. Simple testing shows that
 *            it works. Eg, for 6 points, we always return half of a regular
 *            icosahedron, which is the optimal 6-dir scheme.
 * 2005.11.30 RFD: wasn't guaranteeing that the dipoles remained dipoles! This
 *            worked OK for some N's (the forces will keep some configurations
 *            in a dipole arrangement no matter what), but not for all N. Now
 *            we guarantee the dipole arrangement, but now the algorithm doesn't 
 *            always converge. It gets close enough- just run it a few times and
 *            pick the best run. To fix this, we need to more intelligently
 *            compute the forces to account to for the dipoles.
 */

#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <math.h>
#include <mex.h>

typedef double vec3[3];

double frand(void){return ((rand()-(RAND_MAX/2))/(RAND_MAX/2.));}

double dot(vec3 v1,vec3 v2){ return v1[0]*v2[0]+v1[1]*v2[1]+v1[2]*v2[2];}

double length(vec3 v){  return sqrt(v[0]*v[0]+v[1]*v[1]+v[2]*v[2]); }

double length(vec3 v1,vec3 v2)
{
  vec3 v;
  v[0] = v2[0] - v1[0]; v[1] = v2[1] - v1[1]; v[2] = v2[2] - v1[2];
  return length(v);
}

double get_coulomb_energy(int N,vec3 p[])
{
  double e = 0;
  for(int i = 0;i<N;i++)  
    for(int j = i+1; j<N; j++ ) {
      e += 1/ length(p[i],p[j]);
    }
  return e;
}

void get_forces(int N, vec3 f[], vec3 p[])
{
  int i,j;
  for(i = 0;i<N;i++){
    f[i][0] = 0;f[i][1] = 0;f[i][2] = 0;
  }
  for(i = 0;i<N;i++){
    for(j = i+1; j<N; j++ ) {
      vec3 r = {p[i][0]-p[j][0],p[i][1]-p[j][1],p[i][2]-p[j][2]};
      double l = length(r); l = 1/(l*l*l);
      double ff;
      ff = l*r[0]; f[i][0] += ff; f[j][0] -= ff;
      ff = l*r[1]; f[i][1] += ff; f[j][1] -= ff;
      ff = l*r[2]; f[i][2] += ff; f[j][2] -= ff;
    }
  }
}


/*********************************************************************
 * Entry point for MEX function
*/
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]){
  int N, i, j, k;
  static int Nstep=2000;
  static double step=0.01;
  static double minimal_step=1.e-10;
  static bool dipole = true;

	/* Check number of arguments */
	if(nrhs != 1){
		mexErrMsgTxt("One input required.");
		exit(-1);
	}else if (!mxIsDouble(prhs[0]) || mxIsComplex(prhs[0]) ||
						 mxGetNumberOfDimensions(prhs[0]) != 2){
		printf("%d\n", mxGetNumberOfDimensions(prhs[0]));
		mexErrMsgTxt("Input must be a real scalar array.");
		exit(-1);
	}

  N = (int)mxGetScalar(prhs[0]);
  if(dipole) N = N*2;
  vec3 *p0 = new vec3[N];
  vec3 *p1 = new vec3[N];
  vec3 *f = new vec3[N];
  vec3 *pp0 = p0, *pp1 = p1;

  srand(time(NULL));
  
	mexPrintf("\nProcessing %d points...",N);

	// Initialize locations
  for(i = 0; i<N; i++ ) {
    if(dipole && i>=N/2){
       p0[i][0] = -p0[i-N/2][0];
       p0[i][1] = -p0[i-N/2][1];
       p0[i][2] = -p0[i-N/2][2];
    }else{
        p0[i][0] = 2*frand();
        p0[i][1] = 2*frand();
        p0[i][2] = 2*frand();
        double l = length(p0[i]);
        if(l!=0.0){
            p0[i][0] /= l;
            p0[i][1] /= l;
            p0[i][2] /= l;
        }else{
            i--;
        }
    }
  }

  double e0 = get_coulomb_energy(N,p0);
  double e;
  for(k = 0;k<Nstep;k++) {
    if(k%100==0){ mexEvalString("fprintf('.'); drawnow;"); }
    get_forces(N,f,p0);
    for(i=0; i<N; i++){
       if(dipole && i>=N/2){
          pp1[i][0] = -pp0[i-N/2][0];
          pp1[i][1] = -pp0[i-N/2][1];
          pp1[i][2] = -pp0[i-N/2][2];
       }else{
          double d = dot(f[i],pp0[i]);
          f[i][0]  -= pp0[i][0]*d;
          f[i][1]  -= pp0[i][1]*d;
          f[i][2]  -= pp0[i][2]*d;
          pp1[i][0] = pp0[i][0]+f[i][0]*step;
          pp1[i][1] = pp0[i][1]+f[i][1]*step;
          pp1[i][2] = pp0[i][2]+f[i][2]*step;
       }
       double l = length(pp1[i]);
       pp1[i][0] /= l;
       pp1[i][1] /= l;
       pp1[i][2] /= l;
    }
    e = get_coulomb_energy(N,pp1);
    if(e >= e0){  // not successfull step
      step /= 2;
      if(step < minimal_step)
				break;
      continue;
    }else{   // successfull step
       vec3 *t = pp0;
       pp0 = pp1; 
       pp1 = t;      
       e0 = e;
       step*=2;
    }      
  }
  e0 = get_coulomb_energy(N,p0);
  //mexPrintf("\n[");
  //for(i = 0;i<N;i++)mexPrintf("%0.4f, %0.4f, %0.4f;", p0[i][0], p0[i][1], p0[i][2]);
  //mexPrintf("]\n");

  // Rotate all the points so that the first point is at 1,0,0.
  double u[3], v[3], w[3], s;
  u[0] = p0[0][0]; u[1] = p0[0][1]; u[2] = p0[0][2];
  // v is a unit vector perpendicular to the first point (u):
  s = sqrt(u[0]*u[0] + u[1]*u[1]);
  v[0] = -u[1]/s; v[1] = u[0]/s; v[2] = 0.0;
  // w is a unit vector perpendicular to u and v (cross(u,v)):
  w[0] = u[1]*v[2]-u[2]*v[1];
  w[1] = u[2]*v[0]-u[0]*v[2];
  w[2] = u[0]*v[1]-u[1]*v[0];
  //mexPrintf("u=[%0.4f %0.4f %0.4f]; v=[%0.4f %0.4f %0.4f]; w=[%0.4f %0.4f %0.4f];\n", 
  //					u[0],u[1],u[2],v[0],v[1],v[2],w[0],w[1],w[2]);
  // apply the transform matrix [u; v; w] to all the points ([u; v; w]*p0)
  double pt0, pt1;
  for(i=0; i<N; i++) {
     pt0 = p0[i][0]*u[0] + p0[i][1]*u[1] + p0[i][2]*u[2];
     pt1 = p0[i][0]*v[0] + p0[i][1]*v[1] + p0[i][2]*v[2];
     p0[i][2] = p0[i][0]*w[0] + p0[i][1]*w[1] + p0[i][2]*w[2];
 		 p0[i][0] = pt0; p0[i][1] = pt1;
 	}
  e = get_coulomb_energy(N,p0);
  mexPrintf("\nFinal couloumb energy: %0.4f (%0.4f before rotation).\n\n", e, e0);
  
  if(dipole){
    // Only return the non-colinear points
    N=N/2;
    // Try to redistribute the points uniformly
    e0 = e;
    for(i=0; i<N; i++){
        for(j=0; j<3; j++) p0[i][j] = -p0[i][j];
        e = get_coulomb_energy(N,p0);
        if(e>e0) for(j=0; j<3; j++) p0[i][j] = -p0[i][j];
        else e0 = e;
    }
    mexPrintf("\nFinal couloumb energy after dipole elimination: %0.4f.\n\n", e0);
  }
  plhs[0] = mxCreateDoubleMatrix(3,N,mxREAL);
  double *outPtr = mxGetPr(plhs[0]);
  for(i=0; i<N; i++){
    *outPtr++ = p0[i][0];
	*outPtr++ = p0[i][1];
	*outPtr++ = p0[i][2];
  }

  delete[] p0;
  delete[] p1;
  delete[] f;
}
