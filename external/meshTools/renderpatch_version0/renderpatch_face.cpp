class Face {
private:
    Vertice V[3];
public:
    bool frontfacing;
    Face(){}
    void set(Vertice a, Vertice b, Vertice c) 
    { 
        V[0]=a; V[1]=b; V[2]=c; 
        
        double *a2, *b2, *c2, v1[2], v2[2];
        a2=V[0].getP(); b2=V[1].getP();  c2=V[2].getP();
        v1[0]=a2[0]-b2[0]; v1[1]=a2[1]-b2[1];
        v2[0]=a2[0]-c2[0]; v2[1]=a2[1]-c2[1];
        if((v1[0]*v2[1]-v1[1]*v2[0])>=0) { frontfacing = true; } else { frontfacing = false; }
    }

    void drawFace(Scene *S) {
        
        // Return if face is not visible
        /*
        if((V[0].getPx()<-1)&&(V[1].getPx()<-1)&&(V[2].getPx()<-1)){ return; }
        if((V[0].getPx()> 1)&&(V[1].getPx() >1)&&(V[2].getPx()> 1)){ return; }
        if((V[0].getPy()<-1)&&(V[1].getPy()<-1)&&(V[2].getPy()<-1)){ return; }
        if((V[0].getPy()> 1)&&(V[1].getPy() >1)&&(V[2].getPy()> 1)){ return; }
        if((V[0].getPz()<-1)&&(V[1].getPz()<-1)&&(V[2].getPz()<-1)){ return; }
        if((V[0].getPz()> 1)&&(V[1].getPz() >1)&&(V[2].getPz()> 1)){ return; }
        */
        
        double VN0[3]; 
        double VN1[3]; 
        double VN2[3];
        S[0].TT.NDCtoScreenCoordinates(V[0].getP(),VN0);
        S[0].TT.NDCtoScreenCoordinates(V[1].getP(),VN1);        
        S[0].TT.NDCtoScreenCoordinates(V[2].getP(),VN2);
        
        // Normalization factors
        double f12 = ( VN1[1] - VN2[1] ) * VN0[0]  + (VN2[0] - VN1[0] ) * VN0[1] + VN1[0] * VN2[1] - VN2[0] *VN1[1];
        double f20 = ( VN2[1] - VN0[1] ) * VN1[0]  + (VN0[0] - VN2[0] ) * VN1[1] + VN2[0] * VN0[1] - VN0[0] *VN2[1];
        double f01 = ( VN0[1] - VN1[1] ) * VN2[0]  + (VN1[0] - VN0[0] ) * VN2[1] + VN0[0] * VN1[1] - VN1[0] *VN0[1];
        
        // Lambda Gradient
        double g12x = ( VN1[1] - VN2[1] )/f12;
        double g12y = ( VN2[0] - VN1[0] )/f12;
        double g20x = ( VN2[1] - VN0[1] )/f20;
        double g20y = ( VN0[0] - VN2[0] )/f20;
        double g01x = ( VN0[1] - VN1[1] )/f01;
        double g01y = ( VN1[0] - VN0[0] )/f01;
        
        // Center compensation
        double c12 = (VN1[0] * VN2[1] - VN2[0] *VN1[1])/f12;
        double c20 = (VN2[0] * VN0[1] - VN0[0] *VN2[1])/f20;
        double c01 = (VN0[0] * VN1[1] - VN1[0] *VN0[1])/f01;
        
        // Interpolation values
        double Lambda[3]={0, 0, 0};
        double Lambda_y[3]={0, 0, 0};
        double rx, ry;
        int bmx, bpx;
        int bmy, bpy;
        
        bmx=(int)floor(mind(mind(VN0[0], VN1[0]), VN2[0])); 
        bmy=(int)floor(mind(mind(VN0[1], VN1[1]), VN2[1]));
        bpx=(int)ceil( maxd(maxd(VN0[0], VN1[0]), VN2[0]));  
        bpy=(int)ceil( maxd(maxd(VN0[1], VN1[1]), VN2[1]));
        
        // Draw not outside of image
        bmx = maxd(bmx, 0); bmy = maxd(bmy, 0);
        bpx = mind(bpx, S[0].I.getsize(0)-1); bpy = mind(bpy, S[0].I.getsize(1)-1);

        // From pixel coordinates to real pixel coordinates
        // Maybee some correction of 0.5 pixel needed to make
        // center of pixel the exact coordinate?
        rx=bmx; ry=bmy;
        
        // Interpolation values
        Lambda_y[0]=g12x*rx+g12y*ry+c12,
        Lambda_y[1]=g20x*rx+g20y*ry+c20,
        Lambda_y[2]=g01x*rx+g01y*ry+c01;
        
        Fragment Frag;
                    
        // Loop through bounding box
        for(int j=bmy; j<=bpy; j++) {
            // Update interpolation values
            Lambda[0]=Lambda_y[0]; Lambda[1]=Lambda_y[1]; Lambda[2]=Lambda_y[2];
            for(int i=bmx; i<=bpx; i++) {
                // Check if voxel is inside a polygon
                bool CheckInside=(Lambda[0]>=0)&&(Lambda[0]<=1)&&(Lambda[1]>=0)&&(Lambda[1]<=1)&& (Lambda[2]>=0)&&(Lambda[2]<=1);
                // The Rasterizing stage 
                if(CheckInside) {
                    // Set Fragment position
                    double x=Lambda[0]*V[0].getPx()+Lambda[1]*V[1].getPx()+Lambda[2]*V[2].getPx();
                    double y=Lambda[0]*V[0].getPy()+Lambda[1]*V[1].getPy()+Lambda[2]*V[2].getPy();
                    double z=Lambda[0]*V[0].getPz()+Lambda[1]*V[1].getPz()+Lambda[2]*V[2].getPz();
                    // Check if fragment is Inside the View Volume
                    bool InsideViewVolume=true; //(x>=-1)&&(x<=1)&&(y>=-1)&&(y<=1)&&(z>=-1)&&(z<=1);
                                 
                    if(InsideViewVolume)
                    {
                        Frag.setP(x,y,z);

                        // Set screen coordinates
                        Frag.setPS(i,j);

                        // Set front facing
                        Frag.setFrontFacing(frontfacing);

                        // Only calculate the values if used
                        if(S[0].colorbufferwrite)
                        {
                            // Set Fragment color
                            double color_r = Lambda[0]*V[0].getCr()+Lambda[1]*V[1].getCr()+Lambda[2]*V[2].getCr();
                            double color_g = Lambda[0]*V[0].getCg()+Lambda[1]*V[1].getCg()+Lambda[2]*V[2].getCg();
                            double color_b = Lambda[0]*V[0].getCb()+Lambda[1]*V[1].getCb()+Lambda[2]*V[2].getCb();
                            double color_a = Lambda[0]*V[0].getCa()+Lambda[1]*V[1].getCa()+Lambda[2]*V[2].getCa();
                            Frag.setC(color_r,color_g,color_b,color_a);

                            // Set Fragment normal
                            double normal_x = Lambda[0]*V[0].getNx()+Lambda[1]*V[1].getNx()+Lambda[2]*V[2].getNx();
                            double normal_y = Lambda[0]*V[0].getNy()+Lambda[1]*V[1].getNy()+Lambda[2]*V[2].getNy();
                            double normal_z = Lambda[0]*V[0].getNz()+Lambda[1]*V[1].getNz()+Lambda[2]*V[2].getNz();
                            Frag.setN(normal_x, normal_y, normal_z);

                            // Set texture coordinates
                            double texture_i = Lambda[0]*V[0].getTi()+Lambda[1]*V[1].getTi()+Lambda[2]*V[2].getTi();
                            double texture_j = Lambda[0]*V[0].getTj()+Lambda[1]*V[1].getTj()+Lambda[2]*V[2].getTj();
                            Frag.setT(texture_i, texture_j);
                        }
                        // Set render scene
                        Frag.setRenderScene(S);

                        // Start the fragment render pipeline
                        Frag.renderFragment();
                    }
                    
                }
                // Update interpolation values
                Lambda[0]+=g12x; Lambda[1]+=g20x; Lambda[2]+=g01x;
            }
            // Update interpolation values
            Lambda_y[0]+=g12y; Lambda_y[1]+=g20y; Lambda_y[2]+=g01y;
        }
    }
};
