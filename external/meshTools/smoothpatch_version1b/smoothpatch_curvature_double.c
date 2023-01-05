#include "mex.h"
#include "math.h"
#include "stdio.h"

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

    /* Neighbour list input */
    const mxArray *Ne;
    mxArray *PneigMatlab;
    mwSize *PneigDims;
    int PneigLenght=0;
    double *Pneig;
    
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
    
    /* Swap point variable */
    double *t;
    int swap=0;
    
    /* Loop variable */
    int i,j,k;
    
    /* Neighbourh index temp */
    int k1, k2;
            
    /* Angles */
   double Angle_Left, Angle_Right;
   
   /* Weight */
   double W, Wt;
   /* Temporary vertice update storage */
   double Ux, Uy, Uz;
   

   
    /* Check for proper number of arguments. */
   if(nrhs!=9) {
     mexErrMsgTxt("9 inputs are required.");
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
   Ne=prhs[8];
   
    
   /* Get number of FacesN */
   FacesDims = mxGetDimensions(prhs[0]);   
   FacesN=FacesDims[0]*FacesDims[1];
   
   /* Get number of VertexN */
   VertexDims = mxGetDimensions(prhs[3]);   
   VertexN=VertexDims[0]*VertexDims[1];
   
   /* Intern vertices storage */
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
       for (i=0; i<VertexN; i++)
       {
             /* Get the neigbours of the vertice */
             PneigMatlab=mxGetCell(Ne, i);
             if(PneigMatlab == NULL)
             {
                 PneigLenght=-1;
             }
             else
             {
                 PneigDims=(mwSize *)mxGetDimensions(PneigMatlab);
                 PneigLenght=(PneigDims[0]*PneigDims[1]);
                 Pneig=(double *)mxGetPr(PneigMatlab);
             }
             W=1e-14; Ux=0; Uy=0; Uz=0;
             
             
             for(k=0; k<PneigLenght; k++)
             {
                 k1=k-1; if(k1<0) { k1+=PneigLenght; }
                 k2=k+1; if(k2>(PneigLenght-1)) { k2-=PneigLenght; };
                    
                 index0=i; index2=(int)Pneig[k]-1;
                 
                 /* Vertice of Left angle  */
                 index1=(int)Pneig[k1]-1;
                 
                 /* Calculate edge lengths  */
                 e0x=VerticesNX[index0]-VerticesNX[index1];  
                 e0y=VerticesNY[index0]-VerticesNY[index1];  
                 e0z=VerticesNZ[index0]-VerticesNZ[index1];
                 e1x=VerticesNX[index1]-VerticesNX[index2];  
                 e1y=VerticesNY[index1]-VerticesNY[index2];  
                 e1z=VerticesNZ[index1]-VerticesNZ[index2];
    
                 /* Normalize the edge vectors */
                 e0l = sqrt(e0x*e0x+e0y*e0y+e0z*e0z)+1e-14;
                 e0x/=e0l; e0y/=e0l; e0z/=e0l;
                 e1l = sqrt(e1x*e1x+e1y*e1y+e1z*e1z)+1e-14; 
                 e1x/=e1l; e1y/=e1l; e1z/=e1l;
    
                 /* Calculate angles of face seen from vertices */
                 Angle_Left= acos((e1x*e0x+e1y*e0y+e1z*e0z));
                         
                 /* Vertice of Right angle */
                 index1=(int)Pneig[k2]-1;

                 /* Calculate edge lengths  */
                 e0x=VerticesNX[index0]-VerticesNX[index1];  
                 e0y=VerticesNY[index0]-VerticesNY[index1];  
                 e0z=VerticesNZ[index0]-VerticesNZ[index1];
                 e1x=VerticesNX[index1]-VerticesNX[index2];  
                 e1y=VerticesNY[index1]-VerticesNY[index2];  
                 e1z=VerticesNZ[index1]-VerticesNZ[index2];
    
                 /* Normalize the edge vectors  */
                 e0l = sqrt(e0x*e0x+e0y*e0y+e0z*e0z)+1e-14;
                 e0x/=e0l; e0y/=e0l; e0z/=e0l;
                 e1l = sqrt(e1x*e1x+e1y*e1y+e1z*e1z)+1e-14; 
                 e1x/=e1l; e1y/=e1l; e1z/=e1l;
    
                 /* Calculate angles of face seen from vertices  */
                 Angle_Right= acos((e1x*e0x+e1y*e0y+e1z*e0z));
       
                 
                 Wt = Angle_Left+Angle_Right;

                 Ux+=Wt*(VerticesNX[index0]-VerticesNX[index2]);
                 Uy+=Wt*(VerticesNY[index0]-VerticesNY[index2]);
                 Uz+=Wt*(VerticesNZ[index0]-VerticesNZ[index2]);
                         
                 W += Wt;
            }
            
            VerticesN2X[i]=VerticesNX[i]-Lambda[0]*Ux/W;
            VerticesN2Y[i]=VerticesNY[i]-Lambda[0]*Uy/W;
            VerticesN2Z[i]=VerticesNZ[i]-Lambda[0]*Uz/W;             
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
   free(VerticesNX);
   free(VerticesNY);
   free(VerticesNZ);
   free(VerticesN2X);
   free(VerticesN2Y);
   free(VerticesN2Z);
}
 


