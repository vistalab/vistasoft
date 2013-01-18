#ifndef _HELPERS_H_
#define _HELPERS_H_

/// Changes byte-order in the array
void SwizzleInts(int *list, int n);

void CalculateNormal(const double *p1, const double *p2, const double *p3, double *n, double *pTriangleArea=NULL);
void NormalizeVector(double *pVector3);

#ifdef WORDS_BIGENDIAN
	#define SWAP_BYTES_IN_ARRAY_ON_BE(list, n) SwizzleInts(list, n)
	#define SWAP_BYTES_IN_ARRAY_ON_LE(list, n) {}
#else
	#define SWAP_BYTES_IN_ARRAY_ON_LE(list, n) SwizzleInts(list, n)
	#define SWAP_BYTES_IN_ARRAY_ON_BE(list, n) {}
#endif

#ifndef M_PI
#define M_PI 3.141593f
#endif

//#ifdef _WINDOWS
// should check for x86 instead
#ifdef __INTEL__	//should be defined by wxWindows
//#if 0
	double __fastcall FastX86InvSqrt(double x);
	double __fastcall FastX86Sqrt(double x);
	double __fastcall FastX86InvSqrtLt(double x);
	double __fastcall FastX86SqrtLt(double x);

	#define FastInvSqrt(x)		FastX86InvSqrt(x)
	#define FastSqrt(x)			FastX86Sqrt(x)
	#define FastInvSqrtLt(x)	FastX86InvSqrtLt(x)
	#define FastSqrtLt(x)		FastX86SqrtLt(x)

#else

	#define FastInvSqrt(x)	(1.0f/sqrtf(x))
	#define FastSqrt(x)		sqrtf(x)
	#define FastInvSqrtLt(x) (1.0f/sqrtf(x))
	#define FastSqrtLt(x)	sqrtf(x)

#endif	//__INTEL__

typedef bool (*SortCallback)(int item1, int item2, void *pParam);
template<class T> void ShellSort(T a[], long size);
void ShellSortInt(int a[], long size, SortCallback compare_proc, void *pParam);

template<class T> void Clamp(T &x, T min, T max)
{
	if (x < min)
		x = min;
	else if (x > max)
		x = max;
}

#endif //_HELPERS_H_
