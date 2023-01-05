#include "mex.h"
#include "math.h"

/* 
 * 
 * function [Nx,Ny,Nz]=patchnormals_double(Fa,Fb,Fc,Vx,Vy,Vz)
 *
*/

/* Coordinates to index */
int mindex3(int x, int y, int z, int sizx, int sizy) { return z*sizx*sizy+y*sizx+x;}
int mindex2(int x, int y, int sizx) { return y*sizx+x;}

/* The matlab mex function */
void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] )
{
    /* All inputs */
    double *FacesA, *FacesB, *FacesC, *VerticesX, *VerticesY, *VerticesZ;
    
    /* All outputs, Vertex Normals */
    double *NormalsX, *NormalsY, *NormalsZ;
        
    /* Temporary Face Normals */
    double *FaceNormalsX, *FaceNormalsY, *FaceNormalsZ;
    
    /* Temporary Face angles */
    double *AnglesA,  *AnglesB,  *AnglesC;
    
    /* Number of faces */
    const mwSize *FacesDims;
    int FacesN=0;
   
    /* Number of vertices */
    const mwSize *VertexDims;
    int VertexN=0;
    int VertexNA[1]={0};    
    
    /* 1D Index  */
    int index0, index1, index2;
            
    /* Edge coordinates and lenght */
    double e0x, e0y, e0z, e0l;
    double e1x, e1y, e1z, e1l;
    double e2x, e2y, e2z, e2l;
          
    /* Length of normal */
    double nl;
    
    /* Loop variable */
    int i;
            
    /* Check for proper number of arguments. */
   if(nrhs!=6) {
     mexErrMsgTxt("6 inputs are required.");
   } else if(nlhs!=3) {
     mexErrMsgTxt("3 outputs are required");
   }
   
   /* Read all inputs (faces and vertices) */
   FacesA=mxGetPr(prhs[0]);
   FacesB=mxGetPr(prhs[1]);
   FacesC=mxGetPr(prhs[2]);
   VerticesX=mxGetPr(prhs[3]);
   VerticesY=mxGetPr(prhs[4]);
   VerticesZ=mxGetPr(prhs[5]);

   /* Get number of FacesN */
   FacesDims = mxGetDimensions(prhs[0]);   
   FacesN=FacesDims[0]*FacesDims[1];
   
   /* Get number of VertexN */
   VertexDims = mxGetDimensions(prhs[3]);   
   VertexN=VertexDims[0]*VertexDims[1];
   
   /* Create Output arrays for the Normal coordinates */
   VertexNA[0]=VertexN;
   plhs[0] = mxCreateNumericArray(1, VertexNA, mxDOUBLE_CLASS, mxREAL);
   plhs[1] = mxCreateNumericArray(1, VertexNA, mxDOUBLE_CLASS, mxREAL);
   plhs[2] = mxCreateNumericArray(1, VertexNA, mxDOUBLE_CLASS, mxREAL);
   NormalsX = mxGetPr(plhs[0]);
   NormalsY = mxGetPr(plhs[1]);
   NormalsZ = mxGetPr(plhs[2]);
      

   FaceNormalsX = (double *)malloc( FacesN* sizeof(double) );
   FaceNormalsY = (double *)malloc( FacesN* sizeof(double) );
   FaceNormalsZ = (double *)malloc( FacesN* sizeof(double) );
   
   AnglesA = (double *)malloc( FacesN* sizeof(double) );
   AnglesB = (double *)malloc( FacesN* sizeof(double) );
   AnglesC = (double *)malloc( FacesN* sizeof(double) );
   
   
   /* Calculate all face normals and angles */
   for (i=0; i<FacesN; i++)
   {
       /* Get indices of face vertices */
       index0=(int)FacesA[i]-1;
       index1=(int)FacesB[i]-1;
       index2=(int)FacesC[i]-1;
      
       /* Make edge vectors */
       e0x=VerticesX[index0]-VerticesX[index1];  
       e0y=VerticesY[index0]-VerticesY[index1];  
       e0z=VerticesZ[index0]-VerticesZ[index1];
       
       e1x=VerticesX[index1]-VerticesX[index2];  
       e1y=VerticesY[index1]-VerticesY[index2];  
       e1z=VerticesZ[index1]-VerticesZ[index2];
       
       e2x=VerticesX[index2]-VerticesX[index0];  
       e2y=VerticesY[index2]-VerticesY[index0];  
       e2z=VerticesZ[index2]-VerticesZ[index0];

       /* Normalize the edge vectors */
       e0l = sqrt(e0x*e0x+e0y*e0y+e0z*e0z)+1e-14;
       e0x/=e0l; e0y/=e0l; e0z/=e0l;
       e1l = sqrt(e1x*e1x+e1y*e1y+e1z*e1z)+1e-14; 
       e1x/=e1l; e1y/=e1l; e1z/=e1l;
       e2l = sqrt(e2x*e2x+e2y*e2y+e2z*e2z)+1e-14; 
       e2x/=e2l; e2y/=e2l; e2z/=e2l;

       /* Calculate angles of face seen from vertices */
       AnglesA[i]= acos(e0x*(-e2x)+e0y*(-e2y)+e0z*(-e2z));
       AnglesB[i]= acos(e1x*(-e0x)+e1y*(-e0y)+e1z*(-e0z));
       AnglesC[i]= acos(e2x*(-e1x)+e2y*(-e1y)+e2z*(-e1z));
              
       /* Normal of the face */
       FaceNormalsX[i]=e0y*(e2z) - e0z * (e2y);
       FaceNormalsY[i]=e0z*(e2x) - e0x * (e2z);
       FaceNormalsZ[i]=e0x*(e2y) - e0y * (e2x);
   }
   
   /* Calculate all vertex normals and angles */
   for (i=0; i<FacesN; i++)
   {
       index0=(int)FacesA[i]-1;
       NormalsX[index0]+= FaceNormalsX[i]*AnglesA[i];
       NormalsY[index0]+= FaceNormalsY[i]*AnglesA[i];
       NormalsZ[index0]+= FaceNormalsZ[i]*AnglesA[i];
       index1=(int)FacesB[i]-1;
       NormalsX[index1]+= FaceNormalsX[i]*AnglesB[i];
       NormalsY[index1]+= FaceNormalsY[i]*AnglesB[i];
       NormalsZ[index1]+= FaceNormalsZ[i]*AnglesB[i];
       index2=(int)FacesC[i]-1;
       NormalsX[index2]+= FaceNormalsX[i]*AnglesC[i];
       NormalsY[index2]+= FaceNormalsY[i]*AnglesC[i];
       NormalsZ[index2]+= FaceNormalsZ[i]*AnglesC[i];
   }
    
   /* Normalize the Normals */
   for (i=0; i<VertexN; i++)
   {
       nl= sqrt(NormalsX[i]*NormalsX[i]+NormalsY[i]*NormalsY[i]+NormalsZ[i]*NormalsZ[i])+1e-14; ;
       NormalsX[i]/=nl; NormalsY[i]/=nl; NormalsZ[i]/=nl;
   }

   /* Free memory */
   free(FaceNormalsX);
   free(FaceNormalsY);
   free(FaceNormalsZ);
   free(AnglesA);
   free(AnglesB);
   free(AnglesC);
}
 


