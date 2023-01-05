function imOut = warpUV(imIn, u, v, x, y, interpolationMethod, template)
%
% function imOut = vWarpUV(imIn, u, v, x, y, interpolationMethod, template)
%
% DESCRIPTION
%   This function warps an input image according to the displacement 
%     fields for all pixels (u and v) by using the MATLAB function interp2. 
%     The interpolation method, e.g., bilinear interpolation or 
%     nearest-neighbor interpolation, can be specified. Since this 
%     function is called often, e.g., many times during the
%     registration process, the function tries to use stored
%     (persistent) matrices that are needed as arguments for 
%     interp2 instead of recreating the matrices. 
%
% INPUT   
%   - imIn = image that is to be warped
%   - u = pixel displacement field in x direction
%   - v = pixel displacement field in y direction
%   - x is optional; can be given to the function to improve speed
%   - y is optional; can be given to the function to improve speed
%   - interpolationMetho is optional; 'nearest' is the default
%     'nearest':  edges better because of NaNs outside
%     'linear':   smoother inside
%   - template (optional): NaN regions in this image will be NaN in the 
%     warped image as well; this can be the original phWedgeIm 
%
% OUTPUT / RESULTS 
%   - imOut = warped image
%
% AUTHOR:
%   Volker Maximillian Koch
%   vk@volker-koch.de%
% DATE:
%   January - June 2001
%
% COMMENTS:
%   This function tries to avoid the calculation of x and y with meshgrid
%   since that takes some time. Therefore, these variables are stored
%   persistent.
%
% TO-DO:
%
% Update History:%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
persistent xStored; 
persistent yStored;
persistent sizeStored;
if ~exist('x','var'),  x=[]; end
if ~exist('y','var'),  y=[]; end
if (isempty(x) | isempty(y))
    if isempty(sizeStored)
        sizeStored = [0 0];
    end
    if sizeStored == size(imIn)
        x = xStored;
        y = yStored;    else        [x,y] = meshgrid(1:size(imIn,2),1:size(imIn,1));    endendxStored = x;yStored = y;sizeStored = size(imIn);
if eval('isempty(interpolationMethod)' , '1')    interpolationMethod = '*linear';end
imOut = zeros(size(imIn));% we could use Bernd's version of interp2 (updateTinC). %imOut = updateTinC(imIn, x+u, y+v);imOut = interp2(imIn, x+u, y+v, interpolationMethod);
if eval('~isempty(template)' , '0')    imOut(isnan(template)) = NaN;    end
return
