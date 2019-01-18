function [imgSlice,x,y,z]=dtiGetSliceUint8(std2img, imgVol, sliceThisDim, sliceNum, imDims, interpType, mmPerVox)
%
% [imgSlice,x,y,z]=dtiGetSlice(std2img, imgVol, sliceThisDim, sliceNum, [imDims], [interpType='l'], mmPerVox=[1 1 1])
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
%
% Example:
%   imgVol = dtiGet(handles,'currentanatomydata');
%   std2img = inv(dtiGet(handles,'standardXform'));
%   curPos = dtiGet(handles,'curpos'); 
%   sliceThisDim = 1; sliceNum =curPos(sliceThisDim);
%   [imgSlice,x,y,z]=dtiGetSliceUint8(std2img, imgVol, sliceThisDim, sliceNum);
%
% HISTORY:
%   2007.05.18 RFD (bob@white.stanford.edu) wrote it.
% 

% if(~
if(~exist('sliceNum','var')||isempty(sliceNum)), sliceNum = dtiGet(handles,'currentSliceNum',sliceThisDim); end
if(~exist('imDims','var') || isempty(imDims))
    % This should work well if the standard space is really Talairach. 
    % Otherwise, you may need to specify.
    imDims = dtiGet(1, 'defaultBoundingBox');
elseif(imDims == 0)
    imDims = mrAnatXformCoords(inv(std2img),[1,1,1; ...
            size(imgVol,2),size(imgVol,1),size(imgVol,3); ...
            1,size(imgVol,1),size(imgVol,3); ...
            size(imgVol,2),1,size(imgVol,3); ...
            size(imgVol,2),size(imgVol,1),1]);
    imDims = [min(imDims);max(imDims)];
end
if(~exist('interpType','var')||isempty(interpType)) interpType = 'n'; end
if(~exist('mmPerVox','var')) mmPerVox = [1 1 1]; end

nVols = size(imgVol,4);
tic;
if(sliceThisDim==1) x = sliceNum;
else x = [imDims(1,1):mmPerVox(1):imDims(2,1)]; end;
if(sliceThisDim==2) y = sliceNum;
else y = [imDims(1,2):mmPerVox(2):imDims(2,2)]; end;
if(sliceThisDim==3) z = sliceNum;
else z = [imDims(1,3):mmPerVox(3):imDims(2,3)]; end;

[x,y,z] = meshgrid(x,y,z);
x = squeeze(x);
y = squeeze(y);
z = squeeze(z);

imgCoords = mrAnatXformCoords(std2img, [x(:),y(:),z(:)],false);
toc;
sz = size(imgVol);
for(ii=1:nVols)
    if(interpType=='n')
        tmp = mrAnatFastInterp3(imgVol(:,:,:,ii), round(imgCoords));
    else
        tmp = mrAnatFastInterp3(imgVol(:,:,:,ii), imgCoords);
    end
    imgSlice(:,:,ii) = squeeze(reshape(tmp,size(z)));
end

% Debug
% figure; imagesc(imgSlice); colormap(gray); axis image
return;


