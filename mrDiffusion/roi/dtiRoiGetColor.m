function roiColorRgba = dtiRoiGetColor(roi,alpha)
%
%  roiColorRgba = dtiRoiGetColor(roi,[defaultAlpha=0.75])
%
% If the roi does not specify an alpha channel (opacity), then defaultAlpha
% is appended to the rgb triplet.
%
% HISTORY:
% 2006.08.18 RFD: extracted from dtiSaveImageSlicesOverlay.
% 2006.11.06 RFD: added csome comments about alpha.

% Default transparency (alpha) channel
if ~exist('alpha','var'), alpha = 0.75; end

if(isnumeric(roi.color))
  roiColorRgba = roi.color(:)';
  if(length(roiColorRgba)==3) roiColorRgba(4) = alpha;
  elseif(length(roiColorRgba)~=4) error('ROI color must be 1x3 or 1x4!'); end
else
  switch(roi.color)
   case 'r'
    roiColorRgba = [1 0 0 alpha];
   case 'g'
    roiColorRgba = [0 1 0 alpha];
   case 'b'
    roiColorRgba = [0 0 1 alpha];
   case 'm'
    roiColorRgba = [1 0 1 alpha];
   case 'w'
    roiColorRgba = [1 1 1 alpha];
   case 'y'
    roiColorRgba = [1 1 0 alpha];
   case 'c'
    roiColorRgba = [0 1 1 alpha];
   case 'k'
    roiColorRgba = [0 0 0 alpha];
   otherwise
    error('Unknown ROI color');
  end
end

return;
