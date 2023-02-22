function view = recomputeSSImage(view,numGrays,numColors,clipMode)
%
% function view = recomputeSSImage(view,numGrays,numColors,clipMode)
%
% rmk 09/17/98 based on recomputeImage

% Initialize images
anatIm=[];

% Get anatClip and overlayClip from sliders
anatClip = getAnatClip(view);

% Get anatomy image
anatIm = view.anat;

% Rescale anatIm to [1:numGrays], anatClip determines the range
% of anatomy values that gets mapped to the available grayscales.
% If anatClip=[0,1] then there is no clipping and the entire
% range anatomy values is scaled to the range of available gray
% scales.
minVal = min(anatIm(:));
maxVal = max(anatIm(:));
anatClipMin = min(anatClip)*(maxVal-minVal) + minVal;
anatClipMax = max(anatClip)*(maxVal-minVal) + minVal;
if (length(anatIm(:))~=0)
    anatIm=rescale2(anatIm,[anatClipMin,anatClipMax],[1,numGrays]);
end

% Replace NaNs
indices = find(isnan(anatIm));
anatIm(indices) = 1;

% Finally, set the view.ui.image field
view.ui.image = uint8(anatIm-1);


