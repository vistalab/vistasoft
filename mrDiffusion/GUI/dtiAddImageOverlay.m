function rgbImg = dtiAddImageOverlay(rgbImg, coords, colors, blurSize)
%
%   rgbImg = dtiAddImageOverlay(rgbImg, coords, colors, blurSize)
%
% Author: Dougherty
% Purpose:
%   Add an overlay (FGs or ROIs) to an inplane image
%
% HISTORY:
%  2004.08.25 RFD: wrote it.

if ieNotDefined('colors'), colors = [1 0 0 1]; end
if ieNotDefined('blurSize'), blurSize = 3; end

if(isempty(coords))
    return;
end

if(size(colors,2)==4) alpha = colors(:,4); 
else alpha = 1; end

sz = size(rgbImg);
overlayLocs = sub2ind(sz(1:2), coords(:,1), coords(:,2));

if blurSize > 0.5
    g = fspecial('gaussian',round(2*blurSize),max(blurSize,1)); 
    g = g/sum(g(:));
    mask = zeros(sz(1:2));
    mask(overlayLocs) = 1;
    mask = conv2(mask,g,'same');
    overlayLocs = find(mask(:)>0.5);
end

for(ii=1:3)
    tmp = rgbImg(:,:,ii);
    if(alpha<1)
        tmp(overlayLocs) = (1-alpha).*tmp(overlayLocs) + alpha.*colors(:,ii);
    else
        tmp(overlayLocs) = colors(:,ii);
    end
    rgbImg(:,:,ii) = tmp;
end
    

% rgbOverlay = zeros(size(rgbImg));
% for ii=1:3
%     tmp = rgbOverlay(:,:,ii);
%     tmp(overlayLocs) = colors(ii);
%     if blurSize > 0.5, tmp = conv2(tmp,g,'same'); end
%     rgbOverlay(:,:,ii) = tmp;
% end
% rgbOverlay = mrScale(rgbOverlay);
% figure; imshow(rgbOverlay)

% mask = sum(rgbOverlay,3);
% overlayLocs = find(mask > 0);

% for ii=1:3
%     overlayPlane = rgbOverlay(:,:,ii);
%     imgPlane = rgbImg(:,:,ii);
% 
%     imgPlane(overlayLocs) = overlayPlane(overlayLocs);
%     rgbImg(:,:,ii) = imgPlane;
% end


return;
    
