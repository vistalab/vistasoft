function newImg = dtiResliceVolume(img, xform, boundingBox, mmPerVoxOut)
%
% newImg = dtiResliceVolume(img, xform, boundingBox, mmPerVoxOut)
%
% HISTORY:
%   2004.01.13 RFD (bob@white.stanford.edu) wrote it.

if(~exist('mmPerVoxOut') | isempty(mmPerVoxOut))
    mmPerVoxOut = [1 1 1];
end

if(~exist('boundingBox') | isempty(boundingBox))
    % create a default bounding box for the resliced data.
    % The following is the spm default bounding box. Note that the box is
    % defined in Talairach space (units = mm).
    boundingBox = [-78 -120 -60;
                    78  80   85];
end

% myCinterp3 likes [rows,columns,slices], so we need a permute here
img = double(permute(img,[2,1,3]));

x = (boundingBox(1,1):mmPerVoxOut(1):boundingBox(2,1));
y = (boundingBox(1,2):mmPerVoxOut(2):boundingBox(2,2));
z = (boundingBox(1,3):mmPerVoxOut(3):boundingBox(2,3));
[X,Y,Z] = meshgrid(x, y, z);
newSize = size(X);
clear x y z;
talCoords = [X(:) Y(:) Z(:)];
newSize = size(X);
clear X Y Z;

imgCoords = mrAnatXformCoords(xform, talCoords);
newImg = myCinterp3(img, [size(img,1) size(img,2)], size(img,3), imgCoords, 0.0);
newImg = squeeze(reshape(newImg,newSize));
return;
