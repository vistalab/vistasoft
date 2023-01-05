/*
* When you have a light and object described by a mesh, you want to know
* the shadow of the object.
* This function calculates a mesh named "shadowvolume" (see wikipedia) from
* a triangulated object mesh and a light.
*
* [SVvertices,SVfaces]=patchshadowvolume(OBJvertices,OBJfaces,L);
*
* Inputs,
*    OBJvertices, OBJfaces : The triangulated patch vertices and faces
*                       of the object causing a shadow
*    L: The light must be a 1x4 array with x,y,z,d, 
*		 with d=0 for parallel light, then x,y,z is the light direction
(		 and d=1 for point light, then x,y,z is the light position
*
* Outputs,
*    SVvertices, SVfaces : The triangulated shadow volume
*
* Function is written by D.Kroon University of Twente (March 2010)
*/

#include "mex.h"
#include "math.h"
#include "string.h"
#include <iostream>
#include <algorithm>
#include "stdlib.h"
#define mind(a, b)        ((a) < (b) ? (a): (b))
#define maxd(a, b)        ((a) > (b) ? (a): (b))
#define bignumber 1e6
#ifdef WIN32	
  typedef __int64 int64_t ;
#else
  typedef long long int int64_t ;
#endif

double dot(double * A, double * B){ return A[0]*B[0]+A[1]*B[1]+A[2]*B[2]; }
void normalize(double * A) {
    double l=sqrt(A[0]*A[0]+A[1]*A[1]+A[2]*A[2]);
    A[0]=A[0]/l; A[1]=A[1]/l; A[2]=A[2]/l;
}
void cross(double *a, double *b, double *n) {
    n[0]=a[1]*b[2]-a[2]*b[1]; n[1]=a[2]*b[0]-a[0]*b[2]; n[2]=a[0]*b[1]-a[1]*b[0];
}

struct edge { int64_t id; int v1; int v2; int v3; int v4; };
bool edgeidcomp(const edge & lhs, const edge & rhs) { return lhs.id < rhs.id; }

struct outsidepoint { int vertex; int id; };
bool outsidepointvertexcomp(const outsidepoint & lhs, const outsidepoint & rhs) { return lhs.vertex < rhs.vertex; }



void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] ) {
    // Inputs
    double *Vin;  const mwSize *Vin_dims;  int Vin_ndims=0;
    double *Fin;  const mwSize *Fin_dims;  int Fin_ndims=0;
    double *LPin;  const mwSize *LPin_dims;  int LPin_ndims=0;
    
    /* Check number of inputs / outputs */
    if(nrhs<3) { mexErrMsgTxt("3 input variables required."); }
    if(nlhs<2) { mexErrMsgTxt("2 output variables required."); }
    
	if(!mxIsDouble(prhs[0])){ mexErrMsgTxt("inputs must be double arrays"); }
	if(!mxIsDouble(prhs[1])){ mexErrMsgTxt("inputs must be double arrays"); }
	if(!mxIsDouble(prhs[2])){ mexErrMsgTxt("inputs must be double arrays"); }
	  
    // Assign pointers to each input.
    Vin = mxGetPr(prhs[0]);
    Vin_ndims=mxGetNumberOfDimensions(prhs[0]);
    Vin_dims= mxGetDimensions(prhs[0]);
    
    // Assign pointers to each input.
    Fin = mxGetPr(prhs[1]);
    Fin_ndims=mxGetNumberOfDimensions(prhs[1]);
    Fin_dims= mxGetDimensions(prhs[1]);
    
    // Assign pointers to each input.
    LPin = mxGetPr(prhs[2]);
    LPin_ndims=mxGetNumberOfDimensions(prhs[2]);
    LPin_dims= mxGetDimensions(prhs[2]);
	if(LPin_dims[0]*LPin_dims[1]!=4)
	{
		mexErrMsgTxt("Light must be a 1x4 array with x,y,z,d, with d=0 for parallel light, and d=1 for point light");
	}
	
    int *Ffronttemp = new int[Fin_dims[0]*Fin_dims[1]];
    bool *Vactive = new bool[Vin_dims[0]];
    for(int i=0; i<Vin_dims[0]; i++) { Vactive[i]=false; }
    
    // Number of (light) front facing faces found
    int nfaces=0;
    
    // Loop through all faces, to see which faces are frontfacing the light
    for(int i=0; i<Fin_dims[0]; i++) {
        int F1a=(int)Fin[i+0]-1;
        int F2a=(int)Fin[i+1*Fin_dims[0]]-1;
        int F3a=(int)Fin[i+2*Fin_dims[0]]-1;
        int F1b=F1a+Vin_dims[0];
        int F2b=F2a+Vin_dims[0];
        int F3b=F3a+Vin_dims[0];
        int F1c=F1b+Vin_dims[0];
        int F2c=F2b+Vin_dims[0];
        int F3c=F3b+Vin_dims[0];
        
        double a[3], b[3], c[3];
        a[0]=Vin[F1a]; a[1]=Vin[F1b]; a[2]=Vin[F1c];
        b[0]=Vin[F2a]; b[1]=Vin[F2b]; b[2]=Vin[F2c];
        c[0]=Vin[F3a]; c[1]=Vin[F3b]; c[2]=Vin[F3c];
        
        double v1[3], v2[3];
        v1[0]=a[0]-b[0]; v1[1]=a[1]-b[1]; v1[2]=a[2]-b[2];
        v2[0]=a[0]-c[0]; v2[1]=a[1]-c[1]; v2[2]=a[2]-c[2];
        
        // Construct normal of the face
        double n[3];
        cross(v1, v2, n);
        
        // Center of face
        double fc[3];
        fc[0]=(a[0]+b[0]+c[0])/3;
        fc[1]=(a[1]+b[1]+c[1])/3;
        fc[2]=(a[2]+b[2]+c[2])/3;
        
        // Calculate light vector
        double l[3];
		if(LPin[3]==0)
		{
			l[0]=LPin[0]*bignumber;
			l[1]=LPin[1]*bignumber;
			l[2]=LPin[2]*bignumber;
		}
		else
		{
			l[0]=LPin[0]-fc[0];
			l[1]=LPin[1]-fc[1];
			l[2]=LPin[2]-fc[2];
        }
        bool frontfacing;
        frontfacing=dot(l, n)<=0;
        if(frontfacing) {
            // If facing towards the light add to shadowvolume
            int index1=nfaces+0;
            int index2=nfaces+1*Fin_dims[0];
            int index3=nfaces+2*Fin_dims[0];
            Ffronttemp[index1]=F1a;
            Ffronttemp[index2]=F2a;
            Ffronttemp[index3]=F3a;
            nfaces++;
            
            // Mark vertices as used
            Vactive[F1a]=true; Vactive[F2a]=true; Vactive[F3a]=true;
        }
    }
    
    int *Vnewid = new int[Vin_dims[0]];
    
    // Make vertice array which can contain the current needed vertices (idn)
    // but also the new vertices far away of the shadow volume
    int idn=0;
    for(int i=0; i<Vin_dims[0]; i++) { if(Vactive[i])  { idn++; } }
    int Vfront_dims[2]; Vfront_dims[0]=idn*2; Vfront_dims[1]=3;
    double *Vfront = new double[Vfront_dims[0]*Vfront_dims[1]];
    
    // Make face array, containing all light facing faces.
    int Ffront_dims[2]; Ffront_dims[0]=nfaces; Ffront_dims[1]=3;
    int *Ffront = new int[Ffront_dims[0]*Ffront_dims[1]];
    
    // Copy the needed vertices to the new vertice array
    int id=0;
    for(int i=0; i<Vin_dims[0]; i++) {
        if(Vactive[i]) {
            Vnewid[i]=id;
            // Set output vertex
            Vfront[id]=Vin[i];
            Vfront[id+Vfront_dims[0]]=Vin[i+Vin_dims[0]];
            Vfront[id+2*Vfront_dims[0]]=Vin[i+2*+Vin_dims[0]];
            id++;
        }
    }
    
    // Copy the light facing faces to the new array
    for(int i=0; i<Ffront_dims[0]; i++) {
        int F1a=(int)Ffronttemp[i+0];
        int F2a=(int)Ffronttemp[i+1*Fin_dims[0]];
        int F3a=(int)Ffronttemp[i+2*Fin_dims[0]];
        int F1b=Vnewid[F1a];
        int F2b=Vnewid[F2a];
        int F3b=Vnewid[F3a];
        Ffront[i+0]=F1b;
        Ffront[i+1*Ffront_dims[0]]=F2b;
        Ffront[i+2*Ffront_dims[0]]=F3b;
    }
        
    // Create list with edges, and give them an index
    // so id of 1-5 equals that of 5-1
    edge *edges = new edge[Ffront_dims[0]*3];
    int j=0;
    int64_t idd;
    for(int i=0; i<Ffront_dims[0]; i++) {
        int F1a=Ffront[i+0];
        int F2a=Ffront[i+1*Ffront_dims[0]];
        int F3a=Ffront[i+2*Ffront_dims[0]];
        if(F1a>F2a) { idd = (int64_t) F2a*Vfront_dims[0] + F1a; } else { idd = F1a*Vfront_dims[0] + F2a; }
        edges[j].id=idd; edges[j].v1=F1a; edges[j].v2=F2a; j++;
        if(F2a>F3a) { idd = (int64_t) F3a*Vfront_dims[0] + F2a; } else { idd = F2a*Vfront_dims[0] + F3a; }
        edges[j].id=idd; edges[j].v1=F2a; edges[j].v2=F3a; j++;
        if(F3a>F1a) { idd = (int64_t) F1a*Vfront_dims[0] + F3a; } else { idd = F3a*Vfront_dims[0] + F1a; }
        edges[j].id=idd; edges[j].v1=F3a; edges[j].v2=F1a; j++;
    }
    
    // Sort the edges by id so 1-5 comes right behind 5-1
    std::sort(edges, edges + j, edgeidcomp);
    int64_t nid, pid=-1; int nedgec=0;
    
    // When the edge is only once in the list it is at the the contour (outside) of
    // the mesh. Thus squeeze out all double/triple ids
    for(int i=0; i<j; i++) {
        if(i<(j-1)) { nid=edges[i+1].id; } else { nid=-1; }
        if((pid!=edges[i].id)&&(nid!=edges[i].id)) {
            edges[nedgec].id=edges[i].id; 
            edges[nedgec].v1=edges[i].v1; 
            edges[nedgec].v2=edges[i].v2;
            nedgec++;
        }
        pid=edges[i].id;
    }

    // Make an array containing all ids of vertex points part of an edge
    int ntoutside=nedgec*2;
    outsidepoint *outsidepoints = new outsidepoint[ntoutside];
    for(int i=0; i<nedgec; i++) {
        outsidepoints[i*2  ].vertex=edges[i].v1;
        outsidepoints[i*2+1].vertex=edges[i].v2;
        outsidepoints[i*2  ].id=i;
        outsidepoints[i*2+1].id=i;
    }

    // Sort the outside points
    std::sort(outsidepoints, outsidepoints + ntoutside, outsidepointvertexcomp);

    // Make new vertices far way, from the vertices of the outside contour
    int pf=-1, npoints=0;
    for(int i=0; i<ntoutside; i++) {
        if(pf!=outsidepoints[i].vertex)
        { 
            id =outsidepoints[i].vertex;
          
            double p[3];
            p[0] = Vfront[id];
            p[1] = Vfront[id+Vfront_dims[0]];
            p[2] = Vfront[id+2*Vfront_dims[0]];
            
            double v[3];
			if(LPin[3]==0)
			{
				v[0]=-LPin[0]; 
				v[1]=-LPin[1]; 
				v[2]=-LPin[2];
            }
			else
			{
				v[0]=p[0]-LPin[0]; 
				v[1]=p[1]-LPin[1]; 
				v[2]=p[2]-LPin[2];
			}
			
            // Normalize not really needed, but will cause the endpoints
            // of the shadowvolume to be in the same order of distance
            // from the orignal points
            normalize(v);
        
            // The end points (far away) of the shadow volume
            Vfront[idn] = p[0]+v[0]*bignumber;
            Vfront[idn+Vfront_dims[0]] =  p[1]+v[1]*bignumber;
            Vfront[idn+2*Vfront_dims[0]] = p[2]+v[2]*bignumber;
            idn++; 
        }

        // Set one of the empty vertex ids of an edge to the current
        // vertice id.
        int v1 = edges[outsidepoints[i].id].v1;
        int v2 = edges[outsidepoints[i].id].v2;
        if(v1==outsidepoints[i].vertex) { edges[outsidepoints[i].id].v3=idn-1; }
        else { edges[outsidepoints[i].id].v4=idn-1; }

        pf=outsidepoints[i].vertex;
    }
 
    // Initialize output vertice array
    int Vout_ndims=2; int Vout_dims[2]; Vout_dims[0]=idn; Vout_dims[1]=3;
    plhs[0] = mxCreateNumericArray(Vout_ndims, Vout_dims, mxDOUBLE_CLASS, mxREAL);
    double * Vout = mxGetPr(plhs[0]);
    
    // Initialize output face array
    int Fout_ndims=2; int Fout_dims[2]; Fout_dims[0]=Ffront_dims[0]+nedgec*2; Fout_dims[1]=3;
    plhs[1] = mxCreateNumericArray(Fout_ndims, Fout_dims, mxDOUBLE_CLASS, mxREAL);
    double *Fout = mxGetPr(plhs[1]);

    
    // Copy Vertices array to output array
    for(int i=0; i<Vout_dims[0]; i++)
    {
        Vout[i] = Vfront[i];
        Vout[i+Vout_dims[0]] =  Vfront[i+Vfront_dims[0]];
        Vout[i+2*Vout_dims[0]] = Vfront[i+2*Vfront_dims[0]];
    }
    
           
    // Add front facing faces to shadow volume
    for(int i=0; i<Ffront_dims[0]; i++) 
    {
        Fout[i]=Ffront[i]+1;
        Fout[i+1*Fout_dims[0]]=Ffront[i+1*Ffront_dims[0]]+1;
        Fout[i+2*Fout_dims[0]]=Ffront[i+2*Ffront_dims[0]]+1;
    }
    
    // Make the new shadowvolume faces
    j=Ffront_dims[0];
    for(int i=0; i<nedgec; i++) 
    {
        Fout[j]=edges[i].v3+1;
        Fout[j+1*Fout_dims[0]]=edges[i].v4+1;
        Fout[j+2*Fout_dims[0]]=edges[i].v2+1;
        j++;
            
        Fout[j]=edges[i].v2+1;
        Fout[j+1*Fout_dims[0]]=edges[i].v1+1;
        Fout[j+2*Fout_dims[0]]=edges[i].v3+1;
        j++;
    }
    
    delete Ffronttemp;
    delete Vactive;
    delete Vnewid;
    delete Vfront;
    delete Ffront;
    delete edges;
    delete outsidepoints;
}


