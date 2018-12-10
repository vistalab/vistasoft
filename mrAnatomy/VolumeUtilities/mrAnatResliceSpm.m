function [newImg,xform,deformField] = mrAnatResliceSpm(img, xform, bb, ...
    mmPerVox, bSplineParams, showProgress)
% Use SPM spline-based interpolation to reslice a volume image to a specific 
% resolution in mm.
%
% Also crops the image to be constrained inside a specific bounding box (bb) 
% also specified in mm.
%
%  [newImg, xform, deformField] = mrAnatResliceSpm(img, xform,   ...
%                                 [boundingBox], [mmPerVox],     ...
%                                 [bSplineParams=[7 7 7 0 0 0]], ...
%                                 [showProgress=1])
%
% INPUTS:
%           xform - 4x4 affine transform to apply to input image 
%                   This xform should take the image from image space to mm.
%     boundingBox - New bounding box specified in mm.
%                   Defaults to a box the same size as the input image.
%        mmPerVox - Output voxel size in mm. Defaults to [1 1 1], 1 cubic mm.
%   bSplineParams - Parameters for the spm function that does the image resampling.
%                   (see spm_bsplins). Defaults to  [7 7 7 0 0 0], a 7th oder spline. 
%                   For trilinear interpolation use [1 1 1 0 0 0].
%    showProgress - Logical, (1,0). If set to 1 shows a wait bar with the
%                   progress of the process.
%
% OUTPUTS:
%          newImg - The final image resampled at the wanted resolution nd
%                   contained inside the requested bounding box.
%           xform - This is the xform that takes the newImg from mm
%                   space to image space.
%     deformField - The deformation applied to the image. Need better
%                   comment.
% 
% EXAMPLE:
%
%   We like the translation to roughly center the image, so be sure to set 
%   the transform matrix appropriately. For example,
%
%     origin = (size(img)+1)/2;
%     xform = inv([diag(1./mmPerVox), origin'; [0 0 0 1]]);
% 
%   This will ensure that you rotate about the center of the image. Note
%   that it's easiest to assemble the reverse transform (image space to mm
%   space) and then invert it to get the centered mm space to image space
%   that we want. Basically, what we want is an xform such that
%
%     inv(xform)*[0 0 0 1]'
%
%   gives you the desired origin (image center, in our case).
%
%   The bounding box (bb) defines the new image size, in the new (mm space) 
%   coordinate frame. If you use an xform matrix that centers each image (as above), 
%   then you can create your bounding box such that it will preserve the input 
%   image dimensions. Eg:
%
%   define bounding box in image space
%     bb = [-size(img)/2; size(img)/2-1]
%   
%   now convert to mm space
%     bb = V.mat*[bb,[0;0]]';
%     bb = bb(1:3,:)';
%
%   (note- you need -1 in there somewhere to make it work exactly, but I'm
%   not sure which side you should put it on to avoid a 1/2 voxel shift.)
%
%   The call to mrAnatResliceSpm will be something like:
%
%   img2 = mrAnatResliceSpm(img, inv(V.mat), bb, mmPerVox);
%
%   Or, if you wanted to reslice to 1mm isotropic voxels with trilinear
%   interp:
%
%   img2 = mrAnatResliceSpm(img, inv(V.mat), bb, [1 1 1], [1 1 1 0 0 0]);
% 
% (Stanford Vista Team 2012

% HISTORY:
% 2004.11.10 RFD: wrote it, after gaining some understanding of the spm
% conventions.
% 2005.08.09 RFD: fixed error in calculation of new xform. It was totally
% wrong for cases where mmPerVox ~= [1 1 1].
% 2006.07.19 RFD: NOW the newXform is correct for mmPerVox ~= 1. 
% 2007.10.30 RFD: Finally- newXform for mmPerVox ~= 1 is consistent with SPM.

%% Establish parameters
if(~exist('mmPerVox','var') || isempty(mmPerVox))
    mmPerVox = [1 1 1];
end
if(~exist('bb','var') || isempty(bb))
    if(isstruct(xform)), error('Must supply a bounding box with non-affine xforms.'); end
    sz = size(img);
    % Get a bounding box in ac-pc space that captures the whole image.
    %img2acpc = inv(xform);
    %inMmPerVox = sqrt(sum(img2acpc(1:3,1:3).^2));
    %if det(xform(1:3,1:3))<0, inMmPerVox(1) = -inMmPerVox(1); end;
    %inOrigin  = img2acpc\[0 0 0 1]'; inOrigin  = inOrigin(1:3)';
    %bb = [-inMmPerVox.*(inOrigin-1); inMmPerVox.*(sz(1:3)-inOrigin)];
    %bb = [-mmPerVox.*(inOrigin-1); mmPerVox.*(size(img)-inOrigin)];
    bb = sort(mrAnatXformCoords(inv(xform),[1 1 1; sz(1:3)]));
end

if(~exist('bSplineParams','var') || isempty(bSplineParams))
    bSplineParams = [7 7 7 0 0 0];
elseif(numel(bSplineParams)==1)
    bSplineParams = [bSplineParams bSplineParams bSplineParams 0 0 0];
end

if(~exist('showProgress','var') || isempty(showProgress))
    showProgress = 0;
end
    
% If the value in the parameter is 1, we call trilinear.  Otherwise we call
% the b-spline method.
if(bSplineParams(1) == 1), interpMethod = 'trilinear'; 
else interpMethod = ['b-spline (order ' num2str(bSplineParams(1)) ')']; 
end


% Make sure step size is consistent with bounding box values
for ii=1:3
    if bb(2,ii) < bb(1,ii), mmPerVox(ii) = -1*mmPerVox(ii); end
end

% x,y,z coordinates in the output image space
x   = (bb(1,1):mmPerVox(1):bb(2,1));
y   = (bb(1,2):mmPerVox(2):bb(2,2));
z   = (bb(1,3):abs(mmPerVox(3)):bb(2,3));

newSz = [size(x,2) size(y,2) size(z,2)];
newImg = zeros([newSz size(img,4)]);
if(nargout>2), deformField = zeros([newSz,3]); end
if(showProgress), h = mrvWaitbar(0,['Resampling with ' interpMethod ' interpolation...']); end
totalNumSlices = length(z)*size(img,4);

for fourthDim=1:size(img,4)
    if(showProgress), mrvWaitbar(0.005,h); end
    bsplineCoefs = spm_bsplinc(img(:,:,:,fourthDim), bSplineParams);
    if(showProgress), mrvWaitbar(0.1,h); end
    curSliceTotal = (fourthDim-1)*length(z);
    for ii=1:length(z)
        [X,Y,Z] = ndgrid(x, y, z(ii));
        [sampleCoords,outMat] = mrAnatXformCoords(xform, [X(:) Y(:) Z(:)]);
        
        % Resampling the coordinates using the bspline method
        tmp = spm_bsplins(bsplineCoefs, ...
            sampleCoords(:,1), sampleCoords(:,2), sampleCoords(:,3), bSplineParams);
        tmp = reshape(tmp, newSz([1,2]));
        %figure; imagesc(tmp); axis image; colormap gray;
        
        newImg(:,:,ii,fourthDim) = tmp; %permute(tmp,[2,1]);
        
        if(showProgress), mrvWaitbar((curSliceTotal+ii)/totalNumSlices*0.9+0.1,h); end
        
        % Return the deformation field
        if(exist('deformField','var'))
            if(~isempty(outMat))
                % this is quite inefficient, but makes for cleaner code.
                % This "if(exist('deformField'..." conditional is rarely used anyway.
                sampleCoords = mrAnatXformCoords(inv(outMat), sampleCoords);
            end
            deformField(:,:,ii,1) = reshape(sampleCoords(:,1),size(X)) - X;
            deformField(:,:,ii,2) = reshape(sampleCoords(:,2),size(Y)) - Y;
            deformField(:,:,ii,3) = reshape(sampleCoords(:,3),size(Z)) - Z;
        end
    end
end

if(showProgress), close(h); end

% the new origin is the AC- 0,0,0 in MNI/Tal space. That will be 
newOrigin = bb(1,:) - mmPerVox;
xform = [diag(mmPerVox), newOrigin'; [0 0 0 1]];

return;
