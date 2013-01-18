#ifndef _VECTOR_H_
#define _VECTOR_H_

class CVector
{
public:
	double	x, y, z;
    
public:
    
	CVector() {x = y = z = 0;}
	CVector(const CVector &v) {x = v.x; y = v.y; z = v.z;}
	CVector(double _x, double _y, double _z) {x = _x; y = _y; z = _z;}

	double operator *(const CVector &v) const
	{
		return x*v.x + y*v.y + z*v.z;
	}
	CVector operator ^(const CVector &v) const
	{
		return CVector(y*v.z - z*v.y, z*v.x - x*v.z, x*v.y - y*v.x);
	}
	CVector operator +(const CVector &v) const
	{
		return CVector(x+v.x, y+v.y, z+v.z);
	}
	CVector operator -(const CVector &v) const
	{
		return CVector(x-v.x, y-v.y, z-v.z);
	}
	CVector& operator +=(const CVector &v)
	{
		x += v.x;
		y += v.y;
		z += v.z;
		return *this;
	}
	CVector& operator -=(const CVector &v)
	{
		x -= v.x;
		y -= v.y;
		z -= v.z;
		return *this;
	}
	CVector operator *(double fScale)
	{
		return CVector(x*fScale, y*fScale, z*fScale);
	}
	CVector operator /(double fScale)
	{
		double fInvScale = 1.0f / fScale;
		return CVector(x * fInvScale, y * fInvScale, z * fInvScale);
	}
	CVector& operator *=(double fScale)
	{
		x *= fScale;
		y *= fScale;
		z *= fScale;
		return *this;
	}
	double GetMagnitude()
	{
		//return CFastMath::SqrtLt(x*x + y*y + z*z);
		return FastSqrtLt(x*x + y*y + z*z);
	}
	void Normalize()
	{
		double l = x*x + y*y + z*z;
		//l = CFastMath::InvSqrtLt(l);
		l = FastInvSqrtLt(l);
		x = x * l;
		y = y * l;
		z = z * l;
	}
	CVector operator -() const
	{
		return CVector(-x, -y, -z);
	}
	operator double*()
	{
		return &x;
	}
	operator const double*()
	{
		return &x;
	}
};

struct	Vertex
{
    CVector	vCoord;
    CVector	vNormal;
    CColor	cColor;
};

struct	Triangle
{
    int v[3];
};

#endif	// _VECTOR_H_
