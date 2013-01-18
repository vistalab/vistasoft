#include "grayVolume.h"

/* Classification. */
/* 
 * Internal classification tags. 
 * The classification tag is 8-bits wide.  The most significant
 * bit is use to determine selection.  The next upper 3 bits
 * are used to specify the class (white=1, gray=2, CSF=3, tmp=4).
 * The lower 4 bits are used to specify other information.
 * For example, the lower 4 bits for gray matter tags
 * could be used to describe up to 16 layers of gray.  The
 * lower 4 bits for white matter tags could be used to specify
 * tags for up to 16 white matter connected components.
 */
#define SELECT_MASK	0x80
#define CLASS_MASK	0x70

#define WHITE_CLASS	(1<<4)
#define GRAY_CLASS	(2<<4)
#define CSF_CLASS	(3<<4)
#define TMP_CLASS1	(4<<4)

#define	ISOLEVEL_VALUE	0.5f
#define INNER_VALUE		0
#define OUTER_VALUE		1

CColor	CGrayVolume::cDefaultColor(192, 192, 192, 255);

CGrayVolume::CGrayVolume()
{
	bLoaded = false;
	pClassData = NULL;
}

CGrayVolume::~CGrayVolume()
{
	Free();
}

bool CGrayVolume::CreateFromArray(unsigned char* pArray, int* pDims, double* scale)
{
	Free();
	vtkUnsignedCharArray* pClassValues = NULL;
	double fTemp;

	pClassValues = vtkUnsignedCharArray::New();

    int	iSizes[3] = {pDims[0]+2, pDims[1]+2, pDims[2]+2};
    int	nTotalValues = iSizes[0] * iSizes[1] * iSizes[2];

    pClassValues->SetNumberOfValues(nTotalValues);
    memset(pClassValues->GetPointer(0), OUTER_VALUE, nTotalValues);

    pClassData = vtkStructuredPoints::New();
    pClassData->SetDimensions(iSizes[0], iSizes[1], iSizes[2]);

    pClassData->SetOrigin(-scale[0], -scale[1], -scale[2]);
	pClassData->SetSpacing(scale[0], scale[1], scale[2]);
		   
    int	iSrcIndex;
    int iDstIndex;

    for (int iSrcZ = 0; iSrcZ < pDims[2]; iSrcZ++)
    {
        for (int iSrcY = 0; iSrcY < pDims[1]; iSrcY++)
        {
            iSrcIndex = iSrcZ * pDims[1] * pDims[0] + iSrcY * pDims[0];
            iDstIndex = (iSrcZ+1) * iSizes[1] * iSizes[0] + (iSrcY+1) * iSizes[0] + 1;

            for (int iSrcX = 0; iSrcX < pDims[0]; iSrcX++)
            {
                fTemp = pArray[iSrcIndex];
                pClassValues->SetValue(iDstIndex, (fTemp > 0) ? INNER_VALUE : OUTER_VALUE);

                iSrcIndex++;
                iDstIndex++;
            }
        }
    }

    pClassData->GetPointData()->SetScalars(pClassValues);

    pClassValues->Delete();

    bLoaded = true;

    return true;
}

void CGrayVolume::Free()
{
	if (pClassData)
	{
		pClassData->Delete();
		pClassData = NULL;
	}
}

bool CGrayVolume::VtkToArrays(vtkPolyData *pPD, Vertex* &pVertices, Triangle* &pTriangles)
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
            pVertices[iV].cColor = cDefaultColor;
    }

    // transfer triangles
    vtkIdType	*pPolys = pPD->GetPolys()->GetPointer();
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

vtkPolyData* CGrayVolume::BuildMesh()
{
	if (!bLoaded)
		return NULL;

	ASSERT(pClassData);

	vtkMarchingCubes		*pMC	= NULL;
	vtkPolyData				*pOut	= NULL;

    pMC = vtkMarchingCubes::New();
    pMC->SetInput(pClassData);
    pMC->SetValue(0, ISOLEVEL_VALUE);

    pMC->ComputeGradientsOff();
    pMC->ComputeNormalsOff();
    pMC->ComputeScalarsOff();

    ASSERT(pMC->GetNumberOfContours() == 1);

    pMC->Update();

    pOut = vtkPolyData::New();
    pOut->ShallowCopy(pMC->GetOutput());

    ReverseTriangles(pOut);

    pMC->Delete();

    return pOut;

}


void CGrayVolume::ReverseTriangles(vtkPolyData *pPD)
{
	int nPolys = pPD->GetNumberOfPolys();
	
    vtkIdType	*pPolys = pPD->GetPolys()->GetPointer();
	for (int iPoly = 0; iPoly < nPolys; iPoly++)
	{
		int nVertices = *pPolys;
		if (nVertices == 3)
		{
			int iLast = pPolys[3];
			pPolys[3] = pPolys[1];
			pPolys[1] = iLast;
		}
		pPolys += nVertices+1;
	}
}

