function img = atlasMapRgn2FullImage(img,imgRegion,X,Y,fillvalue)
%
%   img = atlasMapRgn2FullImage(img,imgRegion,X,Y,[fillvalue = -1])
%
% Author: Wandell
% Purpose:
%    We use atlasCreate (via CP2TFORM and IMTRANFORM) to transform the standard
%    atlas into the coordinate frame of the data. This produces a set of
%    standard atlas values that fall within an imgRegion inside the full
%    image of the data (img). The coordinates of imgRegion are at the
%    locations between X(1):X(2) and Y(1):Y(2) in the destination image,
%    img.  Because of the limitations on the affine transformations,
%    sometimes the data in imgRegion are   invalid,  having a fill value
%    (default of -1).  This routine copies the valid data in imgRegion into
%    the full image.
%
% Examples:
%    atlasE = atlasMapRgn2FullImage(atlasE,atlasET,X,Y);
%

if ~exist('fillvalue','var') , fillvalue = -1; end

xCoords = round(X(1):X(2));
yCoords = round(Y(1):Y(2));
for ii=1:length(xCoords)
    for jj=1:length(yCoords)
        if imgRegion(jj,ii) ~= fillvalue
            img(yCoords(jj),xCoords(ii)) = imgRegion(jj,ii);
        end
    end
end

return;
