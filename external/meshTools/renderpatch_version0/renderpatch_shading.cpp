class Shading {
private:
    double Id, Imult, Ioff, Is, Ia;
    double material[5];
    double V[3];
    double *LP;
    int nlights;
public:
    Shading() {
        material[0]=0.3; material[1]=0.6;
        material[2]=0.9; material[3]=20;
        material[4]=1;
        V[0]=0; V[1]=0; V[2]=-1;
        LP=new double[3];
        LP[0]=0.67; LP[1]=0.33; LP[2]=-2;
        nlights=1;
    }
    void setMaterial(double *M){ material[0]=M[0]; material[1]=M[1];
    material[2]=M[2]; material[3]=M[3];
    material[4]=M[4];}
    void setLightPosition(double *LV, int nlightst) { LP=LV; nlights=nlightst; }
    
    void PhongLight(double *N, double *P, double *rgba) {
        Ia=material[0];
        Imult=Ia;
        Ioff=0;
        // Normal is interpolated thus it is neat to 
        // normalization again
        normalize(N);
        
        // Calculate the phong shading values for multiple lights
        for(int j=0; j<nlights; j++)
        {
            double L[3];
            // Calculate Light Vector
			if(L[3]==0)
			{
				L[0]=LP[j];
				L[1]=LP[j+nlights];
				L[2]=LP[j+2*nlights];
            }
			else
			{
 				L[0]=(LP[j]-P[0]);
				L[1]=(LP[j+nlights]-P[1]);
				L[2]=(LP[j+2*nlights]-P[2]);
 			}
			
			double d=normalize(L);
            //d=300/(d*d);
            d=1;
            
            double R[3];
            double tr=2.0*dot(N, L);
            R[0]= tr*N[0] - L[0]; 
            R[1]= tr*N[1] - L[1]; 
            R[2]= tr*N[2] - L[2];
            
            Id = maxd(mind(material[1]*dot(N, L),1),-1);
            if(Id>0) { Is = pow(maxd(dot(R, V),0), material[3]); } else { Is=0; }
            Imult+= (d*(Id+1))-1+d*Is*material[4];
            Ioff+= d*Is*material[2];
        }

        rgba[0]=Imult*rgba[0]+Ioff;
        rgba[1]=Imult*rgba[1]+Ioff;
        rgba[2]=Imult*rgba[2]+Ioff;
        
        // In OpenGL it is common to limit RGB output to range [0..1]
        rgba[0]=mind(maxd(rgba[0], 0), 1);
        rgba[1]=mind(maxd(rgba[1], 0), 1);
        rgba[2]=mind(maxd(rgba[2], 0), 1);
    }
    
    double dot(double * A, double * B){ return A[0]*B[0]+A[1]*B[1]+A[2]*B[2]; }
    double normalize(double * A) {
        double l=sqrt(A[0]*A[0]+A[1]*A[1]+A[2]*A[2]);
        A[0]=A[0]/l; A[1]=A[1]/l; A[2]=A[2]/l;
        return l;
    }
    void cross(double *a, double *b, double *n) {
        n[0]=a[1]*b[2]-a[2]*b[1]; n[1]=a[2]*b[0]-a[0]*b[2]; n[2]=a[0]*b[1]-a[1]*b[0];
    }
};

