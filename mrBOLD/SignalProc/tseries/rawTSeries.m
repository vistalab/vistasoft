function tSeries = rawTSeries(view,scanNum,ROIcoords,detrendOption)
% tSeries = rawTSeries(view,scanNum,ROIcoords,detrendOption)
% PURPOSE:
% Returns the tSeries from all the voxels in the given ROIcoods
% INPUTS:
% scanNum: scan number
% ROIcoords can be either:
%    3xN array of (y,x,z) coords
%    cell array of ROIcoords arrays
% If detrendOption is true (the default) then tSeries are detrended using
% the current settings for that scan prior to being returned. Otherwise the
% percentage tSeries numbers are returned.
% RETURNS: cell array of tSeries matrices. Or a single tSeries matrix
% if only 1 ROI was requested.
% ARW 2004-03-21
% Based on meanTSeries


% Make sure the input is in the right format
if ~exist('ROIcoords','var')
    disp('You must pass in a valid set of ROIcoords');
    return;
end
if ~exist('detrendOption','var')
    detrendOption=1;
end

ROIcoords = ROIcoords2cellArray(view,ROIcoords);

% Find the slice indices for this collection of ROIs
sliceInds = getSlicesROI(view,ROIcoords);

nROIs = length(ROIcoords);

tSeries = cell(1,nROIs);

nFrames = numFrames(view,scanNum);
detrend = detrendFlag(view,scanNum);
smoothFrames = detrendFrames(view,scanNum);

% Take first pass through ROIs to see which slices to load
switch view.viewType
    case {'Inplane' 'Flat'}        
        sliceInds = [];
        for r=1:nROIs
            if isempty(ROIcoords{r})                disp(['MeanTSeries ignoring empty ROI in this slice'])            else
                sliceInds = [sliceInds, ROIcoords{r}(3,:)];
            end
        end        
        sliceInds = unique(sliceInds);
    case {'Gray'}
        sliceInds = 1;
    otherwise
        myErrorDlg('meanTSeries: Only for Inplane, Gray, or Flat views.');
end


% Loop through slicesfor iSlice = 1:length(sliceInds);    
    slice = sliceInds(iSlice);
    
    % Load tSeries & divide by mean, but don't detrend yet.
    % Otherwise, detrending the entire tSeries is much slower. DJH
    view = percentTSeries(view,scanNum,slice,0);
    
    for r=1:nROIs
        % Extract time-series
        subtSeries = getTSeriesROI(view,ROIcoords{r});
        
        if ~isempty(subtSeries)
            
            % Detrend now (faster to do it now after extracting subtSeries for a small subset of the voxels)
            if (detrendOption)
                subtSeries = detrendTSeries(subtSeries,detrend,smoothFrames);
            end
            
            % Stack 'em up
            if isempty(tSeries{r})
                tSeries{r} = [subtSeries];
                numPts{r} = size(subtSeries,2);            else                tSeries{r} = [tSeries{r},subtSeries];
                numPts{r} = numPts{r} + size(subtSeries,2);                
            end % End check on empty tSeries
        end % end check on empty subTSeries
    end % Next ROI
end % Next slice
% % Final pass through ROIs to turn sum into mean% 
% for r=1:nROIs
%     if isempty(numPts{r})
%         tSeries{r} = zeros(nFrames,1);
%     else% 
%         tSeries{r} = tSeries{r} / numPts{r};
%     end
% end

if (nROIs==1) % Don't mess around with cell arrays if we were only asked for a single ROI
    tSeries = tSeries{1};
end

% Clean up (because didn't detrend the whole tSeries properly)
view.tSeries=[];
view.tSeriesScan=NaN;
view.tSeriesSlice=NaN;

return;

