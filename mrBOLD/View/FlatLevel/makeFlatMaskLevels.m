function vw = makeFlatMaskLevels(vw,blurLevel,thresh)
%
% function view = makeFlatMaskLevels(view,blurLevel,thresh)
%
% Make mask, a binary matrix that determines what parts of the image to
% keep.  Mask out the parts of the image that are far from the
% initial sample points.
%
% djh, 7/99.  Wrote this so that the mask no longer needs to be recomputed
% each time you call myGriddata.
%
% djh, 8/4/99.  Round the coords because we no longer do it in
% loadGLocs (to get rid of the streaky artifacts).
%
% ras, 10/04. Version for flat level view (coords is not a cell anymore).

global mrSESSION;

if ~exist('blurLevel','var')
  blurLevel = 1;
end
if ~exist('thresh','var')
  thresh = .1;
end

mask=zeros(viewGet(vw,'Size'));
imSize = vw.ui.imSize;
for slice = 1:numSlices(vw)
    coords = vw.coords{slice};
    coords = round(coords);
    
    if isempty(coords)
        mask(:,:,slice) = NaN*ones(imSize);
    else
        y = coords(1,:);
        x = coords(2,:);
        % Remove NaN coords
        allFinite = find(finite(x) & finite(y));
        x = x(allFinite);
        y = y(allFinite);
        % Initialize to 0s
        maskIm = zeros(imSize);
        % Set to 1s at sample points
        for i=1:length(y)
            maskIm(y(i),x(i)) = 1;
        end
        % Blur and threshold
        maskIm = blur(maskIm,blurLevel);
        maskIm = maskIm > thresh;
        
        % Assign NaNs to pixels that are far from the sample points
        % maskIm as created above is a logical.  This routine dies when
        % you try to set a logical to a NaN.  So, we just left it as 0s.
        %         indices = find(maskIm==0);
        %         maskIm(indices) = NaN;
        mask(:,:,slice) = maskIm;
    end
end

% Set view.ui.mask field
vw.ui.mask = mask;

return


% 
% % Debug/text
% 
% FLAT{1} = makeFlatMask(FLAT{1});	% For debugging
% mask = FLAT{1}.ui.mask;
% indices = isnan(mask);
% mask(indices) = 0;
% showIm(mask(:,:,1));
% showIm(mask(:,:,2));
