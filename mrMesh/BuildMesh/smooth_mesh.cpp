/*************************************************
*
* For more help type from a Matlab environment:
*   help smoothMesh
*
*   WINDOWS INSTRUCTIONS :
*
* To compile it, type from a Matlab environment:
*   mex smooth_mesh.cpp -IVTK_Include
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
*    mex smooth_mesh.cpp -I/usr/include/vtk /usr/lib64/libvtkCommon.so /usr/lib64/libvtkFiltering.so /usr/lib64/libvtkGraphics.so
**
***************************************************/

#include "mex.h"
#include "matrix.h"

#pragma comment(linker, "/NODEFAULTLIB:msvcrt.lib")

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
#include "vtkDoubleArray.h"
#include "vtkDataSetAttributes.h"
#include "vtkPolyDataNormals.h"

#define ASSERT(a) {if(!(a)) {int q=1,b=0,c=q/b;}}
#include "helpers.cpp"
#include "doublearray.cpp"
#include "color.h"
#include "vector.h"

#include "vtkfilter.cpp"
#include "grayVolume.cpp"

Vertex* CreateVerticesFromMxArray(mxArray* mxVertices, mxArray* mxColors, mxArray* mxNormals)
{

	if (mxGetM(mxVertices) != 3)
		mexErrMsgTxt("The field vertices must have 3 rows");

	int nVertices = mxGetN(mxVertices);
	Vertex* pVertices = new Vertex[nVertices];

	double* pV = mxGetPr(mxVertices);

	for (int iV = 0; iV<nVertices; iV++) {
		pVertices[iV].vCoord.x = pV[0];
		pVertices[iV].vCoord.y = pV[1];
		pVertices[iV].vCoord.z = pV[2];
		pV += 3;
	}

	if (mxColors) {
		
		if ((mxGetM(mxColors) != 4) || (mxGetN(mxColors) != nVertices))
			mexErrMsgTxt("The number of columns of the fields vertices and colors must be the same");

		double* pC = mxGetPr(mxColors);
		for (int iV = 0; iV < nVertices; iV++)
		{
			for (int iC = 0; iC < 4; iC++)
				pVertices[iV].cColor.m_ucColor[iC] = (unsigned char)pC[iC];
			pC += 4;
		}

	} 
	else {
        for (int iV = 0; iV < nVertices; iV++)
        {
            pVertices[iV].cColor = CGrayVolume::cDefaultColor;
        }

	}

	if (mxNormals) {

		if ((mxGetM(mxNormals) != 3) || (mxGetN(mxNormals) != nVertices))
			mexErrMsgTxt("The dimensions of the fields vertices and normals must be the same");

		double *pN = mxGetPr(mxNormals);
		for (int iV = 0; iV < nVertices; iV++)
		{
			pVertices[iV].vNormal.x = pN[0];
			pVertices[iV].vNormal.y = pN[1];
			pVertices[iV].vNormal.z = pN[2];
			pN += 3;
		}

	}
	else {
		for (int iV = 0; iV < nVertices; iV++)
		{
			pVertices[iV].vNormal.x = 0;
			pVertices[iV].vNormal.y = 0;
			pVertices[iV].vNormal.z = 0;
		}
	}

	return pVertices;

}

Triangle* CreateTrianglesFromMxArray(mxArray* mxTriangles)
{

	if (mxGetM(mxTriangles) != 3)
		mexErrMsgTxt("The field triangles must have 3 rows");

	int nTriangles = mxGetN(mxTriangles);
	Triangle* pTriangles = new Triangle[nTriangles];

	double* pT = mxGetPr(mxTriangles);


	for (int iT = 0; iT<nTriangles; iT++) {
		pTriangles[iT].v[0] = (int) pT[0];
		pTriangles[iT].v[1] = (int) pT[1];
		pTriangles[iT].v[2] = (int) pT[2];
		pT += 3;
	}

	return pTriangles;

}

vtkPolyData* BuildVtkPolyDataTriangles(int nVertices, int nTriangles, Vertex *pVertices, Triangle *pTriangles)
{
    
  
	vtkPolyData		*pPD		= NULL;
	vtkPoints		*pPoints	= NULL;
	vtkCellArray	*pPolys		= NULL;
	vtkDoubleArray	*pNormals	= NULL;
	vtkUnsignedCharArray	*pColors = NULL;

	pPD			= vtkPolyData::New();
	pPoints		= vtkPoints::New();
	pPolys		= vtkCellArray::New();
	pNormals	= vtkDoubleArray::New();
	pColors		= vtkUnsignedCharArray::New();

	pPoints->SetDataType(VTK_DOUBLE);
	pPoints->SetNumberOfPoints(nVertices);
	
	pNormals->SetNumberOfComponents(3);
	pNormals->SetNumberOfTuples(nVertices);
	pNormals->Allocate(3*nVertices);

	pColors->SetNumberOfComponents(3);
	pColors->SetNumberOfTuples(nVertices);
	pColors->Allocate(3*nVertices);

	pPolys->EstimateSize(nTriangles, 3);
    
    
    
	for (int iV = 0; iV < nVertices; iV++)
	{
		pPoints->SetPoint(iV, pVertices[iV].vCoord);
		pNormals->SetTuple(iV, pVertices[iV].vNormal);

		for (int iC=0; iC<3; iC++)
			pColors->InsertComponent(iV, iC, pVertices[iV].cColor[iC]);
	}

//     Debug output for diagnosing 64bit/32bit idType errors
//     char cStr[256] = "";
//    sprintf( cStr, "vtkIdType %d int %d", sizeof( vtkIdType), sizeof ( int));
//     mexWarnMsgTxt(cStr);
    
    for (int iT = 0; iT < nTriangles; iT++)
	{
        // This code fixes a unsafe cast that assumed vkIdType was a 32bit int
		// VV & JMA
        vtkIdType vtkTriplet[3];
        vtkTriplet[0] = pTriangles[iT].v[0];
        vtkTriplet[1] = pTriangles[iT].v[1];
        vtkTriplet[2] = pTriangles[iT].v[2];
        pPolys->InsertNextCell((vtkIdType) 3, vtkTriplet);
                
	}
	
       
	
    pPD->SetPoints(pPoints);
    pPD->GetPointData()->SetNormals(pNormals);
    pPD->GetPointData()->SetScalars(pColors);
    pPD->SetPolys(pPolys);

	return pPD;
}

bool VtkToArrays(vtkPolyData *pPD, Vertex* &pVertices, Triangle* &pTriangles)
{
    int iV;

    int nVertices	= pPD->GetNumberOfPoints();
    int nTriangles	= pPD->GetNumberOfPolys();

    if ((nVertices < 3) || (nTriangles < 1))
    {
        nVertices = 0;
        nTriangles = 0;
        mexErrMsgTxt("No triangle");
    }

    pVertices	= new Vertex[nVertices];
    pTriangles	= new Triangle[nTriangles];

    vtkDataArray	*pNormals	= pPD->GetPointData()->GetNormals();
    vtkDataArray	*pColors	= pPD->GetPointData()->GetScalars();

    if (!pNormals)
        mexErrMsgTxt("No normals");
    
    if (pColors && (pColors->GetNumberOfComponents() != 3))
        pColors = NULL;

    // transfer vertices
    for (iV = 0; iV < nVertices; iV++)
    {
        pPD->GetPoint(iV, pVertices[iV].vCoord);
        if (pNormals)
            pNormals->GetTuple(iV, pVertices[iV].vNormal);
        if (pColors)
        {
            pVertices[iV].cColor.m_ucColor[0] = (unsigned char)pColors->GetComponent(iV, 0);
            pVertices[iV].cColor.m_ucColor[1] = (unsigned char)pColors->GetComponent(iV, 1);
            pVertices[iV].cColor.m_ucColor[2] = (unsigned char)pColors->GetComponent(iV, 2);
        }
        else
			pVertices[iV].cColor = CGrayVolume::cDefaultColor;
    }

    // transfer triangles
    //int	*pPolys = pPD->GetPolys()->GetPointer();
    vtkIdType *pPolys = pPD->GetPolys()->GetPointer();
    int	iTriangleIndex = 0;
    for (int iT = 0; iT < nTriangles; iT++)
    {
        int nVerticesCount = *pPolys;
        if (nVerticesCount != 3)
        {
            nTriangles --;	//discard non-triangles
            // warning: memory allocated for such polys will remain allocated
        }
        else
        {
            pTriangles[iTriangleIndex].v[0] = pPolys[1];
            pTriangles[iTriangleIndex].v[1] = pPolys[2];
            pTriangles[iTriangleIndex].v[2] = pPolys[3];
            iTriangleIndex ++;
        }
        pPolys += nVerticesCount + 1;
    }

    return true;
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  
    // Parsing arguments
    if (nrhs < 1) 
		mexErrMsgTxt("This function should take at least one argument");

    if (!mxIsStruct(prhs[0])) 
		mexErrMsgTxt("The first argument should be a structure");

	mxArray* mxVertices = mxGetField(prhs[0], 0, "vertices");
	if (!mxVertices)
		mexErrMsgTxt("The first argument should have a field named vertices");

	mxArray* mxTriangles = mxGetField(prhs[0], 0, "triangles");
	if (!mxTriangles)
		mexErrMsgTxt("The first argument should have a field named triangles");

	mxArray* mxColors = mxGetField(prhs[0], 0, "colors");
	mxArray* mxNormals = mxGetField(prhs[0], 0, "normals");
	
	Vertex* pVertices = CreateVerticesFromMxArray(mxVertices, mxColors, mxNormals); 
	int nVertices = mxGetN(mxVertices);

	Triangle* pTriangles = CreateTrianglesFromMxArray(mxTriangles);
	int nTriangles = mxGetN(mxTriangles);
	
    
    
	vtkPolyData *pVTKMesh = BuildVtkPolyDataTriangles(nVertices, nTriangles, pVertices, pTriangles);

	CVTKFilter* filter = new CVTKFilter();
	filter->UpdateParameters((mxArray*) prhs[0]);    
	

    if (!filter->Smooth(pVTKMesh))
		mexErrMsgTxt("Error when smoothing the mesh");

	if (!filter->BuildNormals(pVTKMesh))
		mexErrMsgTxt("Error when building the normals");

 
    if (!VtkToArrays(pVTKMesh, pVertices, pTriangles))
		mexErrMsgTxt("Error when returning the output");
            
	mxArray* mxNewVertices = mxCreateDoubleMatrix(3,nVertices,mxREAL);
    mxArray* mxNewNormals  = mxCreateDoubleMatrix(3,nVertices,mxREAL); 
    mxArray* mxNewColors   = mxCreateDoubleMatrix(4,nVertices,mxREAL); 
    
    double *outVertices;
    //outVertices = mxGetPr(plhs[0]);
    outVertices = mxGetPr(mxNewVertices);
    
    double *outNormals;
    //outNormals = mxGetPr(plhs[1]);
    outNormals = mxGetPr(mxNewNormals);
    
    double *outColors;
    //outColors = mxGetPr(plhs[3]);
    outColors = mxGetPr(mxNewColors);
    
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
    
    mxArray* mxNewTriangles = mxCreateDoubleMatrix(3,nTriangles,mxREAL); 
    
    double *outTriangles;
    outTriangles = mxGetPr(mxNewTriangles);
    //outTriangles = mxGetPr(plhs[2]);
    
    for (i = 0; i <nTriangles; i++) {
        outTriangles[3*i] = pTriangles[i].v[0];
        outTriangles[3*i + 1] = pTriangles[i].v[1];
        outTriangles[3*i + 2] = pTriangles[i].v[2];
    }
        
    const char *fields[] = {"triangles","normals",
                                    "vertices","colors"};
    
    plhs[0] = mxCreateStructMatrix(1, 1, 4, fields);
    mxSetField(plhs[0], 0, "triangles", mxNewTriangles);
    mxSetField(plhs[0], 0, "normals", mxNewNormals);
    mxSetField(plhs[0], 0, "vertices", mxNewVertices);
    mxSetField(plhs[0], 0, "colors", mxNewColors);

}
