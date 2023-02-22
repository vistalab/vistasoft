function [xTexture,yTexture,zTexture] = dtiTextureImage(xIm,yIm,zIm,transparency)
% Set alpha for non-brain to 0 so it's transparent (erode/dilate to smooth)      
% Not used right now, but it used to be.  Could be fixed up.

if ~isempty(xIm)
    mask = imblur(double(xIm>0.1),13)>0.1;
    mask = imfill(mask,'holes');
    mask = imerode(mask, strel('disk',3));
    mask = imdilate(mask, strel('disk',4));
    mask = bwareaopen(mask, 100);
    xTexture = double(mask)*transparency;
else
    xTexture = [];
end

if ~isempty(yIm)
    mask = imblur(double(yIm>0.1),13)>0.1;
    mask = imfill(mask,'holes');
    mask = imerode(mask, strel('disk',3));
    mask = imdilate(mask, strel('disk',4));
    mask = bwareaopen(mask, 100);
    yTexture = double(mask)*transparency;
else
    yTexture = [];
end

if ~isempty(zIm)
    mask = imblur(double(zIm>0.1),13)>0.1;
    mask = imfill(mask,'holes');
    mask = imerode(mask, strel('disk',3));
    mask = imdilate(mask, strel('disk',4));
    mask = bwareaopen(mask, 100);
    zTexture = double(mask)*transparency;    
else
    zTexture = [];
end
