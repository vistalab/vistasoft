class Texture {
private:
    double *I;
    int size[3];
public:
    Texture(){}
    Texture(double *It, int sizx, int sizy,int sizz) {
        I=It; size[0]=sizx; size[1]=sizy; size[2]=sizz;
    }
    int getsize(int i){ return size[i]; }
    
    double getcolor_mindex2(int x, int y, int sizx, int sizy, double *I, int rgb) {
        return I[rgb*sizy*sizx+y*sizx+x];
    }

    void getpixel(double Tlocalx, double Tlocaly, double *Ipixel) {
        // This function returns a linear interpolated RGB(A) pixel value
        // from the coordinate Tlocalx, Tlocaly
        
        /*  Linear interpolation variables */
        int xBas0, xBas1, yBas0, yBas1;
        double perc[4]={0, 0, 0, 0};
        double xCom, yCom, xComi, yComi;
        double color[4]={0, 0, 0, 0};

        /*  Rounded location  */
        double fTlocalx, fTlocaly;

        /* Determine the coordinates of the pixel(s) which will be come the current pixel */
        /* (using linear interpolation) */
        fTlocalx = floor(Tlocalx); fTlocaly = floor(Tlocaly);
        xBas0=(int) fTlocalx; yBas0=(int) fTlocaly;
        xBas1=xBas0+1; yBas1=yBas0+1;

        /* Linear interpolation constants (percentages) */
        xCom=Tlocalx-fTlocalx; yCom=Tlocaly-fTlocaly;
        xComi=(1-xCom); yComi=(1-yCom);
        perc[0]=xComi * yComi; perc[1]=xComi * yCom;
        perc[2]=xCom * yComi; perc[3]=xCom * yCom;

        // Clamp to edge, if coordinates outside
        if(xBas0<0) { xBas0=0; if(xBas1<0) { xBas1=0; }}
        if(yBas0<0) { yBas0=0; if(yBas1<0) { yBas1=0; }}
        if(xBas1>(size[0]-1)) { xBas1=size[0]-1; if(xBas0>(size[0]-1)) { xBas0=size[0]-1; }}
        if(yBas1>(size[1]-1)) { yBas1=size[1]-1; if(yBas0>(size[1]-1)) { yBas0=size[1]-1; }}

        // Combine the rgb values of all 4 neighbours
        Ipixel[3]=1;
        for (int c=0; c<size[2]; c++) {
            color[0]=getcolor_mindex2(xBas0, yBas0, size[0], size[1], I, c);
            color[1]=getcolor_mindex2(xBas0, yBas1, size[0], size[1], I, c);
            color[2]=getcolor_mindex2(xBas1, yBas0, size[0], size[1], I, c);
            color[3]=getcolor_mindex2(xBas1, yBas1, size[0], size[1], I, c);
            Ipixel[c]=color[0]*perc[0]+color[1]*perc[1]+color[2]*perc[2]+color[3]*perc[3];
        }
        
    }
};

