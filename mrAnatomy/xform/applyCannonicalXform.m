function [img, mmPerVoxNew, dimOrder, dimFlip] = applyCannonicalXform(img, img2std, mmPerVox, insertMarkerFlag)
% Applies the cannonical xform specified in img2std to img
%
%  [img, mmPerVoxNew, dimOrder, dimFlip] = ...
%   applyCannonicalXform(img, img2std, mmPerVox, insertMarkerFlag)
%
% Applies the cannonical xform specified in img2std. NOTE! This function
% does not do a full affine transform- it assumes that the transform
% specified is a set of simple rotations and flips.
%
% When used with computeCannonicalXformFromIfile, img is reoriented to a
% standard axial orientation. That is, the image will be reoriented so that
% left-right is along the x-axis, anterior-posterior is along the y-axis,
% superior-inferior is along the z-axis, and the leftmost, anterior-most,
% superior-most point is at 0,0,0 (which, for Analyze, is the lower
% left-hand corner of the last slice).
%
% To help you find the 0,0,0 point, a 4-pixel rectange is drawn there with a pixel
% value equal to the maximum image intensity. Set insertMarkerFlag to
% false to disbale this. Also, if ndims(img)>3, this is automatically
% diabled.
%
% To adjust an img-to-standard space xofrm, use:
%
%    newXform = inv(canXform*inv(imToScanXform));
%
% SEE ALSO: computeCannonicalXformFromIfile
%
% HISTORY:
%   2003.06.19 RFD (bob@white.stanford.edu): wrote it.
%%

if(nargin<2)
    help(mfilename);
    return;
end
if(~exist('insertMarkerFlag','var')||isempty(insertMarkerFlag))
    insertMarkerFlag = true;
end

% Extract rotation & scale matrix. We have set things up so that the scales
% should be 1.
img2stdRot = round(img2std(1:3,1:3));

% Note that we have constructed this transform matrix so that it will only
% involve cannonical rotations. We did this by specifying corresponding
% points from cannonical locations (the corners of the volume- see
% stdCoords and volCoords).

% We use shortcuts to apply the transform. Since all rotations are
% cannonical, we can achieve them efficiently by swapping dimensions with
% 'permute'. The dimension permutation logic- we want to know which of the
% current dimensions should be x, which should be y, and which should be z:
xdim = find(abs(img2stdRot(1,:))==1);
ydim = find(abs(img2stdRot(2,:))==1);
zdim = find(abs(img2stdRot(3,:))==1);
dimOrder = [xdim, ydim, zdim];
dimFlip = [0 0 0];
if exist('mmPerVox','var')
    mmPerVoxNew = [mmPerVox(xdim), mmPerVox(ydim), mmPerVox(zdim)];
else
    mmPerVoxNew = [];
end

% Allow >3 dims- just leave the extra dims alone.
img = permute(img, [dimOrder, 4, 5]);

% Now do any necessary mirror flips (indicated by negative rotation matrix values).
if img2stdRot(1,xdim)<0
    dimFlip(xdim) = 1;
    % flip each slice ud (ie. along matlab's first dimension- our x-axis)
    %for(jj=1:size(img,3)) img(:,:,jj) = flipud(squeeze(img(:,:,jj))); end
    img = flipdim(img, 1);
end
if img2stdRot(2,ydim)<0
    dimFlip(ydim) = 1;
    % flip each slice lr (ie. along matlab's second dimension- our y-axis)
    %for(jj=1:size(img,3)) img(:,:,jj) = fliplr(squeeze(img(:,:,jj))); end
    img = flipdim(img, 2);
end   
if img2stdRot(3,zdim)<0
    dimFlip(zdim) = 1;
    % reorder slices (ie. flip along the 3rd dim)
    %for(jj=1:size(img,1)) img(jj,:,:) = fliplr(squeeze(img(jj,:,:))); end
    img = flipdim(img, 3);
end

if insertMarkerFlag&&ndims(img)==3
    % insert a marker at 1,end,end (should be left, anterior, superior 
    % given stdCoords of [0,0,0; 0,-1,0; 0,0,-1; -1,0,0])
    img(1,end,end) = max(img(:));
    img(2,end,end) = img(end,1,end);
    img(1,end-1,end) = img(end,1,end);
    img(2,end-1,end) = img(end,1,end);
end

return;

%%