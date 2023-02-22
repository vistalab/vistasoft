class Fragment {
private:
    double P[3]; // Position XYZ coordinates
    int PS[2]; // Screen position
    double T[2]; // Texture IJ coordinates
    double C[4]; // Color
    double N[3]; // Normal
    bool frontfacing;
    Scene *S;
public:
    Fragment(){}
    Fragment(double x1, double y1, double z1) { P[0]=x1; P[1]=y1; P[2]=z1; }
    
    void setP(double x1, double y1, double z1) { P[0]=x1; P[1]=y1; P[2]=z1; }
    void setPS(int i, int j) { PS[0]=i; PS[1]=j;}
    void setN(double x1, double y1, double z1) { N[0]=x1; N[1]=y1; N[2]=z1; }
    void setT(double i, double j) { T[0]=i; T[1]=j; }
    void setC(double r, double g, double b, double a) { C[0]=r; C[1]=g; C[2]=b; C[3]=a;}
    void setFrontFacing(bool f){ frontfacing=f; }
    void setRenderScene(Scene *St) { S=St; } ;
    
    void renderFragment() {
        if(S[0].enablestenciltest)
        {
            // Do the stencil test
            bool stenciltest = S[0].I.checkstencil(PS[0], PS[1], S[0].stencilreferencevalue , S[0].stencilfunction);

            // Stop rendering if stencil test fails
            if(stenciltest!=true) {
                // Update stencil
                S[0].I.updatestencil(PS[0], PS[1], S[0].stencilreferencevalue, S[0].stencilfail,frontfacing);
                return;
            }
        }

        if(S[0].enabledepthtest)
        {
            // Do the depth test
            bool depthtest = S[0].I.checkdepth(PS[0], PS[1], P[2], S[0].depthfunction);

             // Stop rendering if depth test fails
            if(depthtest!=true) {
                // Update stencil
                if(S[0].enablestenciltest)
                {
                    S[0].I.updatestencil(PS[0], PS[1], S[0].stencilreferencevalue, S[0].stencilpassdepthbufferfail,frontfacing);
                }
                return;
            }
            else {
                // Update stencil
                if(S[0].enablestenciltest)
                {
                    S[0].I.updatestencil(PS[0], PS[1], S[0].stencilreferencevalue, S[0].stencilpassdepthbufferpass,frontfacing);
                }
            }
        }
        
        if(S[0].colorbufferwrite )
        {
            
            double rgba[4];
            if(S[0].enabletexture) {
                // Color Pixel with Texture
                S[0].T.getpixel(T[0], T[1],rgba);
            }
            else {
                // Color Pixel
                rgba[0]=C[0]; rgba[1]=C[1]; rgba[2]=C[2]; rgba[3]=C[3];
            }
           
            // Use phong shading if enabled
            if(S[0].enableshading) {
                S[0].Q.PhongLight(N, P, rgba);
            }
        
            // Do the blending
            if(S[0].enableblending)
            {
                rgba[3]=0.5;
                double d[4];
                S[0].I.getpixel(PS[0], PS[1] , d);
                S[0].I.Blend(rgba, d, S[0].blendcolor, S[0].blendfunction[0], S[0].blendfunction[1]); 
            }
       
            // Draw the pixel
            S[0].I.setpixel(PS[0], PS[1], rgba);
            
        }
        
        if(S[0].depthbufferwrite)
        {
            // Set depth buffer
            S[0].I.setdepth(PS[0], PS[1], P[2]);
        }
    }
};



