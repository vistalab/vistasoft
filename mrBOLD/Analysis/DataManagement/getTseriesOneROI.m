function [roitSeries, subCoords] = getTseriesOneROI(vw, ROIcoords, scanNum, getRawTseries, removeRedundant)
% 
%   [roitSeries, subCoords] = getTseriesOneROI(vw,ROIcoords,scanNum, getRawTseriesFlag(=0 default), removeRedundantFlag(=1 default) )
%
% For a single ROI, we loop through slices and acquire all of the
% tSeries(voxel by voxel). Return these time courses, removing redundant
% tSeries (which occur because several anatomical coords may reference the
% same functional voxel). Also returns the locations of the non-redundant
% voxels in subCoords.
% The removing redundant can be turned off by removeRedundantFlag = 0;
%
% ras, 04/04: remove redundant time courses from upsampling the functional.
% ras, 05/04: also, return the sub-coords, with the redundant voxels
% removed. (They'll be in the coordinates of the inplane anatomy, but 
% there will only be one voxel contained within a given functional voxel.)
% ras, 5/2004 -- now it returns the tSeries in the order that corresponds
% to the voxels specified in ROIcoords (before, it would return in them
% in a semi-shuffled order if you were in the inplane view -- b/c of 
% the loop through slices).
% jl, 5/2005 - make "remove redundant from upsampling" optional

% Make sure the input is in the right format
if notDefined('ROIcoords'),         ROIcoords       = viewGet(vw, 'ROI coords'); end
if notDefined('scanNum'),           scanNum         = viewGet(vw, 'Current Scan'); end
if notDefined('getRawTseries'),     getRawTseries   = 0; end
if notDefined('removeRedundant'),   removeRedundant = 1; end

ROIcoords = ROIcoords2cellArray(vw,ROIcoords);

% b/c of upsampling b/w the functionals and anats,
% there tend to be redundant coords specifying the 
% same functional voxel -- remove these:
switch vw.viewType
    case 'Inplane',
        if removeRedundant
            % b/c of upsampling b/w the functionals and anats, there tend
            % to be redundant coords specifying the same functional voxel
            % -- remove these:
            subCoords = roiSubCoords(vw,ROIcoords{1});
        end
        ROIcoords = {subCoords};
    case 'Flat',
        % the tSeries will only cover points
        % on the flat map mapped by the ROI, 
        % ignoring ones on blank/masked nodes

        % jw: comment out
        %         ind = sub2ind(size(vw.indices),ROIcoords{1}(1,:),...
        %                         ROIcoords{1}(2,:),ROIcoords{1}(3,:));
        %         ind = find(vw.indices(ind)>0);
        %         subCoords = ROIcoords{1}(:,ind);

        % jw: comment in
        subCoords = ROIcoords;
    otherwise,
        subCoords = ROIcoords;
end


roitSeries = [];

if ~getRawTseries
    detrend = detrendFlag(vw,scanNum);
    smoothFrames = detrendFrames(vw,scanNum);
end

% Find the slice indices for this collection of ROIs
sliceInds = getSlicesROI(vw,ROIcoords);

for iSlice = 1:length(sliceInds)
    slice = sliceInds(iSlice);
    
    % Load tSeries & divide by mean, but don't detrend yet.
    % Otherwise, detrending the entire tSeries is much slower. DJH
    % this crashes on the volume - out of memory - kgs 06/05
    % rewrote this section
    if(getRawTseries)
        vw = percentTSeries(vw,scanNum,slice,0,0,0,1);
     else
        vw = percentTSeries(vw,scanNum,slice,0);
     end
 
    % Extract time-series from the current slice
    %  The third argument of getTSeriesROI is 'preserveCoords', which is
    %  the logical opposite of removeRedundant. That is, if we remove
    %  redundant voxels, we will not preserve the coordinates (we will get
    %  back fewer time series than coordinates), and vice versa.
    preserveCoords = ~removeRedundant;
    [subtSeries subIndices] = getTSeriesROI(vw,ROIcoords{1}, preserveCoords);
    
    if removeRedundant & strcmpi(viewGet(vw, 'view type'), 'gray')
        coords = viewGet(vw, 'coords');
        subCoords{1} = coords(:, subIndices);
    end

    
    if ~isempty(subtSeries) & ~getRawTseries %#ok<*AND2>
        % Norm and Detrend (faster and doesn't crash after extracting subtSeries for a small subset of the voxels)
        subtSeries = detrendTSeries(subtSeries,detrend,smoothFrames);
    end
    
    switch vw.viewType
        case 'Inplane',
            % assign to the columns in roitSeries that correspond to the selected
            % voxels:
            voxelsInSlice = ROIcoords{1}(3,:) == vw.tSeriesSlice;    
            roitSeries(:,voxelsInSlice) = subtSeries;
        case 'Gray',
            roitSeries = subtSeries;
        case 'Volume',
            roitSeries = subtSeries;
        case 'Flat',
            roitSeries = [roitSeries subtSeries];
    end
end

% make a cell (to be in line with multi-ROI analyses)
roitSeries = {roitSeries};
clear vw.tSeries; % free memory


return
