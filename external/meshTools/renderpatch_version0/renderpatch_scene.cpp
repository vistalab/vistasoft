class Scene {
public:
    bool enableblending;
    bool enabledepthtest;
    bool enablestenciltest;
    bool enabletexture;
    bool enableshading;
    int depthfunction;
    int stencilfunction;
    double stencilreferencevalue;
    int stencilfail;
    int stencilpassdepthbufferfail;
    int stencilpassdepthbufferpass;
    bool depthbufferwrite;
    bool colorbufferwrite;
    int culling;
    int blendfunction[2];
    double blendcolor[4];
    Shading Q;
    Texture T;
    RenderImage I;
    Transformation TT;

    Scene()
    {
        enableblending=false;
        enabledepthtest=false;
        enablestenciltest=false;
        enabletexture=false;
        enableshading=false;
        depthfunction =2;
        stencilfunction =1;
        stencilreferencevalue =0;
        stencilfail = 0;
        stencilpassdepthbufferfail=0;
        stencilpassdepthbufferpass=0;
        depthbufferwrite = true;
        colorbufferwrite = true;
        culling=1;
        blendfunction[0]=7;
        blendfunction[1]=6;
        blendcolor[0]=1; 
        blendcolor[1]=0; 
        blendcolor[2]=0; 
        blendcolor[3]=1;
    }
};

