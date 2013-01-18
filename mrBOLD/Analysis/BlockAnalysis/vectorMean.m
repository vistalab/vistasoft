function [meanAmp,meanPh,seZ,meanStd] = vectorMean(view,scanNum,ROIcoords)
%
% [meanAmp,meanPh,seZ,meanStd] = vectorMean(view,scanNum,ROIcoords)
%
% Calculates mean amplitude and phase for pixels that are in
% ROIcoords.  
% The standard error (std(z)/sqrt(length(z))) can also
% returned.  This is the average distance of the complex values
% z = amp*exp(-i(ph)) from the mean of z.
%
% Can >also< return the mean noise std in the ROI:
% Computed from the coherence and the amplitude.
% 
% scanNum: scan number (integer)
% ROIcoords: 3xN array of (y,x,z) coords (e.g., corresponding to
%   the selected ROI).
%
% djh 4/23/98
% bw  2/17/99 Added seZ computation.
%
% Get co and ph (vectors) for the desired scan, within the
% current ROI.
%
subAmp = getCurDataROI(view,'amp',scanNum,ROIcoords);
subPh = getCurDataROI(view,'ph',scanNum,ROIcoords);
subCo = getCurDataROI(view,'co',scanNum,ROIcoords);

% Remove NaNs from subCo and subAmp that may be there if ROI
% includes volume voxels where there is no data.
NaNs = find(isnan(subPh));
if ~isempty(NaNs)
  disp('ROI includes voxels that have no data.  These voxels are being ignored.');
  notNaNs = find(~isnan(subPh));
  subPh = subPh(notNaNs);
  subAmp = subAmp(notNaNs);
  subCo= subCo(notNaNs);
  
end

% Compute the mean co right here...
meanCo=mean(subCo);

% convert to complex numbers
z = subAmp .* exp(sqrt(-1)*subPh);
if isempty(z)
   disp('Warning: no activity seen for current ROI');
   seZ = 0;
   meanAmp = 0;
   meanPh = 0;
else
	meanZ = mean(z);
    
    if nargout > 2
        seZ   = std(z)/sqrt(length(z));
    end
    meanAmp = abs(meanZ);
	meanPh = angle(meanZ);
end
% Compute the meanStd right here...
meanStd=meanAmp.*sqrt((1/mean(subCo).^2)-1);


return;

% Debug

coords = INPLANE{1}.ROIs(INPLANE{1}.selectedROI).coords;
scan = 1;
[meanAmp,meanPh] = vectorMean(INPLANE{1},scan,coords)
