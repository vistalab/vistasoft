function sliceInds = getSlicesROI(view,ROIcoords)
%
%  sliceInds = getSlicesROI(view,ROIcoords)
%
% Author:  BW/AB
%    Figure out which slices are needed to represent the data in the cell
% array of ROIcoords
%    Only the ROI and the ROI fields are used.
%

% Convert/construct ROIcoords arg so that it is a cell array of coords
if ~exist('ROIcoords','var')
    % If the ROIcoords isn't passed in, assume all of the ROIs?  Why not
    % just current ROI?
    ROIcoords = cell(1,length(view.ROIs));
    for r=1:length(ROIcoords)
        ROIcoords{r} = view.ROIs(r).coords;
    end
end

% If not a cell array already, convert it
if ~iscell(ROIcoords)
    tmp{1} = ROIcoords;
    ROIcoords = tmp;
end

nROIs = length(ROIcoords);
    

% Take first pass through ROIs to see which slices to load
switch view.viewType
case {'Inplane' 'Flat'}
    sliceInds = [];
    for r=1:nROIs
        if isempty(ROIcoords{r})
            warning('Ignoring empty ROI')
        else
            sliceInds = [sliceInds, ROIcoords{r}(3,:)];
        end
    end
    sliceInds = unique(sliceInds);
case {'Gray' 'Volume'}
    sliceInds = 1;
otherwise
    myErrorDlg('meanTSeries: Only for Inplane, Volume, or Flat views.');
end

return;