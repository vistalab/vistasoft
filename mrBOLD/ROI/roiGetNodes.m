function [nodeIndices, nodeDist] = roiGetNodes(ROI, grayView)
%
%  [nodeIndices, nodeDist] = roiGetNodes(ROI, grayView)
%
%  Finds the gray matter nodes for the coords of a Volume ROI. This is a
%  necessary step torward computing the distance along the ROI. Next step
%  is binning and getting the ph and co info with ROIBuildBins.
%
% HISTORY:
%   2007.02.16 RFD wrote it.

mrGlobals;

if(isempty(ROI.coords))
    error('ROI coords are empty')
else
    % Find the nearest gray node for each coordinate.
    %
    [nodeIndices, bestSqDist] = nearpoints(ROI.coords, grayView.nodes([2,1,3],:));
    if(nargout>1)
        nodeDist = sqrt(bestSqDist);
    end
end
return;
