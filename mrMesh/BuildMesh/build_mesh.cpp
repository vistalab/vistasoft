/*************************************************
*
* For more help type from a Matlab environment:
*   help buildMesh
*
*   WINDOWS INSTRUCTIONS :
*
* (THESE INSTRUCTIONS ARE OUTDATED- NEED AN UPDATE)
* To compile it, type from a Matlab environment:
*   mex build_mesh.cpp -IVTK_Include
*
* The libraries needed for this program to compile in windows
* are in the directory VTK_Libs
*
* The header files neede for this program to compile in windows
* are in the directory VTK_Include
*
* All the libraries are already
* linked to this program with the command "pragma comment"
*
*   LINUX INSTRUCTIONS :
*
* Install the binary distribution of VTK for your platform. 
* E.g., on redhat linux, try 'yum install vtk'. 
* On Ubuntu/Debian, try 'apt-get install vtk'.
*
* Then, from matlab, run something like (be sure to set the 
* correct path to your VTK includes and libs):
* 
*    mex build_mesh.cpp -I/usr/include/vtk /usr/lib64/libvtkCommon.so /usr/lib64/libvtkFiltering.so /usr/lib64/libvtkGraphics.so
*
*
***************************************************/

#include "mex.h"
#include "matrix.h"

//#pragma comment(linker, "/NODEFAULTLIB:msvcrt.lib")

#pragma comment(lib, "Gdi32.lib")
#pragma comment(lib, "user32.lib")

#pragma comment(lib,"VTK_Libs/vtkCommon.lib")
#pragma comment(lib,"VTK_Libs/vtkFiltering.lib")
#pragma comment(lib,"VTK_Libs/vtkGraphics.lib")


#include "vtkMarchingCubes.h"
#include "vtkStructuredPoints.h"
#include "vtkUnsignedCharArray.h"
#include "vtkPointData.h"
#include "vtkPolyData.h"
#include "vtkCellArray.h"
#include "vtkDataSetAttributes.h"
#include "vtkPolyDataNormals.h"

#define ASSERT(a) {if(!(a)) {int q=1,b=0,c=q/b;}}
#include "helpers.cpp"
#include "doublearray.cpp"
#include "color.h"
#include "vector.h"

#include "vtkfilter.cpp"
#include "grayVolume.cpp"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  
    // Parsing arguments
    int *dim;
    
    if (nrhs < 1) mexErrMsgTxt("This function should take at least one argument");
    
    if (!mxIsNumeric(prhs[0]) || mxIsComplex(prhs[0]))
		mexErrMsgTxt("Wrong sort of data (1).");
	if (mxGetNumberOfDimensions(prhs[0]) != 3) 
        mexErrMsgTxt("Wrong number of dims (1).");
    
    dim  = (int *)mxGetDimensions(prhs[0]);
    unsigned char* vol = (unsigned char *)mxGetPr(prhs[0]);
    
	CGrayVolume	gray;
	vtkPolyData *pVTKMesh;
    double *scale = new double[3];
    
    if (nrhs > 1) {
        scale = (double *)mxGetPr(prhs[1]);
    }
    else {            
        scale[0] = 1;
        scale[1] = 1;
        scale[2] = 1;
    }
    
    if (!gray.CreateFromArray(vol,dim,scale))
	{
		mexErrMsgTxt("Out of Memory (1)");
	}

	pVTKMesh = gray.BuildMesh();
    if (!pVTKMesh)
    {
        mexErrMsgTxt("Out of Memory (2)");
    }

    CVTKFilter* filter = new CVTKFilter();
    
    if (!filter->BuildNormals(pVTKMesh))
        ASSERT(0);
    
    int nVertices	= pVTKMesh->GetNumberOfPoints();
    int nTriangles	= pVTKMesh->GetNumberOfPolys();
    Vertex*     pVertices;
    Triangle*   pTriangles;
    
    gray.VtkToArrays(pVTKMesh, pVertices, pTriangles);
    
    //plhs[0] = mxCreateDoubleMatrix(3,nVertices,mxREAL);
    //plhs[1] = mxCreateDoubleMatrix(3,nVertices,mxREAL);
    //plhs[2] = mxCreateDoubleMatrix(3,nTriangles,mxREAL);
    //plhs[3] = mxCreateDoubleMatrix(4,nVertices,mxREAL);
    
    mxArray* mxVertices = mxCreateDoubleMatrix(3,nVertices,mxREAL);
    mxArray* mxNormals  = mxCreateDoubleMatrix(3,nVertices,mxREAL); 
    mxArray* mxColors   = mxCreateDoubleMatrix(4,nVertices,mxREAL); 
    
    double *outVertices;
    //outVertices = mxGetPr(plhs[0]);
    outVertices = mxGetPr(mxVertices);
    
    double *outNormals;
    //outNormals = mxGetPr(plhs[1]);
    outNormals = mxGetPr(mxNormals);
    
    double *outColors;
    //outColors = mxGetPr(plhs[3]);
    outColors = mxGetPr(mxColors);
    
    int i;
    
    for (i = 0; i <nVertices; i++) {
        
        outVertices[3*i] = pVertices[i].vCoord.x;
        outVertices[3*i + 1] = pVertices[i].vCoord.y;
        outVertices[3*i + 2] = pVertices[i].vCoord.z;
        
        outNormals[3*i] = pVertices[i].vNormal.x;
        outNormals[3*i + 1] = pVertices[i].vNormal.y;
        outNormals[3*i + 2] = pVertices[i].vNormal.z;
        
        outColors[4*i] = pVertices[i].cColor.m_ucColor[0];
        outColors[4*i + 1] = pVertices[i].cColor.m_ucColor[1];
        outColors[4*i + 2] = pVertices[i].cColor.m_ucColor[2];
        outColors[4*i + 3] = pVertices[i].cColor.m_ucColor[3];

    }
    
    mxArray* mxTriangles = mxCreateDoubleMatrix(3,nTriangles,mxREAL); 
    
    double *outTriangles;
    outTriangles = mxGetPr(mxTriangles);
    //outTriangles = mxGetPr(plhs[2]);
    
    for (i = 0; i <nTriangles; i++) {
        outTriangles[3*i] = pTriangles[i].v[0];
        outTriangles[3*i + 1] = pTriangles[i].v[1];
        outTriangles[3*i + 2] = pTriangles[i].v[2];
    }
        
    const char *fields[] = {"triangles","normals",
                                    "vertices","colors"};
    
    plhs[0] = mxCreateStructMatrix(1, 1, 4, fields);
    mxSetField(plhs[0], 0, "triangles", mxTriangles);
    mxSetField(plhs[0], 0, "normals", mxNormals);
    mxSetField(plhs[0], 0, "vertices", mxVertices);
    mxSetField(plhs[0], 0, "colors", mxColors);
    
    if (pVTKMesh)
		pVTKMesh->Delete();
    
}
 
