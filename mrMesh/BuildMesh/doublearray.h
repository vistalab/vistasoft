#ifndef _DOUBLEARRAY_H_
#define _DOUBLEARRAY_H_

/// Array used by CParametersMap

class CDoubleArray
{
public:
	CDoubleArray();
	virtual ~CDoubleArray();

	bool	Create(int nDimensions, int iSizeX, int iSizeY=0, int iSizeZ=0);

	bool	GetValue(double *pValue, int x, int y=0, int z=0);
	bool	GetValueRounded(int *pValue, int x, int y=0, int z=0);
	bool	SetValue(double fValue, int x, int y=0, int z=0);

	bool	SetAtAbsoluteIndex(double fValue, int iIndex);
	bool	GetAtAbsoluteIndex(double *pValue, int iIndex);

	double	*GetPointer()
	{
		return fValues;
	}

	int		GetNumberOfItems()
	{
		return nTotalItems;
	}
	int		GetNumberOfDimensions()
	{
		return nDimensions;
	}
	const int *GetSizes()
	{
		return iSize;
	}

	/// checks if array has right dimensions
	bool	CheckSizes(int nDims, int iSizeX, int iSizeY = 0, int iSizeZ = 0);
private:
	int		nDimensions;
	int		iSize[3];
	int		nTotalItems;	///< count of fValues
	double	*fValues;

	void	Free();
};

#endif //_DOUBLEARRAY_H_
