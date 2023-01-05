function [images,imOrigin] = dtiSplitFourImages(handles,xIm,yIm,zIm)
%
%  [images,imOrigin1,imOrigin2,imOrigin3,imOrigin4] = ...
%            dtiSplitFourImages(handles,xIm,yIm,zIm,imOrigin)
%
% Splits each of the images xIm, yIm, and zIm into four images stored in
% the images structure. This is done so that transparency could be
% correctly computed in mrMesh. The center point where the images are cut
% is the current position in dtiFiberUI.
%
% Inputs:
%   - handles : current handles
%   - xIm : image on the x plane
%   - yIm : image on the y plane
%   - zIm : image on the z plane
%
% Output:
%   - images : structure containing the 12 images(xIm1,xIm2...)
%   - imOrigin1,2,3,4 : origins of the new images. It is in a format that
%     facilitates the call of dtiAddImages
%
% Written by : gb 10/24/2005 (Guillaume B.?)
%
% Stanford VISTA Team

% xform = dtiGet(handles,'curacpc2imgxform');
images = struct('xIm',[],'yIm',[],'zIm',[]);

imOrigin = cell(1,4);
imOrigin{1} = struct('x',[],'y',[],'z',[]);
imOrigin{2} = struct('x',[],'y',[],'z',[]);
imOrigin{3} = struct('x',[],'y',[],'z',[]);
imOrigin{4} = struct('x',[],'y',[],'z',[]);

sz = [size(zIm'); size(yIm); size(xIm')];
imSize = 2^ceil(log2(max(sz(:))));

imDims = dtiGet(1, 'defaultBoundingBox');
realCenter = dtiGet(handles, 'acpcpos');
center = floor(realCenter - imDims(1,:)) + 1;
center(center<1) = 1;
%center(center>
if ~isempty(xIm)
    images.xIm{1} = dtiImagePad(xIm(1:floor(center(2)),1:floor(center(3))),0,imSize);
    images.xIm{2} = dtiImagePad(xIm(1:floor(center(2)),floor(center(3)):end),1,imSize);
    images.xIm{3} = dtiImagePad(xIm(floor(center(2)):end,floor(center(3)):end),2,imSize);
    images.xIm{4} = dtiImagePad(xIm(floor(center(2)):end,1:floor(center(3))),3,imSize);

    xOffset = [0 size(images.xIm{1})]/2;
    imOrigin{1}.x = realCenter + [0 -xOffset(2) -xOffset(3)];
    imOrigin{2}.x = realCenter + [0 -xOffset(2) +xOffset(3)];
    imOrigin{3}.x = realCenter + [0 +xOffset(2) +xOffset(3)];
    imOrigin{4}.x = realCenter + [0 +xOffset(2) -xOffset(3)];   
end

if ~isempty(yIm)
    images.yIm{1} = dtiImagePad(yIm(1:floor(center(1)),1:floor(center(3))),0,imSize);
    images.yIm{2} = dtiImagePad(yIm(1:floor(center(1)),floor(center(3)):end),1,imSize);
    images.yIm{3} = dtiImagePad(yIm(floor(center(1)):end,floor(center(3)):end),2,imSize);
    images.yIm{4} = dtiImagePad(yIm(floor(center(1)):end,1:floor(center(3))),3,imSize);
     
    yOffset = [size(images.yIm{1},1) 0 size(images.yIm{1},2)]/2;
    imOrigin{1}.y = realCenter + [-yOffset(1) 0 -yOffset(3)];
    imOrigin{2}.y = realCenter + [-yOffset(1) 0 +yOffset(3)];
    imOrigin{3}.y = realCenter + [+yOffset(1) 0 +yOffset(3)];
    imOrigin{4}.y = realCenter + [+yOffset(1) 0 -yOffset(3)];
end

if ~isempty(zIm)
    images.zIm{1} = dtiImagePad(zIm(1:floor(center(2)),1:floor(center(1))),0,imSize);
    images.zIm{2} = dtiImagePad(zIm(1:floor(center(2)),floor(center(1)):end),1,imSize);
    images.zIm{3} = dtiImagePad(zIm(floor(center(2)):end,floor(center(1)):end),2,imSize);
    images.zIm{4} = dtiImagePad(zIm(floor(center(2)):end,1:floor(center(1))),3,imSize);
    
    zOffset = [size(images.zIm{1}) 0]/2;
    
    imOrigin{1}.z = realCenter + [-zOffset(1) -zOffset(2) 0];
    imOrigin{2}.z = realCenter - [-zOffset(1) +zOffset(2) 0];
    imOrigin{3}.z = realCenter + [+zOffset(1) +zOffset(2) 0];
    imOrigin{4}.z = realCenter - [+zOffset(1) -zOffset(2) 0];

end        
if(0)% isunix
    for(ii=1:4)
        if(~isempty(images.xIm)) 
            images.xIm{ii}(1,:)=0; images.xIm{ii}(end,:)=0; images.xIm{ii}(:,1)=0; images.xIm{ii}(:,end)=0;
        end
        if(~isempty(images.yIm)) 
            images.yIm{ii}(1,:)=0; images.yIm{ii}(end,:)=0; images.yIm{ii}(:,1)=0; images.yIm{ii}(:,end)=0;
        end
        if(~isempty(images.zIm)) 
            images.zIm{ii}(1,:)=0; images.zIm{ii}(end,:)=0; images.zIm{ii}(:,1)=0; images.zIm{ii}(:,end)=0;
        end
    end
end

return

% ---------------------------------------------------------------------- %
function [newImage] = dtiImagePad(image,nbCorner,imSize)
%
% function used to add a pad to the splitted images
%

sz = size(image);
newImage = zeros(imSize,imSize);

switch(nbCorner)
    case 0
        newImage(end - sz(1) + 1:end, end - sz(2) + 1:end) = image;
    case 1
        newImage(end - sz(1) + 1:end, 1:sz(2)) = image;
    case 2
        newImage(1:sz(1), 1:sz(2)) = image;
    case 3
        newImage(1:sz(1), end - sz(2) + 1:end) = image;
end

return