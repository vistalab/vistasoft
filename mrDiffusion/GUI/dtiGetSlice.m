function [imgSlice,x,y,z]=dtiGetSlice(img2std, imgVol, sliceThisDim, sliceNum, imDims, interpType, mmPerVox, dispRange)
%
% [imgSlice,x,y,z]=dtiGetSlice(img2std, imgVol, sliceThisDim, sliceNum, [imDims], [interpType='l'], [mmPerVox=[1 1 1]], [dispRange=[0 1 1]])
%
%     sliceThisDim: X=1, Y=2, Z=3
%
% We use a standard convention- x,y,z always mean the same thing- 
%   x is anatomical left-right, 
%   y is anatomical anterior-posterior and 
%   z is anatomical inferior-superior.
%
% If imDims is empty, then a reasonable Talairach-space bounding box is
% used. If imDims==0, then a bounding box that includes the entire image is
% used.
%
% interpType can be:
%   'n' for nearest-neighbor
%   'l' for trilinear
%   'c' for cubic
%   's' for spline
%
% Example:
%   imgVol = dtiGet(handles,'currentanatomydata');
%   img2std = dtiGet(handles,'standardXform');
%   curPos = dtiGet(handles,'curpos'); 
%   sliceThisDim = 1; sliceNum =curPos(sliceThisDim);
%   [imgSlice,x,y,z]=dtiGetSlice(img2std, imgVol, sliceThisDim, sliceNum);
%
% HISTORY:
%   2003.07.09 RFD (bob@white.stanford.edu) wrote it.
%   2006.11.08 RFD: added options for interpolation methods besides trilinear.
% 


% Programming Notes:
%    We could probably modify this routine to get non-cardinal slices
%    The slice numbering seems complicated to me.  imDims is used, sliceNum
%    is really current position.  Maybe we could clarify? (BW)
if(~exist('imDims','var') || isempty(imDims))
    % This should work well if the standard space is really Talairach. 
    % Otherwise, you may need to specify.
    imDims = dtiGet(1, 'defaultBoundingBox');
elseif(imDims == 0)
    imDims = img2std*[1,1,1,1; ...
            size(imgVol,2),size(imgVol,1),size(imgVol,3),1; ...
            1,size(imgVol,1),size(imgVol,3),1; ...
            size(imgVol,2),1,size(imgVol,3),1; ...
            size(imgVol,2),size(imgVol,1),1,1 ]';
    imDims = imDims(1:3,:)';
    imDims = [min(imDims);max(imDims)];
end

if(~exist('interpType','var')||isempty(interpType)), interpType = 'n'; end
if(~exist('mmPerVox','var')||isempty(mmPerVox)), mmPerVox = [1 1 1]; end
if(~exist('dispRange','var')||isempty(dispRange)), dispRange = [0 1 1]; end

% myCinterp3 uses [rows,columns,slices], so we need a permute here
imgVol = double(permute(imgVol,[2,1,3,4]));
sz = [size(imgVol) 1];
nVols = sz(4);
xform = inv(img2std);

if(sliceThisDim==1), x = sliceNum;
else x = (imDims(1,1):mmPerVox(1):imDims(2,1)); 
end;
if(sliceThisDim==2), y = sliceNum;
else y = (imDims(1,2):mmPerVox(2):imDims(2,2)); 
end;
if(sliceThisDim==3), z = sliceNum;
else z = (imDims(1,3):mmPerVox(3):imDims(2,3)); 
end;

% Make the xyz coordinates in the abstract anatomical data.
[x,y,z] = meshgrid(x,y,z);
x = squeeze(x);
y = squeeze(y);
z = squeeze(z);

% Transform the xyz coordinates into the actual data???
imgCoords = mrAnatXformCoords(xform, [x(:),y(:),z(:)]);
outSz = size(z);
imgSlice = zeros([outSz(1) outSz(2) nVols]);
for(ii=1:nVols)
    if(interpType=='n')
        %imgSlice = interp3(imgVol,imgCoords(:,1),imgCoords(:,2),imgCoords(:,3),interpType);
        tmp = myCinterp3(imgVol(:,:,:,ii),[sz(1) sz(2)], sz(3), round(imgCoords), 0.0);
    elseif(interpType=='l')
        tmp = myCinterp3(imgVol(:,:,:,ii),[sz(1) sz(2)], sz(3), imgCoords, 0.0);
    else
        tmp = interp3(imgVol(:,:,:,ii),imgCoords(:,1),imgCoords(:,2),imgCoords(:,3),interpType);
    end
    imgSlice(:,:,ii) = squeeze(reshape(tmp,outSz));
end

% Clipping and gamma on the brightness when dispRange isn't between 0 and 1
% with a unit gamma (power exponent)
if(~all(dispRange==[0 1 1]))
    if(dispRange(2)~=1)
        imgSlice(imgSlice>dispRange(2)) = dispRange(2);
    end
    if(dispRange(1)~=0)
        imgSlice(imgSlice<dispRange(1)) = dispRange(1);
    end
    
    % Normalizes to display range.
    imgSlice = imgSlice - dispRange(1);
    imgSlice = imgSlice ./ (dispRange(2)-dispRange(1));
    
    % Raise to exponent
    if(dispRange(3)~=1)
        imgSlice = imgSlice.^dispRange(3);
    end
end

% Debug
% figure; imagesc(imgSlice); colormap(gray); axis image
return;


