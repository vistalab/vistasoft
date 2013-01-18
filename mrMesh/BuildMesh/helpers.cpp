#include "helpers.h"

#ifndef min
	#define min(a,b) (a<b)?(a):(b)
#endif

void SwizzleInts(int *list, int n)
{
	unsigned long *p=(unsigned long *)list;
	while (n--)
	{
		unsigned long a=((*p)&0xFF000000)>>24;
		unsigned long b=((*p)&0x00FF0000)>>8;
		(*p)&=0x0000FFFF;
		(*p)|=(((*p)&0x0000FF00)<<8)|(((*p)&0x000000FF)<<24);
		(*p)&=0xFFFF0000;
		(*p)|=a|b;
		p++;
	}
}

void CalculateNormal(const double *p1, const double *p2, const double *p3, double *n, double *A/*=NULL*/)
{
	// Calculates the Normal to a triangle by calculating the
	// cross product of any two sides. The magnitude of this
	// cross product is twice the area of the triangle, and the
	// direction of the cross product is the normal to the triangle.
	// Can optionally store the area at the same time.
	double	v1[3],
			v2[3],
			len;
	enum {x=0,y=1,z=2};

	// Calculate vectors defining two of the sides
	v1[x] = p1[x] - p2[x];
	v1[y] = p1[y] - p2[y];
	v1[z] = p1[z] - p2[z];

	v2[x] = p2[x] - p3[x];
	v2[y] = p2[y] - p3[y];
	v2[z] = p2[z] - p3[z];



	// Take the cross product of the two vectors
	// This gives the normal to the triangle
	n[x] = v1[y]*v2[z] - v1[z]*v2[y];
	n[y] = v1[z]*v2[x] - v1[x]*v2[z];
	n[z] = v1[x]*v2[y] - v1[y]*v2[x];

	// Normalise the vector ( this gives twice the area)
	len = sqrt( n[x]*n[x] + n[y]*n[y] + n[z]*n[z] );

	// Maybe store the area if requested
	if (A)
		*A=len/2;

	// Normalise the normal
	if (len!=0.0)
	{
		double inv_len = 1.0/len;
		n[x] *= inv_len;
		n[y] *= inv_len;
		n[z] *= inv_len;
	}
}

// void CalculateNormal(const double *p1, const double *p2, const double *p3, double *n, double *A/*=NULL*/)
// {
// 	// Calculates the Normal to a triangle by calculating the
// 	// cross product of any two sides. The magnitude of this
// 	// cross product is twice the area of the triangle, and the
// 	// direction of the cross product is the normal to the triangle.
// 	// Can optionally store the area at the same time.
// 	double	v1[3],
// 			v2[3],
// //			len,
// 			inv_len,
// 			len_squared;
// 	enum {x=0,y=1,z=2};

// 	// Calculate vectors defining two of the sides
// 	v1[x] = p1[x] - p2[x];
// 	v1[y] = p1[y] - p2[y];
// 	v1[z] = p1[z] - p2[z];

// 	v2[x] = p2[x] - p3[x];
// 	v2[y] = p2[y] - p3[y];
// 	v2[z] = p2[z] - p3[z];

// 	// Take the cross product of the two vectors
// 	// This gives the normal to the triangle
// 	n[x] = v1[y]*v2[z] - v1[z]*v2[y];
// 	n[y] = v1[z]*v2[x] - v1[x]*v2[z];
// 	n[z] = v1[x]*v2[y] - v1[y]*v2[x];

// 	//// Normalise the vector ( this gives twice the area)
// 	//len = sqrtf( n[x]*n[x] + n[y]*n[y] + n[z]*n[z] );

// 	//// Maybe store the area if requested
// 	//if (A)
// 	//	*A=len/2;

// 	//// Normalise the normal
// 	//if (len!=0.0f)
// 	//{
// 	//	double inv_len = 1.0f/len;
// 	//	n[x] *= inv_len;
// 	//	n[y] *= inv_len;
// 	//	n[z] *= inv_len;
// 	//}

// 	// Normalise the vector ( this gives twice the area)
// 	len_squared = n[x]*n[x] + n[y]*n[y] + n[z]*n[z];
// 	inv_len = FastInvSqrt(len_squared);

// 	// Maybe store the area if requested
// 	if (A)
// 		*A = /*len/2*/ inv_len * len_squared / 2;

// 	// Normalise the normal
// //	if (len_squared!=0.0f)
// 	{
// 		n[x] *= inv_len;
// 		n[y] *= inv_len;
// 		n[z] *= inv_len;
// 	}
// }

void NormalizeVector(double *pVector3)
{
	double fLen = sqrtf(pVector3[0]*pVector3[0] + pVector3[1]*pVector3[1] + pVector3[2]+pVector3[2]);

	if (fLen == 0.0f)
		return;

	double fInvLen = 1.0f/fLen;

	pVector3[0] *= fInvLen;
	pVector3[1] *= fInvLen;
	pVector3[2] *= fInvLen;
}

#if defined(__INTEL__)

// 1/sqrt(x)
double __fastcall FastX86InvSqrt(double x)
{
	static double _0_47 = 0.47f;
	static double _1_47 = 1.47f;

	DWORD y;
	double r;
	_asm
	{
		mov     eax, 07F000000h+03F800000h // (ONE_AS_INTEGER<<1) + ONE_AS_INTEGER
		sub     eax, x
		sar     eax, 1

		mov     y, eax                      // y
		fld     _0_47                       // 0.47
		fmul    DWORD PTR x                 // x*0.47

		fld     DWORD PTR y
		fld     st(0)                       // y y x*0.47
		fmul    st(0), st(1)                // y*y y x*0.47

		fld     _1_47                       // 1.47 y*y y x*0.47
		fxch    st(3)                       // x*0.47 y*y y 1.47
		fmulp   st(1), st(0)                // x*0.47*y*y y 1.47
		fsubp   st(2), st(0)                // y 1.47-x*0.47*y*y
		fmulp   st(1), st(0)                // result
		fstp    y
		and     y, 07FFFFFFFh
	}
//	r = *(double *)&y;
	r = (double &)y;

	// optional
	r = (3.0f - x * (r * r)) * r * 0.5f; // remove for low accuracy
	return r;
}

double __fastcall FastX86Sqrt(double x)
{
	return x*FastX86InvSqrt(x);
}

// 1/sqrt(x)
double __fastcall FastX86InvSqrtLt(double x)
{
	static double _0_47 = 0.47f;
	static double _1_47 = 1.47f;

	DWORD y;
	double r;
	_asm
	{
		mov     eax, 07F000000h+03F800000h // (ONE_AS_INTEGER<<1) + ONE_AS_INTEGER
		sub     eax, x
		sar     eax, 1

		mov     y, eax                      // y
		fld     _0_47                       // 0.47
		fmul    DWORD PTR x                 // x*0.47

		fld     DWORD PTR y
		fld     st(0)                       // y y x*0.47
		fmul    st(0), st(1)                // y*y y x*0.47

		fld     _1_47                       // 1.47 y*y y x*0.47
		fxch    st(3)                       // x*0.47 y*y y 1.47
		fmulp   st(1), st(0)                // x*0.47*y*y y 1.47
		fsubp   st(2), st(0)                // y 1.47-x*0.47*y*y
		fmulp   st(1), st(0)                // result
		fstp    y
		and     y, 07FFFFFFFh
	}
//	r = *(double *)&y;
	r = (double &)y;
	return r;
}

double __fastcall FastX86SqrtLt(double x)
{
	return x*FastX86InvSqrtLt(x);
}

#endif // fast x86 math

int _ShellSortIncrement(long inc[], long size)
{
	int p1, p2, p3, s;

	p1 = p2 = p3 = 1;
	s = -1;
	do {
		if (++s % 2) 
		{
			inc[s] = 8*p1 - 6*p2 + 1;
		}
		else 
		{
			inc[s] = 9*p1 - 9*p3 + 1;
			p2 *= 2;
			p3 *= 2;
		}
		p1 *= 2;
	} while(3*inc[s] < size);  

	return s > 0 ? --s : 0;
}

template<class T>
void ShellSort(T a[], long size) {
	long inc, i, j, seq[40];
	int s;

	// calculating increments sequence
	s = _ShellSortIncrement(seq, size);
	while (s >= 0) {
		// sorting with 'inc[]' increments
		inc = seq[s--];

		for (i = inc; i < size; i++) {
			T temp = a[i];
			for (j = i-inc; (j >= 0) && (a[j] > temp); j -= inc)
				a[j+inc] = a[j];
			a[j+inc] = temp;
		}
	}
}

void ShellSortInt(int a[], long size, SortCallback compare_proc, void *pParam)
{
	long inc, i, j, seq[40];
	int s;

	// calculating increments sequence
	s = _ShellSortIncrement(seq, size);
	while (s >= 0) {
		// sorting with 'inc[]' increments
		inc = seq[s--];

		for (i = inc; i < size; i++) {
			int temp = a[i];
			for (j = i-inc; (j >= 0) && /*(a[j] > temp)*/compare_proc(a[j], temp, pParam); j -= inc)
				a[j+inc] = a[j];
			a[j+inc] = temp;
		}
	}
}
