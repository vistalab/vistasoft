#include "mex.h"
#include "math.h"
#include "string.h"
#include <iostream>
#include "stdlib.h"
#define mind(a, b)        ((a) < (b) ? (a): (b))
#define maxd(a, b)        ((a) > (b) ? (a): (b))
#include "renderpatch_transformation.cpp"
#include "renderpatch_vertice.cpp"
#include "renderpatch_texture.cpp"
#include "renderpatch_renderimage.cpp"
#include "renderpatch_shading.cpp"
#include "renderpatch_scene.cpp"
#include "renderpatch_fragment.cpp"
#include "renderpatch_face.cpp"
#include "renderpatch_mesh.cpp"
using namespace std;

double mxSingleParameter(const char * fieldname, const mxArray *prhs[]) {
    /* Read structure variables */
    mxArray *OptionsFieldMX;
    int field_num;
    double *Vin;  const mwSize *Vin_dimsc;  int Vin_ndims=0;
    double parameter=-9999;
    field_num = mxGetFieldNumber(prhs[1], fieldname);
    if(field_num>=0) {
        OptionsFieldMX = mxGetFieldByNumber(prhs[1], 0, field_num);
        if(!mxIsDouble(OptionsFieldMX)){ mexErrMsgTxt("option must be a double array"); }
        Vin_ndims=mxGetNumberOfDimensions(OptionsFieldMX);
        Vin_dimsc= mxGetDimensions(OptionsFieldMX);
        if(Vin_ndims!=2) { mexErrMsgTxt("option must be an 1 x 1 array");  }
        if((Vin_dimsc[1]!=1)||(Vin_dimsc[0]!=1)) { mexErrMsgTxt("option must be an 1 x 1 array");  }
        Vin=mxGetPr(OptionsFieldMX);
        parameter=Vin[0];
    }
    return parameter;
}

void LoadObject(Mesh *H, const mxArray *prhs[])
{
    /* Read structure variables */
    mxArray *OptionsFieldMX;
    int field_num;
    
    double *Vin;  const mwSize *Vin_dimsc;  int Vin_dims[2];  int Vin_ndims=0;
    double *Fin;  const mwSize *Fin_dimsc;  int Fin_dims[2];  int Fin_ndims=0;
    double *TVin; const mwSize *TVin_dimsc; int TVin_dims[2]; int TVin_ndims=0;
    double *TIin; const mwSize *TIin_dimsc; int TIin_dims[3]; int TIin_ndims=0;
    double *Cin;  const mwSize *Cin_dimsc;  int Cin_dims[2];  int Cin_ndims=0;
    double *Nin;  const mwSize *Nin_dimsc;  int Nin_dims[2];  int Nin_ndims=0;
    double *Min;  const mwSize *Min_dimsc;  int Min_dims[2];  int Min_ndims=0;
    double *MVin; const mwSize *MVin_dimsc; int MVin_dims[2]; int MVin_ndims=0;
    
     field_num = mxGetFieldNumber(prhs[1], "vertices");
    if(field_num>=0) {
        OptionsFieldMX = mxGetFieldByNumber(prhs[1], 0, field_num);
        if(!mxIsDouble(OptionsFieldMX)){ mexErrMsgTxt("vertices must be a double array"); }
        // Check input image dimensions
        Vin_ndims=mxGetNumberOfDimensions(OptionsFieldMX);
        Vin_dimsc= mxGetDimensions(OptionsFieldMX);
        if(Vin_ndims!=2) { mexErrMsgTxt("vertices must be an m x 3 array ");  }
        if(Vin_dimsc[1]!=3) { mexErrMsgTxt("vertices must be an m x 3 array");  }
        Vin=mxGetPr(OptionsFieldMX);
        Vin_dims[0]=Vin_dimsc[0];
        Vin_dims[1]=Vin_dimsc[1];
    }
    else { mexErrMsgTxt("Patch must contain vertices");  }
    
    field_num = mxGetFieldNumber(prhs[1], "faces");
    if(field_num>=0) {
        OptionsFieldMX = mxGetFieldByNumber(prhs[1], 0, field_num);
        if(!mxIsDouble(OptionsFieldMX)){ mexErrMsgTxt("faces must be a double array"); }
        // Check input image dimensions
        Fin_ndims=mxGetNumberOfDimensions(OptionsFieldMX);
        Fin_dimsc= mxGetDimensions(OptionsFieldMX);
        if(Fin_ndims!=2) { mexErrMsgTxt("faces must be an m x 3 array ");  }
        if(Fin_dimsc[1]!=3) { mexErrMsgTxt("faces must be an m x 3 array");  }
        Fin=mxGetPr(OptionsFieldMX);
        Fin_dims[0]=Fin_dimsc[0];
        Fin_dims[1]=Fin_dimsc[1];
    }
    else { mexErrMsgTxt("Patch must contain faces");  }
    
    field_num = mxGetFieldNumber(prhs[1], "texturevertices");
    if(field_num>=0) {
        OptionsFieldMX = mxGetFieldByNumber(prhs[1], 0, field_num);
        if(!mxIsDouble(OptionsFieldMX)){ mexErrMsgTxt("texturevertices must be a double array"); }
        // Check input image dimensions
        TVin_ndims=mxGetNumberOfDimensions(OptionsFieldMX);
        TVin_dimsc= mxGetDimensions(OptionsFieldMX);
        if(TVin_ndims!=2) { mexErrMsgTxt("texturevertices must be an m x 2 array ");  }
        if(TVin_dimsc[1]!=2) { mexErrMsgTxt("texturevertices must be an m x 2 array");  }
        if(TVin_dimsc[0]!=Vin_dimsc[0]) { mexErrMsgTxt("texturevertices array length must equal vertices length");  }
        TVin=mxGetPr(OptionsFieldMX);
        TVin_dims[0]=TVin_dimsc[0];
        TVin_dims[1]=TVin_dimsc[1];
    }
    
    field_num = mxGetFieldNumber(prhs[1], "textureimage");
    if(field_num>=0) {
        OptionsFieldMX = mxGetFieldByNumber(prhs[1], 0, field_num);
        if(!mxIsDouble(OptionsFieldMX)){ mexErrMsgTxt("textureimage must be a double array"); }
        // Check input image dimensions
        TIin_ndims=mxGetNumberOfDimensions(OptionsFieldMX);
        TIin_dimsc= mxGetDimensions(OptionsFieldMX);
        if(TIin_ndims!=3) { mexErrMsgTxt("textureimage must be an m x n x 3 or m x n x 4 array ");  }
        if(TIin_dimsc[2]<3) { mexErrMsgTxt("textureimage must be an m x n x 3 or m x n x 4  array");  }
        TIin=mxGetPr(OptionsFieldMX);
        TIin_dims[0]=TIin_dimsc[0];
        TIin_dims[1]=TIin_dimsc[1];
        TIin_dims[2]=TIin_dimsc[2];
    }
    
    field_num = mxGetFieldNumber(prhs[1], "color");
    if(field_num>=0) {
        OptionsFieldMX = mxGetFieldByNumber(prhs[1], 0, field_num);
        if(!mxIsDouble(OptionsFieldMX)){ mexErrMsgTxt("color must be a double array"); }
        // Check input image dimensions
        Cin_ndims=mxGetNumberOfDimensions(OptionsFieldMX);
        Cin_dimsc= mxGetDimensions(OptionsFieldMX);
        if(Cin_ndims!=2) { mexErrMsgTxt("color must be an m x 3 or m x 4 array");  }
        if(Cin_dimsc[1]<3) { mexErrMsgTxt("color must be an m x 3 or m x 4 array");  }
        if((Cin_dimsc[0]!=Vin_dimsc[0])&&(Cin_dimsc[0]!=1)) {
            mexErrMsgTxt("color array length must equal vertices length or have length 1 x 3 or 1 x 4");  }
        Cin=mxGetPr(OptionsFieldMX);
        Cin_dims[0]=Cin_dimsc[0];
        Cin_dims[1]=Cin_dimsc[1];        
    }
    
    field_num = mxGetFieldNumber(prhs[1], "normals");
    if(field_num>=0) {
        OptionsFieldMX = mxGetFieldByNumber(prhs[1], 0, field_num);
        if(!mxIsDouble(OptionsFieldMX)){ mexErrMsgTxt("normals must be a double array"); }
        // Check input image dimensions
        Nin_ndims=mxGetNumberOfDimensions(OptionsFieldMX);
        Nin_dimsc= mxGetDimensions(OptionsFieldMX);
        if(Nin_ndims!=2) { mexErrMsgTxt("normals must be an m x 3 array");  }
        if(Nin_dimsc[1]!=3) { mexErrMsgTxt("normals must be an m x 3 array");  }
        if(Nin_dimsc[0]!=Vin_dimsc[0]) { mexErrMsgTxt("normals array length must equal vertices length");  }
        Nin=mxGetPr(OptionsFieldMX);
        Nin_dims[0]=Nin_dimsc[0];
        Nin_dims[1]=Nin_dimsc[1];
    }
    
    field_num = mxGetFieldNumber(prhs[1], "modelviewmatrix");
    if(field_num>=0) {
        OptionsFieldMX = mxGetFieldByNumber(prhs[1], 0, field_num);
        if(!mxIsDouble(OptionsFieldMX)){ mexErrMsgTxt("modelviewmatrix must be a double array"); }
        // Check input image dimensions
        MVin_ndims=mxGetNumberOfDimensions(OptionsFieldMX);
        MVin_dimsc= mxGetDimensions(OptionsFieldMX);
        if(MVin_ndims!=2) { mexErrMsgTxt("modelviewmatrix must be an 4 x 4 array");  }
        if((MVin_dimsc[1]!=4)||(MVin_dimsc[0]!=4)) { mexErrMsgTxt("vmodelviewmatrix must be an 4 x 4 array");  }
        MVin=mxGetPr(OptionsFieldMX);
        MVin_dims[0]=MVin_dimsc[0];
        MVin_dims[1]=MVin_dimsc[1];
    }
        
    field_num = mxGetFieldNumber(prhs[1], "material");
    if(field_num>=0) {
        OptionsFieldMX = mxGetFieldByNumber(prhs[1], 0, field_num);
        if(!mxIsDouble(OptionsFieldMX)){ mexErrMsgTxt("material must be a double array"); }
        Min_ndims=mxGetNumberOfDimensions(OptionsFieldMX);
        Min_dimsc= mxGetDimensions(OptionsFieldMX);
        if(Min_ndims!=2) { mexErrMsgTxt("material must be an 1 x 5 array");  }
        if((Min_dimsc[1]!=5)||(Min_dimsc[0]!=1)) { mexErrMsgTxt("material must be an 1 x 5 array");  }
        Min=mxGetPr(OptionsFieldMX);
        Min_dims[0]=Min_dimsc[0];
        Min_dims[1]=Min_dimsc[1];
    }
    
       // Set vertex and face data
    H[0].setVerticesFaces(Fin, Fin_dims, Vin, Vin_dims);

    // Set texture 
    if(TIin_ndims>0) { H[0].setTexture(TIin,TIin_dims);  }
    
    // Set normals 
    if(Nin_ndims>0)  { H[0].setNormals(Nin, Nin_dims);   } 
    
    // Set texture vertices
    if(TVin_ndims>0) { H[0].setTextureVertices(TVin, TVin_dims); } 
    
    // Set colors
    if(Cin_ndims>0)  { H[0].setColors(Cin, Cin_dims);   } 
    
    // Set model view matrix
    if(MVin_ndims>0) { H[0].setModelMatrix(MVin, MVin_dims);  }

    // Set material
    if(Min_ndims>0)  { H[0].setMaterial(Min, Min_dims);  }
}

void LoadScene(Scene *S, RenderImage *I, const mxArray *prhs[])
{
    /* Read structure variables */
    mxArray *OptionsFieldMX;
    int field_num;
    
    double *LPin; const mwSize *LPin_dimsc; int LPin_dims[2]; int LPin_ndims=0;
    double *PMin; const mwSize *PMin_dimsc; int PMin_dims[2]; int PMin_ndims=0;
    double *VPin; const mwSize *VPin_dimsc; int VPin_dims[2]; int VPin_ndims=0;
    double *DRin; const mwSize *DRin_dimsc; int DRin_dims[2]; int DRin_ndims=0;
    double *BFin; const mwSize *BFin_dimsc; int BFin_dims[2]; int BFin_ndims=0;
    double *BCin; const mwSize *BCin_dimsc; int BCin_dims[2]; int BCin_ndims=0;
    
    
    field_num = mxGetFieldNumber(prhs[1], "projectionmatrix");
    if(field_num>=0) {
        OptionsFieldMX = mxGetFieldByNumber(prhs[1], 0, field_num);
        if(!mxIsDouble(OptionsFieldMX)){ mexErrMsgTxt("projectionmatrix must be a double array"); }
        // Check input image dimensions
        PMin_ndims=mxGetNumberOfDimensions(OptionsFieldMX);
        PMin_dimsc= mxGetDimensions(OptionsFieldMX);
        if(PMin_ndims!=2) { mexErrMsgTxt("projectionmatrix be an 4 x 4 array");  }
        if((PMin_dimsc[1]!=4)||(PMin_dimsc[0]!=4)) { mexErrMsgTxt("projectionmatrix be an 4 x 4 array");  }
        PMin=mxGetPr(OptionsFieldMX);
        PMin_dims[0]=PMin_dimsc[0];
        PMin_dims[1]=PMin_dimsc[1];
    }
    field_num = mxGetFieldNumber(prhs[1], "viewport");
    if(field_num>=0) {
        OptionsFieldMX = mxGetFieldByNumber(prhs[1], 0, field_num);
        if(!mxIsDouble(OptionsFieldMX)){ mexErrMsgTxt("viewport must be a double array"); }
        // Check input image dimensions
        VPin_ndims=mxGetNumberOfDimensions(OptionsFieldMX);
        VPin_dimsc= mxGetDimensions(OptionsFieldMX);
        if(VPin_ndims!=2) { mexErrMsgTxt("viewport must be an 1 x 4 array");  }
        if((VPin_dimsc[1]!=4)||(VPin_dimsc[0]!=1)) { mexErrMsgTxt("viewport must be an 1 x 4 array");  }
        VPin=mxGetPr(OptionsFieldMX);
        VPin_dims[0]=VPin_dimsc[0];
        VPin_dims[1]=VPin_dimsc[1];
    }
    
    field_num = mxGetFieldNumber(prhs[1], "depthrange");
    if(field_num>=0) {
        OptionsFieldMX = mxGetFieldByNumber(prhs[1], 0, field_num);
        if(!mxIsDouble(OptionsFieldMX)){ mexErrMsgTxt("depthrange must be a double array"); }
        // Check input image dimensions
        DRin_ndims=mxGetNumberOfDimensions(OptionsFieldMX);
        DRin_dimsc= mxGetDimensions(OptionsFieldMX);
        if(DRin_ndims!=2) { mexErrMsgTxt("depthrange be an 1 x 2 array");  }
        if((DRin_dimsc[1]!=2)||(DRin_dimsc[0]!=1)) { mexErrMsgTxt("depthrange be an 1 x 2 array");  }
        DRin=mxGetPr(OptionsFieldMX);
        DRin_dims[0]=DRin_dimsc[0];
        DRin_dims[1]=DRin_dimsc[1];
    }
    
    field_num = mxGetFieldNumber(prhs[1], "lightposition");
    if(field_num>=0) {
        OptionsFieldMX = mxGetFieldByNumber(prhs[1], 0, field_num);
        if(!mxIsDouble(OptionsFieldMX)){ mexErrMsgTxt("lightposition/direction  must be a double array"); }
        // Check input image dimensions
        LPin_ndims=mxGetNumberOfDimensions(OptionsFieldMX);
        LPin_dimsc= mxGetDimensions(OptionsFieldMX);
        if(LPin_ndims!=2) { mexErrMsgTxt("light position/direction must be an k x 4 array");  }
        if(LPin_dimsc[1]!=4) { mexErrMsgTxt("light position/direction  must be an k x 4 array");  }
        LPin=mxGetPr(OptionsFieldMX);
        LPin_dims[0]=LPin_dimsc[0];
        LPin_dims[1]=LPin_dimsc[1];
    }
    
    double val;
    val=mxSingleParameter("enableblending", prhs);  if(val!=-9999) { if(val==1) { S[0].enableblending=true;}  else { S[0].enableblending=false; }}
    val=mxSingleParameter("enabledepthtest", prhs); if(val!=-9999) { if(val==1) { S[0].enabledepthtest=true;}  else { S[0].enabledepthtest=false; }}
    val=mxSingleParameter("enablestenciltest", prhs); if(val!=-9999) { if(val==1) { S[0].enablestenciltest=true;}  else { S[0].enablestenciltest=false; }}
    val=mxSingleParameter("enabletexture", prhs); if(val!=-9999) { if(val==1) { S[0].enabletexture=true;}  else { S[0].enabletexture=false; }}
    val=mxSingleParameter("enableshading", prhs); if(val!=-9999) { if(val==1) { S[0].enableshading=true;}  else { S[0].enableshading=false; }}
    val=mxSingleParameter("depthbufferwrite", prhs); if(val!=-9999) { if(val==1) { S[0].depthbufferwrite=true;}  else { S[0].depthbufferwrite=false; }}
    val=mxSingleParameter("colorbufferwrite", prhs); if(val!=-9999) { if(val==1) { S[0].enabletexture=true;}  else { S[0].colorbufferwrite=false; }}
    val=mxSingleParameter("culling", prhs); if(val!=-9999) { S[0].culling=(int) val; }
    val=mxSingleParameter("depthfunction", prhs); if(val!=-9999) { S[0].depthfunction=(int)val;}
    val=mxSingleParameter("stencilfunction", prhs); if(val!=-9999) { S[0].stencilfunction=(int)val;}
    val=mxSingleParameter("stencilreferencevalue", prhs); if(val!=-9999) { S[0].stencilreferencevalue=val;}
    val=mxSingleParameter("stencilfail", prhs); if(val!=-9999) { S[0].stencilfail=(int)val;}
    val=mxSingleParameter("stencilpassdepthbufferfail", prhs); if(val!=-9999) { S[0].stencilpassdepthbufferfail=(int)val;}
    val=mxSingleParameter("stencilpassdepthbufferpass", prhs); if(val!=-9999) { S[0].stencilpassdepthbufferpass=(int)val;}
    
    field_num = mxGetFieldNumber(prhs[1], "blendfunction");
    if(field_num>=0) {
        OptionsFieldMX = mxGetFieldByNumber(prhs[1], 0, field_num);
        if(!mxIsDouble(OptionsFieldMX)){ mexErrMsgTxt("blendfunction must be a double array"); }
        BFin_ndims=mxGetNumberOfDimensions(OptionsFieldMX);
        BFin_dimsc= mxGetDimensions(OptionsFieldMX);
        if(BFin_ndims!=2) { mexErrMsgTxt("blendfunction must be an 1 x 2 array");  }
        if((BFin_dimsc[1]!=2)||(BFin_dimsc[0]!=1)) { mexErrMsgTxt("blendfunction must be an 1 x 2 array");  }
        BFin=mxGetPr(OptionsFieldMX);
        BFin_dims[0]=BFin_dimsc[0];
        BFin_dims[1]=BFin_dimsc[1];
        S[0].blendfunction[0]=(int)BFin[0]; S[0].blendfunction[1]=(int)BFin[1];
    }
    
    field_num = mxGetFieldNumber(prhs[1], "blendcolor");
    if(field_num>=0) {
        OptionsFieldMX = mxGetFieldByNumber(prhs[1], 0, field_num);
        if(!mxIsDouble(OptionsFieldMX)){ mexErrMsgTxt("blendcolor must be a double array"); }
        BCin_ndims=mxGetNumberOfDimensions(OptionsFieldMX);
        BCin_dimsc= mxGetDimensions(OptionsFieldMX);
        if(BCin_ndims!=2) { mexErrMsgTxt("blendcolor must be an 1 x 4 array");  }
        if((BCin_dimsc[1]!=4)||(BCin_dimsc[0]!=1)) { mexErrMsgTxt("blendcolor must be an 1 x 4 array");  }
        BCin=mxGetPr(OptionsFieldMX);
        BCin_dims[0]=BCin_dimsc[0];
        BCin_dims[1]=BCin_dimsc[1];
        S[0].blendcolor[0]=BCin[0]; S[0].blendcolor[1]=BCin[1];
        S[0].blendcolor[1]=BCin[2]; S[0].blendcolor[3]=BCin[3];
    }
    
    S[0].I=I[0];

    // Set Scene projection Matrix
    if(PMin_ndims>0) { S[0].TT.setProjectionMatrix(PMin); }
        
    // Set View Port
    if(VPin_ndims>0) { S[0].TT.setViewport(VPin); }
    else {
        double VPin[4];
        VPin[0]=0; VPin[1]=0;
        VPin[2]=(I[0].getsize(0)+I[0].getsize(1))/2; VPin[3]=(I[0].getsize(0)+I[0].getsize(1))/2;
        S[0].TT.setViewport(VPin);
    }

    // Set depth range
    if(DRin_ndims>0) { S[0].TT.setDepthRange(DRin); }
    
    if(LPin_ndims>0) { S[0].Q.setLightPosition(LPin, LPin_dims[0]); }
}

void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] ) {
    double *Iout;
    
    // Inputs
    double *Iin;  const mwSize *Iin_dimsc;  int Iin_dims[3];  int Iin_ndims=0;
   
    RenderImage *I;
    
    /* Check number of inputs */
    if(nrhs<2) { mexErrMsgTxt("2 input variables required."); }
    
    // Assign pointers to each input.
    Iin = mxGetPr(prhs[0]);
    
    // Check input image dimensions
    Iin_ndims=mxGetNumberOfDimensions(prhs[0]);
    Iin_dimsc= mxGetDimensions(prhs[0]);
    
    // Check input types and sizes
    if(Iin_ndims!=3) { mexErrMsgTxt("Render Target Image must be m x n x 6");  }
    if(Iin_dimsc[2]!=6) { mexErrMsgTxt("Render Target Image must be m x n x 6");  }
    Iin_dims[0]=Iin_dimsc[0];
    Iin_dims[1]=Iin_dimsc[1];
    Iin_dims[2]=Iin_dimsc[2];
    if(!mxIsDouble(prhs[0])){ mexErrMsgTxt("Render Target Image must be double"); }
    if(!mxIsStruct(prhs[1])){ mexErrMsgTxt("Patch must be structure"); }
    
    // Make output array;
    plhs[0] = mxCreateNumericArray( Iin_ndims, Iin_dims, mxDOUBLE_CLASS, mxREAL);
    Iout = (double *)mxGetData(plhs[0]);
    
    // Copy input image to output image
    memcpy(Iout, Iin, Iin_dims[0]*Iin_dims[1]*Iin_dims[2]*sizeof(double));
    I=new RenderImage(Iout, Iin_dims[0], Iin_dims[1]);

    // Create the Render Scene with all options
    Scene *S = new Scene[1];
    LoadScene(S, I, prhs);
    
    // Create Mesh object
    Mesh *H=new Mesh();
    LoadObject(H, prhs);
 
    // Draw the Mesh
    H[0].drawMesh(S);
    
    delete I;
    delete S;
}

