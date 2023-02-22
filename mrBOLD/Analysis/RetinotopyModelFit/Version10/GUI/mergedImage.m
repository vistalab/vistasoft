function rgb = mergedImage(img, overlay, cmap, maxGrayValue)
% transform the image into RGB and overlay it with an edge image
% img - the original image in gray values
% overlay - binary edge image or zero
% cmap - desired colormap
% maxGrayValue - used for scaling (for phase images 2*pi)
if isempty(overlay)
    overlay=1;
else
    overlay=1-overlay;
end
img = ceil(img*size(cmap,1)/maxGrayValue);
img(isnan(img)) = 1;
img(img<1) = 1;
img(img>size(cmap,1)) = size(cmap,1);
cmap(1,:)=[1 1 1];
rgb(:,:,1) = reshape(cmap(img,1),size(img));
rgb(:,:,2) = reshape(cmap(img,2),size(img));
rgb(:,:,3) = reshape(cmap(img,3),size(img));
% overlay
rgb(:,:,1) = rgb(:,:,1).*overlay;
rgb(:,:,2) = rgb(:,:,2).*overlay;
rgb(:,:,3) = rgb(:,:,3).*overlay;
return;
