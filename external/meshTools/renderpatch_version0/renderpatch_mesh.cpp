class Mesh {
private:
    double *Nout, *Vout, *TVout;
    
    // Texture variables
    int TIin_dims[3];
    Texture *T;
    
    // Vertex data
    double *Vin;  
    int Vin_dims[2];  
    int Vin_ndims;
    
    // Face data
    double *Fin;  
    int Fin_dims[2];  
    int Fin_ndims;
   
    double *TVin; 
    int TVin_dims[2]; 
    int TVin_ndims;
    
    double *Cin;  
    int Cin_dims[2];  
    int Cin_ndims;
        
    double *Nin;  
    int Nin_dims[2];  
    int Nin_ndims;
 
    double *Min;  
    int Min_dims[2];  
    int Min_ndims;
    
    // ModelMatrix variables
    double *MVin; 
    int MVin_dims[2]; 
    
    bool TextureAvailable;
    bool NormalsAvailable;
    bool ColorsAvailable;
    bool ModelMatrixAvailable;
    bool TextureVerticesAvailable;
    bool MaterialAvailable;

public:
    Mesh()
    {
        TextureAvailable = false; 
        NormalsAvailable = false;
        ColorsAvailable = false;
        ModelMatrixAvailable=false;
        TextureVerticesAvailable=false;
        MaterialAvailable=false;
    }
        
    void setTexture(double *TIin, int *TIin_dimst)
    {
        // Make Texture Image
        TIin_dims[0]=TIin_dimst[0]; 
        TIin_dims[1]=TIin_dimst[1]; 
        TIin_dims[2]=TIin_dimst[2];
        T=new Texture(TIin, TIin_dims[0], TIin_dims[1] , TIin_dims[2]);
        TextureAvailable = true;
    }

    void setVerticesFaces(double *Fint, int *Fin_dimst, double *Vint, int *Vin_dimst)
    {
        Fin=Fint;
        Fin_dims[0]=Fin_dimst[0];
        Fin_dims[1]=Fin_dimst[1];
        Vin=Vint; 
        Vin_dims[0]=Vin_dimst[0];
        Vin_dims[1]=Vin_dimst[1];
    }
    void setNormals(double *Nint, int *Nin_dimst)
    {
        Nin=Nint; 
        Nin_dims[0]=Nin_dimst[0];
        Nin_dims[1]=Nin_dimst[1];
        NormalsAvailable = true;
    }
    
    void setColors(double *Cint, int *Cin_dimst)
    {
        Cin=Cint;
        Cin_dims[0]=Cin_dimst[0];
        Cin_dims[1]=Cin_dimst[1];
        ColorsAvailable = true;
    }

    void setTextureVertices(double *TVint, int *TVin_dimst)
    {
        TVin=TVint;
        TVin_dims[0]=TVin_dimst[0];
        TVin_dims[1]=TVin_dimst[1];
        TextureVerticesAvailable = true;
    }
    
    void setModelMatrix(double *MVint, int *MVin_dimst)
    {
        MVin=MVint; 
        MVin_dims[0]=MVin_dimst[0];
        MVin_dims[1]=MVin_dimst[1];
        ModelMatrixAvailable=true;
    }
    
    void setMaterial(double *Mint, int *Min_dimst)
    {
        Min=Mint;
        Min_dims[0]=Min_dimst[0];
        Min_dims[1]=Min_dimst[1];
        MaterialAvailable=true;
    }
    
    void drawMesh(Scene *S)
    {
        // Enable texture in scene
        if(TextureAvailable)
        {
            S[0].T=T[0];
        }
        else
        {
            S[0].enabletexture=false;
        }

        // Set Model Matrix
        if(ModelMatrixAvailable)
        {
            S[0].TT.setModelViewMatrix(MVin); 
        }
                
        // Combine the projection matrix with model matrix
        S[0].TT.makeInverseMatrices();

        Vout=S[0].TT.TransformVertices(Vin, Vin_dims[0]);

        // Transform the normals
        if(NormalsAvailable) 
        { 
            Nout=S[0].TT.TransformNormals(Nin, Nin_dims[0]);
        }

        
        if( TextureVerticesAvailable) {
            TVout=S[0].TT.TransformTextureVertices(TVin, TVin_dims[0], TIin_dims[0], TIin_dims[1]);
        }

        if(MaterialAvailable) 
        { 
            S[0].Q.setMaterial(Min); 
        }
      
        Face F;
        Vertice a, b, c;

    
        // Loop through all faces (and render them)
        for(int i=0; i<Fin_dims[0]; i++) {
            int F1a=(int)Fin[i+0]-1;
            int F2a=(int)Fin[i+1*Fin_dims[0]]-1;
            int F3a=(int)Fin[i+2*Fin_dims[0]]-1;
            int F1b=F1a+Vin_dims[0];
            int F2b=F2a+Vin_dims[0];
            int F3b=F3a+Vin_dims[0];
            int F1c=F1b+Vin_dims[0];
            int F2c=F2b+Vin_dims[0];
            int F3c=F3b+Vin_dims[0];
            int F1d=F1c+Vin_dims[0];
            int F2d=F2c+Vin_dims[0];
            int F3d=F3c+Vin_dims[0];

            // Store the vertex coordinates in the vertices
            a.setP(Vout[F1a], Vout[F1b], Vout[F1c]);
            b.setP(Vout[F2a], Vout[F2b], Vout[F2c]);
            c.setP(Vout[F3a], Vout[F3b], Vout[F3c]);
            if(S[0].culling!=0)
            {
                // Put the vertices in the face object
                F.set(a, b, c);
                if(F.frontfacing) {
                    if(S[0].culling<0) { continue; }
                }
                else {
                    if(S[0].culling>0) { continue; }
                }
            } 

            if(ColorsAvailable) {
                if(Cin_dims[0]==1) {
                    // One color mesh, flat face coloring
                    if(Cin_dims[1]==3) {
                        a.setC(Cin[0], Cin[1], Cin[2]);
                        b.setC(Cin[0], Cin[1], Cin[2]);
                        c.setC(Cin[0], Cin[1], Cin[2]);
                    }
                    else {
                        a.setC(Cin[0], Cin[1], Cin[2], Cin[3]);
                        b.setC(Cin[0], Cin[1], Cin[2], Cin[3]);
                        c.setC(Cin[0], Cin[1], Cin[2], Cin[3]);
                    }
                }
                else {
                    // Color defined on each vertex
                    if(Cin_dims[1]==3) {
                        a.setC(Cin[F1a], Cin[F1b], Cin[F1c]);
                        b.setC(Cin[F2a], Cin[F2b], Cin[F2c]);
                        c.setC(Cin[F3a], Cin[F3b], Cin[F3c]);
                    }
                    else {
                        a.setC(Cin[F1a], Cin[F1b], Cin[F1c], Cin[F1d]);
                        b.setC(Cin[F2a], Cin[F2b], Cin[F2c], Cin[F2d]);
                        c.setC(Cin[F3a], Cin[F3b], Cin[F3c], Cin[F3d]);
                    }
                }
            }
            else {
                // No color set
                a.setC(0, 0, 1);
                b.setC(0, 1, 0);
                c.setC(1, 0, 0);
            }

            // If normals available store them in the vertices
            if(NormalsAvailable) {
                a.setN(Nout[F1a], Nout[F1b], Nout[F1c]);
                b.setN(Nout[F2a], Nout[F2b], Nout[F2c]);
                c.setN(Nout[F3a], Nout[F3b], Nout[F3c]);
            }
            
            // In case of texture store the coordinates in the vertices
            // and image in Face
            if(TextureVerticesAvailable) {
                a.setT(TVout[F1a], TVout[F1b]);
                b.setT(TVout[F2a], TVout[F2b]);
                c.setT(TVout[F3a], TVout[F3b]);
            }

            // Put the vertices in the face object
            F.set(a, b, c);
            // Draw ( Rasterize ) the face
            F.drawFace(S);
        }
        delete Vout;
        if(NormalsAvailable) { delete Nout; }
        if(TextureAvailable) { delete[] T; }
        
    }
};
