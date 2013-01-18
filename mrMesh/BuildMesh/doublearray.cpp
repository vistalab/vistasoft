#include "doublearray.h"

CDoubleArray::CDoubleArray()
{
	fValues = NULL;
	nTotalItems = 0;
	nDimensions = 0;
}

CDoubleArray::~CDoubleArray()
{
	Free();
}

bool CDoubleArray::Create(int nDimensions, int iSizeX, int iSizeY, int iSizeZ)
{
	ASSERT((nDimensions > 0) && (nDimensions <= 3));

	Free();

	if ((nDimensions < 1) || (nDimensions > 3))
		return false;

	this->nDimensions = nDimensions;

	iSize[0] = iSizeX;
	iSize[1] = iSizeY;
	iSize[2] = iSizeZ;

	nTotalItems = 1;
	for (int i=0; i<nDimensions; i++)
		nTotalItems *= iSize[i];

	ASSERT(nTotalItems);
	if (!nTotalItems)
		return false;

	fValues = new double[nTotalItems];
	if (!fValues)
		return false;

	return true;
}

void CDoubleArray::Free()
{
	if (fValues)
	{
		delete[] fValues;
		fValues = NULL;	
	}
	memset(iSize, 0, sizeof(int)*3);
	nTotalItems = 0;
	nDimensions = 0;
}

bool CDoubleArray::SetAtAbsoluteIndex(double fValue, int iIndex)
{
	ASSERT(fValues);
	if (!fValues)
		return false;

	if (iIndex < 0 || iIndex >= nTotalItems)
		return false;

	fValues[iIndex] = fValue;

//	wxLogDebug("Adding %f to [%d]", fValue, iIndex);

	return true;
}

bool CDoubleArray::GetAtAbsoluteIndex(double *pValue, int iIndex)
{
	ASSERT(fValues);
	if (!fValues)
		return false;

	if (iIndex < 0 || iIndex >= nTotalItems)
		return false;

	*pValue = fValues[iIndex];

//	wxLogDebug("Returning %f from [%d]", *pValue, iIndex);

	return true;
}

bool CDoubleArray::SetValue(double fValue, int x, int y, int z)
{
	if (nDimensions == 1)
		return SetAtAbsoluteIndex(fValue, x);

	if (x < 0 || x >= iSize[0] || y < 0 || y >= iSize[1])
		return false;

	if (nDimensions == 2)
		return SetAtAbsoluteIndex(fValue, x + y*iSize[0]);

	if (z < 0 || z >= iSize[2])
		return false;

	return SetAtAbsoluteIndex(fValue, x + y*iSize[0] + z*iSize[1]*iSize[0]);
}

bool CDoubleArray::GetValue(double *pValue, int x, int y, int z)
{
	if (nDimensions == 1)
		return GetAtAbsoluteIndex(pValue, x);

	if (x < 0 || x >= iSize[0] || y < 0 || y >= iSize[1])
		return false;

	if (nDimensions == 2)
		return GetAtAbsoluteIndex(pValue, x + y*iSize[0]);

	if (z < 0 || z >= iSize[2])
		return false;

	return GetAtAbsoluteIndex(pValue, x + y*iSize[0] + z*iSize[1]*iSize[0]);
}

bool CDoubleArray::CheckSizes(int nDims, int iSizeX, int iSizeY, int iSizeZ)
{
	if (nDims != nDimensions)
		return false;
	
	if (iSize[0] != iSizeX)
		return false;

	if (nDimensions > 1)
	{
		if (iSize[1] != iSizeY)
			return false;
		
		if (nDimensions > 2)
			if (iSize[2] != iSizeZ)
				return false;
	}
	return true;
}
