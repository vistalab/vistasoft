function [h] = dtiComputeFiberDensity(h, fiberGroupNum, endptFlag, fgCountFlag)
%
%   [handles] = dtiComputeFiberDensity(handles, [fiberGroupNum=selectFGs], [endPointFlag=false], [fgCountFlag=false]) 
%
% Calculate how many fibers pass through each of the voxels.  Normalize
% this number to 1.  Return the values as a 3D image attached to the
% handles structure (image is called 'fiber density'). 
%
%
% RETURNS:
%  handles, with a new background image representing the fiber density.
%
% HISTORY:
% 2003.12.18 RFD (bob@white.stanford.edu) wrote it.
% 2006.06.09 RFD: removed fiber density normalization in here. This allows
% dtiAddBackground to do the normalization and save the original fiber
% counts so that we don't lose these values.

normalise = false; %TODO: expose normalization as an option

if(isempty(h.fiberGroups))
    error('No fiber groups.');
end
if(~exist('fiberGroupNum','var') ||isempty(fiberGroupNum))
    fiberGroupNum = dtiSelectFGs(h, 'Select fiber group(s) for density calculation');
end
if(any(fiberGroupNum>length(h.fiberGroups)))
    error('Invalid fiber group.');
end
if(~exist('endptFlag','var') || isempty(endptFlag))
    endptFlag = false;
end
if(~exist('fgCountFlag','var') || isempty(fgCountFlag))
    fgCountFlag = false;
end

bb = dtiGet(h,'boundingBox');
imSize = diff(bb)+1;
%imSize = size(h.dt6);imSize = imSize(1:3);

%gd = dtiGet(h, 'acpcGrid', h.vec.mat, h.vec.mmPerVoxel, size(h.vec.img(:,:,:,1)));
% We need to get the T1-space image coords from the current anatomy image.
%imgCoords = mrAnatXformCoords(inv(dtiGet(h,'acpcXform')), [gd.X(:) gd.Y(:) gd.Z(:)]);
%xform = inv(h.xformToAcpc);
% TO DO: this should be based on the actual fiber step size, rather than
% assuming that it's 1mm.
mmPerVoxel = [1 1 1];
ac = mrAnatXformCoords(h.xformToAcpc,[0 0 0]);
%xformImgToAcpc = h.xformToAcpc/diag([h.mmPerVoxel 1]);
xformImgToAcpc = diag([mmPerVoxel 1]);
xformImgToAcpc(1:3,4) = ac';

fdImg = dtiComputeFiberDensityNoGUI(h.fiberGroups, xformImgToAcpc, imSize, normalise, fiberGroupNum, endptFlag, fgCountFlag);

%uniqueFiberInds = unique(fiberInds);
% Calculate how many fibers are associated with each unique fiber index.
% HOW TO DO THIS WITHOUT A LOOP?
%for(ii=uniqueFiberInds')
%    fdImg(ii) = sum(fiberInds==ii);
%end
% USE  [a, b]=hist(uniqueFiberInds)

imName = 'fiber density';
[h,bgNum] = dtiAddBackgroundImage(h, fdImg, imName, mmPerVoxel, xformImgToAcpc);
h = dtiSet(h,'curOverlayNum',bgNum);
return;