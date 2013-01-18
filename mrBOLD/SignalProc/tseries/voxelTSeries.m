function [voxelTcs, coords] = voxelTSeries(view, coords, scans, getRawTSeries, preserveCoords)
% 
%   [voxelTcs, coords] = voxelTSeries(view, [coords, scans, getRawTSeries, preserveCoords])
%
% Return a matrix with the time series for each voxel within
% the selected ROI/ROIs. A replacement for getTseriesOneROI (this I think
% is a much clearer name.) Unlike that function, this returns
% a matrix rather than a cell.
%
% The format of the returned voxelTcs is 2D matrix,
% with the format rows->time points, cols->voxels. 
% The coordinates of the voxel for each column 
% is given in the corresponding column of coords. 
%
% Note that in inplane views, removes redundant voxels/tSeries 
% which occur because several anatomical coords may reference the
% same functional voxel). 
%
% view: mrVista view (Inplane, Gray, or Flat Level).
% coords: 3 x N ROI coordinates, or else cell of such coords for
% many ROIs. [Default cur Roi coords]
% scans: # of scans from which to take tSeries. [default cur scan]
% getRawTSeries: flag to return tSeries w/o detrending, processing,
% [default 0].
%
% preserveCoords: a flag to not remove redundant tSeries (e.g.,
% if multiple anatomical voxels point to the same functional 
% place). If 1, will return exactly one tSeries column for 
% each column in the input coords, even if they're redundant 
% or empty. Default 0: be efficient.
%
%
%
%
% ras, 04/01/05: renamed, updated from getTseriesOneROI.
if notDefined('view'),    view = getSelectedInplane;          end
if notDefined('coords'),  coords = getCurROIcoords(view);     end
if notDefined('scans'),   scans = getCurScan(view);           end
if notDefined('getRawTSeries'),    getRawTSeries = 0;         end
if notDefined('preserveCoords'),   preserveCoords = 0;        end

% recursively loop through scans if more
% than one selected
if length(scans)>1
    voxelTcs = [];
    for i = 1:length(scans)
        voxelTcs = [voxelTcs; voxelTSeries(view,coords,scans(i),getRawTSeries)];
    end
    return
end

if preserveCoords==0
	% b/c of upsampling b/w the functionals and anats,
	% there tend to be redundant coords specifying the 
	% same functional voxel -- remove these:
	coords = roiSubCoords(view,coords);
end


% Find the slice indices for this collection of ROIs
sliceInds = getSlicesROI(view,coords);

voxelTcs = [];

nFrames = numFrames(view,scans);
detrend = detrendFlag(view,scans);
smoothFrames = detrendFrames(view,scans);

% Find the slice indices for this collection of ROIs
sliceInds = getSlicesROI(view,coords);

for iSlice = 1:length(sliceInds)
    slice = sliceInds(iSlice);
    
    % Load tSeries & divide by mean, but don't detrend yet.
    % Otherwise, detrending the entire tSeries is much slower. DJH
    if getRawTSeries==1
        view = percentTSeries(view,scans,slice,0,0,0,1);
    else
        view = percentTSeries(view,scans,slice,0);
    end
    
    % Extract time-series from the current slice
    [subtSeries subIndices] = getTSeriesROI(view, coords, preserveCoords);
    
    if ~isempty(subtSeries) & getRawTSeries==0
        % Detrend now (faster to do it now after extracting subtSeries for a small subset of the voxels)
        subtSeries = detrendTSeries(subtSeries,detrend,smoothFrames);
    end
    
    switch view.viewType
        case 'Inplane',
            % assign to the columns in voxelTcs that correspond to the selected
            % voxels:
            voxelsInSlice = find(coords(3,:) == view.tSeriesSlice);    
            voxelTcs(:,voxelsInSlice) = subtSeries;
        case {'Gray', 'Volume'},
            voxelTcs = subtSeries;
			coords = view.coords(:,subIndices);
        case 'Flat',
            voxelTcs = [voxelTcs subtSeries];
    end
end

return
