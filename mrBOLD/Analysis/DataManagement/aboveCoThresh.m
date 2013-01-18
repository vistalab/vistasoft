function coords = aboveCoThresh(view,scanNum,ROIcoords,cothresh)
%
% coords = aboveCoThresh(view,scanNum,ROIcoords,cothresh)
%
% Returns coords of voxels for which co > cothresh.
%	
% djh, 7/98
% dbr, 6/99  Added interpretation for negative cothresh, that is,
%            keep all values *below* the absolute value of the
%            given cothresh.

% Get co for desired scanNum (note: there may be NaNs in ph for
% volume voxels that are outside the inplanes, but these voxels
% will be tossed because NaN is not greater than cothresh).
co = getCurDataROI(view,'co',scanNum,ROIcoords);

% Get ROIcoords for which co is above cothresh.
if cothresh > 0
  subROIIndices = find(co >= cothresh);
elseif cothresh < 0
  subROIIndices = find(co <= abs(cothresh));
else % if cothresh==0, or something weird
    subROIIndices = 1:size(ROIcoords, 2);
end

coords = ROIcoords(:,subROIIndices);
return
