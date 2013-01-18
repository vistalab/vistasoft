
function [gabor_even,gabor_odd]=gabor_filter_new(img,K,w0,theta,p,grid_size)

%--------------------------------------------------------------------------
% Computes even and odd Gabor filters for a given image dimension,K value, 
% radial frequency (w0), orientation (theta) and phase offset of 
% baseband complex sinusoid. K values are pre-computed for desired spatial 
% frequency bandwidth. eg. K=2.5 , when bandwidth = 1.5 octave. 
% 
%Reference : www.cnbc.cmu.edu/~tai/papers/pami.pdf
% 
%INPUTS:
%   IMG    - Image input      
%   K      - Constant ( depends on bandwidth )
%   W0     - Radial frequeny
%   THETA  - Filter Orientation
%   P      - Phase offset for complex sinusoid
%OUTPUT:
%   GABOR_EVEN - Even Gabor filter ( phase 0 ) for given image dimension
%   GABOR_ODD  - Odd Gabor filter ( phase 90 ) for given image dimension
%  Note: Function returns Quadrature phase pairs of orientation theta.
%--------------------------------------------------------------------------


if nargin < 5
   errordlg('Insufficient no. of arguments to function.')
end
if grid_size==[]
    grid_size=1;
end 

img_rows=size(img,1);
img_cols=size(img,2);
MN=img_rows*img_cols;                           %total no. of pixels in the image

a=floor(img_rows/grid_size);
b=floor(img_cols/grid_size);
a_mid=floor(a/2);
b_mid=floor(b/2);

for r=1:1:grid_size
    for s=1:1:grid_size
        x_0(r,s)=(r-1)*a + a_mid;
        y_0(r,s)=(s-1)*b + b_mid;
    end
end 
    

q=1;
for r=1:1:grid_size
    for s=1:1:grid_size

        x0=x_0(r,s);
        y0=y_0(r,s);

        img_vect=reshape(img',MN,1);                    % vectorizing the 2-D image rowwise                 
        [x,y]=meshgrid(1:1:img_rows,1:1:img_cols);      % vectorizing the pixel co-ordinates
        x_n=reshape(x,MN,1);
        y_n=reshape(y,MN,1);
        xy_vect=[x_n y_n];
        rot_theta = [cos(theta) -sin(theta); sin(theta) cos(theta)]; %rotation matrix


        x0y0= ones(MN,1)* [x0 y0];
        vect_xy=xy_vect-x0y0;                           % translated coordinates
        xy_vect=vect_xy*rot_theta;
        xy_vect2=xy_vect.^2;
        xy_vect2(:,1)=xy_vect2(:,1).*4;
        gauss_arg=((-w0^2)/(8*K^2)).*(xy_vect2(:,2)+xy_vect2(:,1));

        %*************************

        gauss = (w0/(K*sqrt(2*pi)))* exp(gauss_arg);   %computing the gaussian envelope of the modulated wave

        %computing the complex sinusoid
        sine_arg= w0*xy_vect(:,1)+ p*ones(MN,1);        % argument to the complex sine
        %complex_sine = exp(sine_arg.*j);
        complex_sine = exp(sine_arg.*j)-exp((-K^2)-1)*ones(MN,1);     % complex sinusoid with dc offset for zero mean correction

        gabor_wavelet=gauss.*complex_sine;
        gabor_wavelet=reshape(gabor_wavelet,img_cols,img_rows);
        gabor_wavelet=gabor_wavelet';                          
        gabor_even(:,:,q)=real(gabor_wavelet);
        gabor_odd(:,:,q)=imag(gabor_wavelet);
        
        q=q+1;
    end
end


%  surfl(gabor_even)
%  shading interp 
%  colormap copper
%  
% figure
% imshow(gabor_even(:,:,1),[])
% imshow(gabor_odd(:,:,1),[])






