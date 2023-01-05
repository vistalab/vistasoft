#include "mex.h"
#include "math.h"

/* Coordinates to index */
int mindex3(int x, int y, int z, int sizx, int sizy) { return z*sizx*sizy+y*sizx+x;}
int mindex2(int x, int y, int sizx) { return y*sizx+x;}

/* The matlab mex function */
void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] )
{
    /* All inputs */
    double *FacesA, *FacesB, *FacesC, *VerticesX, *VerticesY, *VerticesZ;
    double *Iterations, *Lambda;
    /* All outputs */
    double *VerticesOX, *VerticesOY, *VerticesOZ;

    /* All outputs, Vertex storage*/
    double *VerticesNX, *VerticesNY, *VerticesNZ;
    double *VerticesN2X, *VerticesN2Y, *VerticesN2Z;
    
        
    /* Temporary Weights */
    double *VerticesW ;
    
    /* Number of faces */
    const mwSize *FacesDims;
    int FacesN=0;
   
    /* Number of vertices */
    const mwSize *VertexDims;
    int VertexN=0;
    int VertexNA[1]={0};    
    
    /* Point Update temporary storage */
    double Ux, Uy, Uz;
    
    /* 1D Index  */
    int index0, index1, index2;
            
    /* Edge coordinates and lenght */
    double e0x, e0y, e0z, e0l;
    double e1x, e1y, e1z, e1l;
    double e2x, e2y, e2z, e2l;
    
    /* Swap point variable */
    double *t;
    int swap=0;
    
    /* Loop variable */
    int i,j;
            
    /* Check for proper number of arguments. */
   if(nrhs!=8) {
     mexErrMsgTxt("8 inputs are required.");
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
   Iterations=mxGetPr(prhs[6]);
   Lambda=mxGetPr(prhs[7]);
   /* Get number of FacesN */
   FacesDims = mxGetDimensions(prhs[0]);   
   FacesN=FacesDims[0]*FacesDims[1];
   
   /* Get number of VertexN */
   VertexDims = mxGetDimensions(prhs[3]);   
   VertexN=VertexDims[0]*VertexDims[1];
   
   /* Intern vertices storage */
   VerticesW = (double *)malloc( VertexN * sizeof(double) );
   VerticesNX = (double *)malloc( VertexN * sizeof(double) );
   VerticesNY = (double *)malloc( VertexN * sizeof(double) );
   VerticesNZ = (double *)malloc( VertexN * sizeof(double) );
   VerticesN2X = (double *)malloc( VertexN * sizeof(double) );
   VerticesN2Y = (double *)malloc( VertexN * sizeof(double) );
   VerticesN2Z = (double *)malloc( VertexN * sizeof(double) );
   
   /* Copy input arrays to ouput vertice arrays */
   memcpy( VerticesNX,VerticesX,VertexN* sizeof(double));
   memcpy( VerticesNY,VerticesY,VertexN* sizeof(double));
   memcpy( VerticesNZ,VerticesZ,VertexN* sizeof(double));
   
   for (j=0; j<Iterations[0]; j++)
   {
       /* Clean the weights */
       for (i=0; i<VertexN; i++) { VerticesW[i] =0;  VerticesN2X[i]=0; VerticesN2Y[i]=0; VerticesN2Z[i]=0; }

       /* Calculate all face normals and angles */
       for (i=0; i<FacesN; i++)
       {
           /* Get indices of face vertices */
           index0=(int)FacesA[i]-1;
           index1=(int)FacesB[i]-1;
           index2=(int)FacesC[i]-1;

           /* Calculate edge lengths */
           e0x=VerticesNX[index0]-VerticesNX[index1];  
           e0y=VerticesNY[index0]-VerticesNY[index1];  
           e0z=VerticesNZ[index0]-VerticesNZ[index1];
           e1x=VerticesNX[index1]-VerticesNX[index2];  
           e1y=VerticesNY[index1]-VerticesNY[index2];  
           e1z=VerticesNZ[index1]-VerticesNZ[index2];
           e2x=VerticesNX[index2]-VerticesNX[index0];  
           e2y=VerticesNY[index2]-VerticesNY[index0];  
           e2z=VerticesNZ[index2]-VerticesNZ[index0];
           e0l=1 / (sqrt(e0x*e0x + e0y*e0y + e0z*e0z)+Lambda[1]);
           e1l=1 / (sqrt(e1x*e1x + e1y*e1y + e1z*e1z)+Lambda[1]);
           e2l=1 / (sqrt(e2x*e2x + e2y*e2y + e2z*e2z)+Lambda[1]);

           VerticesN2X[index0]+=VerticesNX[index1]*e0l;
           VerticesN2Y[index0]+=VerticesNY[index1]*e0l;
           VerticesN2Z[index0]+=VerticesNZ[index1]*e0l;
           VerticesW[index0]+=e0l;

           VerticesN2X[index1]+=VerticesNX[index0]*e0l; 
           VerticesN2Y[index1]+=VerticesNY[index0]*e0l;
           VerticesN2Z[index1]+=VerticesNZ[index0]*e0l;
           VerticesW[index1]+=e0l;


           VerticesN2X[index1]+=VerticesNX[index2]*e1l;
           VerticesN2Y[index1]+=VerticesNY[index2]*e1l;
           VerticesN2Z[index1]+=VerticesNZ[index2]*e1l;
           VerticesW[index1]+=e1l;

           VerticesN2X[index2]+=VerticesNX[index1]*e1l;
           VerticesN2Y[index2]+=VerticesNY[index1]*e1l;
           VerticesN2Z[index2]+=VerticesNZ[index1]*e1l;
           VerticesW[index2]+=e1l;

           VerticesN2X[index2]+=VerticesNX[index0]*e2l;
           VerticesN2Y[index2]+=VerticesNY[index0]*e2l; 
           VerticesN2Z[index2]+=VerticesNZ[index0]*e2l;
           VerticesW[index2]+=e2l;

           VerticesN2X[index0]+=VerticesNX[index2]*e2l; 
           VerticesN2Y[index0]+=VerticesNY[index2]*e2l; 
           VerticesN2Z[index0]+=VerticesNZ[index2]*e2l;
           VerticesW[index0]+=e2l;
       }

       /* Normalize the Vertices */
       for (i=0; i<VertexN; i++)
       {
           Ux=0; Uy=0; Uz=0;
           Ux=VerticesN2X[i]/VerticesW[i];
           Uy=VerticesN2Y[i]/VerticesW[i];
           Uz=VerticesN2Z[i]/VerticesW[i];

           Ux=Ux-VerticesNX[i]; 
           Uy=Uy-VerticesNY[i]; 
           Uz=Uz-VerticesNZ[i]; 

           VerticesN2X[i]=VerticesNX[i]+Ux*Lambda[0]; 
           VerticesN2Y[i]=VerticesNY[i]+Uy*Lambda[0]; 
           VerticesN2Z[i]=VerticesNZ[i]+Uz*Lambda[0];
       }
       
       /* Swap the variables */
       t=VerticesNX; VerticesNX=VerticesN2X; VerticesN2X=t;
       t=VerticesNY; VerticesNY=VerticesN2Y; VerticesN2Y=t;
       t=VerticesNZ; VerticesNZ=VerticesN2Z; VerticesN2Z=t;

       /* Swap output variable */
       if(swap==0) { swap=1; } else { swap=0; }
   }

   /* Create Output arrays for the new vertex coordinates */
   VertexNA[0]=VertexN;
   plhs[0] = mxCreateNumericArray(1, VertexNA, mxDOUBLE_CLASS, mxREAL);
   plhs[1] = mxCreateNumericArray(1, VertexNA, mxDOUBLE_CLASS, mxREAL);
   plhs[2] = mxCreateNumericArray(1, VertexNA, mxDOUBLE_CLASS, mxREAL);
   VerticesOX = mxGetPr(plhs[0]);
   VerticesOY=  mxGetPr(plhs[1]);
   VerticesOZ = mxGetPr(plhs[2]);

   if(swap==0)
   {
        /* Copy input arrays to ouput vertice arrays */
       memcpy( VerticesOX,VerticesN2X,VertexN* sizeof(double));
       memcpy( VerticesOY,VerticesN2Y,VertexN* sizeof(double));
       memcpy( VerticesOZ,VerticesN2Z,VertexN* sizeof(double));
   }
   else
   {
        /* Copy input arrays to ouput vertice arrays */
       memcpy( VerticesOX,VerticesNX,VertexN* sizeof(double));
       memcpy( VerticesOY,VerticesNY,VertexN* sizeof(double));
       memcpy( VerticesOZ,VerticesNZ,VertexN* sizeof(double));
   }
           
   
   /* Free memory */
   free(VerticesW);
   free(VerticesNX);
   free(VerticesNY);
   free(VerticesNZ);
   
   free(VerticesN2X);
   free(VerticesN2Y);
   free(VerticesN2Z);
}
 


