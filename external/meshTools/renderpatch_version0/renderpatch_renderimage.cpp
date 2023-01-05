class RenderImage{
private:
    double *I;
    int size[3];
    int npixels;
public:
    RenderImage(){};
    RenderImage(double *It, int sizx, int sizy) {
        I=It; size[0]=sizx; size[1]=sizy;
        npixels = size[0]*size[1];
    }
    int getsize(int i){ return size[i]; }
    
    void setpixel(int i, int j, double* rgba) {
        // Set a pixel RGBA
        // It would be much faster to have RGBA as first dimension, but
        // Matlab default is RGBA as last dimension.
        int indexr, indexg, indexb, indexa;
        indexr = i + j * size[0];
        indexg=indexr+npixels;
        indexb=indexg+npixels;
        indexa=indexb+npixels;
        I[indexr]=rgba[0];
        I[indexg]=rgba[1];
        I[indexb]=rgba[2];
        I[indexa]=rgba[3];
    }
    
    void getpixel(int i, int j, double *rgba) {
        int indexr, indexg, indexb, indexa;
        indexr = i + j * size[0]; indexg=indexr+npixels;
        indexb=indexg+npixels; indexa=indexb+npixels;
        rgba[0]=I[indexr]; rgba[1]=I[indexg];
        rgba[2]=I[indexb]; rgba[3]=I[indexa];
    }
    
    void setdepth(int i, int j, double z) {
        int index = i + j * size[0] + npixels*4;
        I[index]=z;
    }
    
    void updatestencil(int i, int j, double sf, int mode,bool frontfacing) {
        int index = i + j * size[0] + npixels*5;
        switch(mode){
            case 1: I[index]=0; break;
            case 2: I[index]=sf; break; 
            case 3: I[index]++; break;
            case 4: I[index]--; break;
            case 5: if(frontfacing){I[index]++;}else{I[index]--;}; break;
            
        };
    }
    
    bool checkdepth(int i, int j, double zf, int mode) {
        double zb=I[i + j * size[0] + npixels*4];
        switch(mode){
            case 0: return false; break;
            case 1: return true; break;
            case 2: return zf<zb; break;
            case 3: return zf<=zb; break;
            case 4: return zf==zb; break;
            case 5: return zf>=zb; break;
            case 6: return zf>zb; break;
            case 7: return zf!=zb; break;
        };
        return false;    
    }
    
    bool checkstencil(int i, int j, double sf, int mode) {
        double sb=I[i + j * size[0] + npixels*5];
        switch(mode){
            case 0: return false; break;
            case 1: return true; break;
            case 2: return sf<sb; break;
            case 3: return sf<=sb; break;
            case 4: return sf==sb; break;
            case 5: return sf>=sb; break;
            case 6: return sf>sb; break;
            case 7: return sf!=sb; break;
        };
        return false;
    }
    
    void Blend(double *s, double *d, double *c, int modes, int moded) {
        double fs[4];
        double fd[4];
        BlendScaleFactors(s, d, c, modes,fs);
        BlendScaleFactors(s, d, c, moded,fd);
        for(int i=0; i<4; i++) { s[i]=mind(1, s[i]*fs[i]+d[i]*fd[i]); }
    }
    
    void BlendScaleFactors(double *s, double *d, double *c, int mode, double *f) {
        double i;
        switch(mode){
            case 0: f[0]=0; f[1]=0; f[2]=0; f[3]=0; break; // 0:ZERO
            case 1: f[0]=1; f[1]=1; f[2]=1; f[3]=1; break; //1:ONE
            case 2: f[0]=s[0]; f[1]=s[1]; f[2]=s[2]; f[3]=s[3]; break; // 2:SRC_COLOR
            case 3: f[0]=1-s[0]; f[1]=1-s[1]; f[2]=1-s[2]; f[3]=1-s[3]; break;// 3:ONE_MINUS_SRC_COLOR
            case 4: f[0]=d[0]; f[1]=d[1]; f[2]=d[2]; f[3]=d[3];  break; // 4:DST_COLOR
            case 5: f[0]=1-d[0]; f[1]=1-d[1]; f[2]=1-d[2]; f[3]=1-d[3]; break; // 5:ONE_MINUS_DST_COLOR
            case 6: f[0]=s[3]; f[1]=s[3]; f[2]=s[3]; f[3]=s[3]; break; // 6:SRC_ALPHA
            case 7: f[0]=1-s[3]; f[1]=1-s[3]; f[2]=1-s[3]; f[3]=1-s[3];  break; // 7:ONE_MINUS_SRC_ALPHA
            case 8: f[0]=d[3]; f[1]=d[3]; f[2]=d[3]; f[3]=d[3]; break; // 8:DST_ALPHA
            case 9: f[0]=1-d[3]; f[1]=1-d[3]; f[2]=1-d[3]; f[3]=1-d[3]; break; // 9:ONE_MINUS_DST_ALPHA
            case 10: i=mind(s[3], 1-d[3]); f[0]=i; f[1]=i; f[2]=i; f[3]=1; break; // 10:SRC_ALPHA_SATURATE
            case 11: f[0]=c[0]; f[1]=c[1]; f[2]=c[2]; f[3]=c[3]; break; // 11:CONSTANT_COLOR
            case 12: f[0]=1-c[0]; f[1]=1-c[1]; f[2]=1-c[2]; f[3]=1-c[3]; break; // 12:ONE_MINUS_CONSTANT_COLOR
            case 13: f[0]=c[3]; f[1]=c[3]; f[2]=c[3]; f[3]=c[3]; break; // 13:CONSTANT_ALPHA
            case 14: f[0]=1-c[3]; f[1]=1-c[3]; f[2]=1-c[3]; f[3]=1-c[3]; break; // 14:ONE_MINUS_CONSTANT_ALPHA
        };
    }
};

