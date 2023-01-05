class Transformation {
private:
    double ModelViewMatrix[16];
    double ModelViewMatrixInverseTrans[16];
    double ProjectionMatrix[16];
    double Object2ClipMatrix[16];
    double ViewPort[4];
    double DepthRange[2];
public:
    Transformation() {
        ModelViewMatrix[0]=1; ModelViewMatrix[4]=0; ModelViewMatrix[8]=0;  ModelViewMatrix[12]=0;
        ModelViewMatrix[1]=0; ModelViewMatrix[5]=1; ModelViewMatrix[9]=0;  ModelViewMatrix[13]=0;
        ModelViewMatrix[2]=0; ModelViewMatrix[6]=0; ModelViewMatrix[10]=1; ModelViewMatrix[14]=0;
        ModelViewMatrix[3]=0; ModelViewMatrix[7]=0; ModelViewMatrix[11]=0; ModelViewMatrix[15]=1;
        
        ProjectionMatrix[0]=1; ProjectionMatrix[4]=0; ProjectionMatrix[8]=0;  ProjectionMatrix[12]=0;
        ProjectionMatrix[1]=0; ProjectionMatrix[5]=1; ProjectionMatrix[9]=0;  ProjectionMatrix[13]=0;
        ProjectionMatrix[2]=0; ProjectionMatrix[6]=0; ProjectionMatrix[10]=1; ProjectionMatrix[14]=0;
        ProjectionMatrix[3]=0; ProjectionMatrix[7]=0; ProjectionMatrix[11]=0; ProjectionMatrix[15]=1;
        // Make total transformation matrix
        Matrix4TimesMatrix(ProjectionMatrix, ModelViewMatrix,Object2ClipMatrix);
        // Make the inverse model view matrix
        double ModelViewMatrixInverse[16];
        matrix_inverse(ModelViewMatrix, ModelViewMatrixInverse, 4);
        matrix4Transpose(ModelViewMatrixInverse, ModelViewMatrixInverseTrans);
        DepthRange[0]=-1;
        DepthRange[1]=1;
        ViewPort[0]=0;
        ViewPort[1]=0;
        ViewPort[2]=100;
        ViewPort[3]=100;
    }
    
    void setModelViewMatrix(double *A) {
        for(int i=0; i<16; i++) { ModelViewMatrix[i]=A[i]; }
    }
    
    void setProjectionMatrix(double *A) {
        for(int i=0; i<16; i++) { ProjectionMatrix[i]=A[i]; }
        ProjectionMatrix[3]=0; ProjectionMatrix[7]=0; ProjectionMatrix[11]=0; ProjectionMatrix[15]=1;
    }
   
    void makeInverseMatrices()
    {
         // Make total transformation matrix
        Matrix4TimesMatrix(ProjectionMatrix, ModelViewMatrix,Object2ClipMatrix);
        // Make the inverse model view matrix
        double ModelViewMatrixInverse[16];
        matrix_inverse(ModelViewMatrix, ModelViewMatrixInverse, 4);
        matrix4Transpose(ModelViewMatrixInverse, ModelViewMatrixInverseTrans);
    }
    
    void matrix4Transpose(double *MI, double *MK) {
        MK[0]=MI[0]; MK[4]=MI[1];  MK[8]=MI[2];   MK[12]=MI[3];
        MK[1]=MI[4]; MK[5]=MI[5];  MK[9]=MI[6];   MK[13]=MI[7];
        MK[2]=MI[8]; MK[6]=MI[9];  MK[10]=MI[10]; MK[14]=MI[11];
        MK[3]=MI[12]; MK[7]=MI[13];MK[11]=MI[14]; MK[15]=MI[15];
    }
    
    double * TransformVertices(double *Vin, int length) {
        // Instead of rotating a view vector, the object vertices 
        // are transformed (As in OpenGL)
        // There are several transformations from Object Coord ->
        // World coord -> Clip coord -> Normalized Device Coordinates
        // range [-1..1] -> Window Coordinates
        double *Vout;
        double Vt[4];
        double Ut[4];
        int index1, index2, index3;
        Vout = new double[length*3];
        for(int i=0; i<length; i++) {
            index1=i; index2=index1+length; index3=index2+length;
            Vt[0]=Vin[index1]; Vt[1]=Vin[index2]; Vt[2]=Vin[index3]; Vt[3]=1;
            // Object to Clip coordinates
            Matrix4TimesVector(Object2ClipMatrix, Vt, Ut);
            // Normalized Device Coordinates (NDC)
            Ut[0] = Ut[0] / Ut[3];
            Ut[1] = Ut[1] / Ut[3];
            Ut[2] = Ut[2] / Ut[3];
            Vout[index1]=Ut[0];
            Vout[index2]=Ut[1];
            Vout[index3]=Ut[2];
        }
        return Vout;
    }

    double * NDCtoScreenCoordinates(double * Vt, double *Ut)
    {
        double x=ViewPort[0];
        double y=ViewPort[1];
        double w=ViewPort[2];
        double h=ViewPort[3];
        double n=DepthRange[0];
        double f=DepthRange[1];
        // Window Coordinates / Screen Coordinates
        Ut[0] = (w/2) * Vt[0] + (x + w/2)-0.5;
        Ut[1] = (h/2) * Vt[1] + (y + h/2)-0.5;
        Ut[2] = ((f-n)/2) * Vt[2] + ((f+n)/2);
        return Ut;
    }
            
    double * TransformNormals(double *Nin, int length) {
        // Instead of rotating a view vector, the object vertices 
        // are transformed thus the normal vectors have to transformed
        // with the inverse transposed modelviewmatrix. (As in OpenGL)
        double *Nout;
        double Vt[4];
        double Ut[4];
        int index1, index2, index3;
        Nout = new double[length*3];
        for(int i=0; i<length; i++) {
            index1=i; index2=index1+length; index3=index2+length;
            Vt[0]=Nin[index1]; Vt[1]=Nin[index2]; Vt[2]=Nin[index3]; Vt[3]=1;
            Matrix4TimesVector(ModelViewMatrixInverseTrans, Vt, Ut);
            Nout[index1]=Ut[0]; Nout[index2]=Ut[1]; Nout[index3]=Ut[2];
        }
        return Nout;
    }
    
    double * TransformTextureVertices(double *TVin, int length, int sizex, int sizey) {
        // Texture coordinates are defined in the range [0..1], this function
        // transforms the coordinates to [0 sizeimage-1] (for pixel sampling)
        double *TVout;
        int index1, index2;
        TVout = new double[length*2];
        for(int i=0; i<length; i++) {
            index1=i; index2=index1+length;
            TVout[index1]=TVin[index1]*(sizex-1);
            TVout[index2]=TVin[index2]*(sizey-1);
        }
        return TVout;
    }
    
    
    void setViewport(double *A) {
        for(int i=0; i<4; i++) {  ViewPort[i]=A[i]; }
    }
    
    void setDepthRange(double *A) {
        DepthRange[0]=A[0]; DepthRange[1]=A[1];
    }
    
    void Matrix4TimesVector(double * M, double *V, double *U) {
        U[0]=M[0]*V[0]+M[4]*V[1]+M[8]*V[2]+M[12]*V[3];
        U[1]=M[1]*V[0]+M[5]*V[1]+M[9]*V[2]+M[13]*V[3];
        U[2]=M[2]*V[0]+M[6]*V[1]+M[10]*V[2]+M[14]*V[3];
        U[3]=M[3]*V[0]+M[7]*V[1]+M[11]*V[2]+M[15]*V[3];
    }
    
    void Matrix4TimesMatrix(double * A, double *B, double *C) {
        C[0] = A[0]*B[0] + A[4]*B[1] + A[8]*B[2] + A[12]*B[3];
        C[1] = A[1]*B[0] + A[5]*B[1] + A[9]*B[2] + A[13]*B[3];
        C[2] = A[2]*B[0] + A[6]*B[1] + A[10]*B[2]+ A[14]*B[3];
        C[3] = A[3]*B[0] + A[7]*B[1] + A[11]*B[2]+ A[15]*B[3];
        C[4] = A[0]*B[4] + A[4]*B[5] + A[8]*B[6] + A[12]*B[7];
        C[5] = A[1]*B[4] + A[5]*B[5] + A[9]*B[6] + A[13]*B[7];
        C[6] = A[2]*B[4] + A[6]*B[5] + A[10]*B[6]+ A[14]*B[7];
        C[7] = A[3]*B[4] + A[7]*B[5] + A[11]*B[6]+ A[15]*B[7];
        C[8] = A[0]*B[8] + A[4]*B[9] + A[8]*B[10] + A[12]*B[11];
        C[9] = A[1]*B[8] + A[5]*B[9] + A[9]*B[10] + A[13]*B[11];
        C[10]= A[2]*B[8] + A[6]*B[9] + A[10]*B[10]+ A[14]*B[11];
        C[11]= A[3]*B[8] + A[7]*B[9] + A[11]*B[10]+ A[15]*B[11];
        C[12]= A[0]*B[12] + A[4]*B[13] + A[8]*B[14] + A[12]*B[15];
        C[13]= A[1]*B[12] + A[5]*B[13] + A[9]*B[14] + A[13]*B[15];
        C[14]= A[2]*B[12] + A[6]*B[13] + A[10]*B[14]+ A[14]*B[15];
        C[15]= A[3]*B[12] + A[7]*B[13] + A[11]*B[14]+ A[15]*B[15];
    }
    
    void matrix_inverse(double *Min, double *Mout, int actualsize) {
        /* This function calculates the inverse of a square matrix
         *
         * matrix_inverse(double *Min, double *Mout, int actualsize)
         *
         * Min : Pointer to Input square Double Matrix
         * Mout : Pointer to Output (empty) memory space with size of Min
         * actualsize : The number of rows/columns
         *
         * Notes:
         *  - the matrix must be invertible
         *  - there's no pivoting of rows or columns, hence,
         *        accuracy might not be adequate for your needs.
         *
         * Code is rewritten from c++ template code Mike Dinolfo
         */
        /* Loop variables */
        int i, j, k;
        /* Sum variables */
        double sum, x;
        /*  Copy the input matrix to output matrix */
        for(i=0; i<actualsize*actualsize; i++) { Mout[i]=Min[i]; }
        /* Add small value to diagonal if diagonal is zero */
        for(i=0; i<actualsize; i++) {
            j=i*actualsize+i; if((Mout[j]<1e-12)&&(Mout[j]>-1e-12)){ Mout[j]=1e-12; }
        }
        /* Matrix size must be larger than one */
        if (actualsize <= 1) return;
        /* normalize row 0 */
        for (i=1; i < actualsize; i++) { Mout[i] /= Mout[0];  }
        for (i=1; i < actualsize; i++)  {
            for (j=i; j < actualsize; j++)  { /* do a column of L */
                sum = 0.0;
                for (k = 0; k < i; k++) {
                    sum += Mout[j*actualsize+k] * Mout[k*actualsize+i];
                } Mout[j*actualsize+i] -= sum;
            }
            if (i == actualsize-1) continue;
            for (j=i+1; j < actualsize; j++)  {  /* do a row of U */
                sum = 0.0;
                for (k = 0; k < i; k++) {
                    sum += Mout[i*actualsize+k]*Mout[k*actualsize+j];
                } Mout[i*actualsize+j] = (Mout[i*actualsize+j]-sum) / Mout[i*actualsize+i];
            }
        }
        for ( i = 0; i < actualsize; i++ )  /* invert L */ {
            for ( j = i; j < actualsize; j++ )  {
                x = 1.0;
                if ( i != j ) {
                    x = 0.0;
                    for ( k = i; k < j; k++ ) {
                        x -= Mout[j*actualsize+k]*Mout[k*actualsize+i];
                    }
                } Mout[j*actualsize+i] = x / Mout[j*actualsize+j];
            }
        }
        for ( i = 0; i < actualsize; i++ ) /* invert U */ {
            for ( j = i; j < actualsize; j++ )  {
                if ( i == j ) continue;
                sum = 0.0;
                for ( k = i; k < j; k++ ) {
                    sum += Mout[k*actualsize+j]*( (i==k) ? 1.0 : Mout[i*actualsize+k] );
                } Mout[i*actualsize+j] = -sum;
            }
        }
        for ( i = 0; i < actualsize; i++ ) /* final inversion */ {
            for ( j = 0; j < actualsize; j++ )  {
                sum = 0.0;
                for ( k = ((i>j)?i:j); k < actualsize; k++ ) {
                    sum += ((j==k)?1.0:Mout[j*actualsize+k])*Mout[k*actualsize+i];
                } Mout[j*actualsize+i] = sum;
            }
        }
    }
};
