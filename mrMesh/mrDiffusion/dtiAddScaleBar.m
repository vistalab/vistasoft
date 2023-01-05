function image = dtiAddScaleBar(image)
% Add scale bar to an image
%
%   dtiAddScaleBar(image)
%
% I am guessing that the image is in 1mm samples?  This routine should be
% clarified and fixed up (BW).
%
% Stanford VISTA Team

% Position relative to image edge, I guess
sbOffset = 10;

% sb must mean scalebar itself.  Looks like it is set to 10 samples, not a
% known distance.  
sb = [[1:10] + sbOffset; repmat(sbOffset+5,1,10)];
sb = [sb, [sb(1,:); sb(2,:) + 1]];

% Add the scale bar, which is a plus sign 10 pixels long
sbInds = sub2ind(size(image), sb(1,:), sb(2,:));
image(sbInds) = 1;

sbInds = sub2ind(size(image), sb(2,:), sb(1,:));
image(sbInds) = 1;  

return