function [totalDist, bins] = measureCorticalDistanceBins(view, coords, binDist, grayView)
% [totalDist, bins] = measureCorticalDistanceBins(view, coords, [binDist], [grayView])
%
% RETURNS:
%  totalDist- total cortical distance along the ROI, in mm
%  bins- an array of bin structs, one for each bin created. This includes:
%   (see buildNodeBins for details).
%
%
% SEE ALSO:
%  measureCorticalDistance
%  buildNodeBins
%  roi_getFlatNodes
%  mrManDist
%
% HISTORY:
% 2002.12.20 RFD (bob@white.stanford.edu) wrote it.

if(~exist('binDist','var') | isempty(binDist))
    answer = inputdlg('Enter the bin distance (in mm)','Bin Distance',1,{'4'});
    if(isempty(answer))
        return;
    end
    binDist = str2num(answer{1});
end
if(~exist('grayView','var') | isempty(grayView))
    grayView = getSelectedGray;
    if isempty(grayView)
        grayView = initHiddenGray;
    end
end

[flatNodeIndices, volNodeIndices, flatNodeDist, slice] = roi_getFlatNodes(view, coords, 1, grayView);
bins = buildNodeBins(view, [volNodeIndices{:}], binDist, slice, grayView);
totalDist = sum([bins.distToPrev]);
disp([num2str(binDist),' mm bin size: total cortical distance: ',num2str(totalDist),'mm.']);

if(nargout<1)
    msgbox(['Total cortical distance: ', num2str(totalDist),'mm.'], 'Cortical Distance');
end