class Vertice {
private:
        double P[3]; // Position XYZ coordinates
        double T[2]; // Texture IJ coordinates
        double C[4]; // Color
        double N[3]; // Normal
public:
        Vertice() {}
        void setP(double x, double y, double z) { P[0]=x; P[1]=y; P[2]=z; }
        void setN(double nx, double ny, double nz) { N[0]=nx; N[1]=ny; N[2]=nz; }
        void setT(double i, double j) { T[0]=i; T[1]=j; }
        void setC(double r, double g, double b) { C[0]=r; C[1]=g; C[2]=b; C[3]=1;}
        void setC(double r, double g, double b, double a) { C[0]=r; C[1]=g; C[2]=b; C[3]=a;}

        double *getP() { return P; }
        double getPx() { return P[0]; }
        double getPy() { return P[1]; }
        double getPz() { return P[2]; }

        double *getN() { return N; }
        double getNx() { return N[0]; }
        double getNy() { return N[1]; }
        double getNz() { return N[2]; }
        
        double *getT() { return T; }
        double getTi() { return T[0]; }
        double getTj() { return T[1]; }

        double *getC() { return C; }
        double getCr() { return C[0]; }
        double getCg() { return C[1]; }
        double getCb() { return C[2]; }
        double getCa() { return C[3]; }
};

