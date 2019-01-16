function [tSeries, tSerr] = meanTSeries(vw, scanNum, roi, getRawData)
% Computes the mean tSeries, averaged over ROIcoords, for scanNum.
%
%   tSeries = meanTSeries(vw, scanNum, [roi], [getRawData])
%
% scanNum: scan number
% roi:     roi specification (ROI coords, name of loaded ROI, or ROI
%           struct). It can also be a cell array, in which case the
%           returned tSeries will also be a cell array, one entry for each
%           ROI.
% getRawData: if true, then do not detrend and do not convert to % signal
%
% djh, 7/98
% djh, 2/2001
% - updated to mrLoadRet-3.0
% - updated to work for gray and flat views
% bw/ab 6/2003
% - wrote getSlicesROI, ROIcoords2cellArray and inserted here so
%   we could use those routines in other places, too.
% Ress, 4/05 One fix and a new feature:
% Fix: Added code to properly ignore bad-flagged (NaN) values when taking
%       the mean. Feature: Now returns spatial SEM as an optional second
%       output argument; note that this estimate needs to be scaled up by a
%       voxel-size dependent spatial correlation factor
if notDefined('roi'),        roi         = vw.selectedROI; end
if notDefined('getRawData'), getRawData  = false;            end

% make sure the ROI is properly specified
roi = tc_roiStruct(vw, roi);

% if the ROI is empty, don't bother with the rest of this function
if length(roi) == 1 && isempty(roi.coords)
    tSeries = [];
    tSerr = [];
    return
end

% get the set of ROI coords as a cell array
for n = 1:length(roi)
    ROIcoords{n} = roi(n).coords;
end

% Find the slice indices for this collection of ROIs
sliceInds = getSlicesROI(vw, ROIcoords);

nROIs = length(ROIcoords);

tSeries = cell(1,nROIs);
tSerr   = cell(1, nROIs);

nFrames               = viewGet(vw, 'numFrames', scanNum);
detrend               = detrendFlag(vw,scanNum);
inhomoCorrection      = inhomoCorrectionFlag(vw, scanNum);
temporalNormalization = temporalNormalizationFlag(vw, scanNum);
smoothFrames          = detrendFrames(vw,scanNum);

if getRawData
    detrend = false;
    inhomoCorrection      = false;
    temporalNormalization = false;
    %smoothFrames = 0;
end

% Take first pass through ROIs to see which slices to load
switch vw.viewType
    case {'Inplane' 'Flat'}
        sliceInds = [];
        for r=1:nROIs
            if isempty(ROIcoords{r})
                disp('MeanTSeries: ignoring empty ROI in this slice')
            else
                sliceInds = [sliceInds, ROIcoords{r}(3,:)];
            end
        end
        sliceInds = unique(sliceInds);
    case {'Gray' 'Volume'}
        sliceInds = 1;
    otherwise
        myErrorDlg('meanTSeries: Only for Inplane, Gray, or Flat views.');
end



% Load tSeries & divide by mean, but don't detrend yet.
% Otherwise, detrending the entire tSeries is much slower. DJH
detrendNow    = false;
noMeanRemoval = false;
if getRawData,	noMeanRemoval = true; end % just get the raw data!

vw = percentTSeries(vw,scanNum,sliceInds,detrendNow,inhomoCorrection,temporalNormalization,noMeanRemoval);


for r=1:nROIs
    % Extract time-series
    subtSeries = getTSeriesROI(vw,ROIcoords{r});
    if ~isempty(subtSeries)
        
        % Detrend now (faster to do it now after extracting subtSeries for a small subset of the voxels)
        subtSeries = detrendTSeries(subtSeries, detrend, smoothFrames);
        % Add 'em up
        if isempty(tSeries{r})
            numPts{r} = sum(isfinite(subtSeries), 2);
            subtSeries(~isfinite(subtSeries)) = 0;
            tSerr{r} = sum(subtSeries.^2, 2);
            tSeries{r} = sum(subtSeries, 2);
        else
            numPts{r} = numPts{r} + sum(isfinite(subtSeries), 2);
            subtSeries(~isfinite(subtSeries)) = 0;
            tSerr{r} = tSerr{r} + sum(subtSeries.^2, 2);
            tSeries{r} = tSeries{r} + sum(subtSeries,2);
        end
    end
end


% Final pass through ROIs to turn sum into mean
for r=1:nROIs
    if isempty(numPts{r})
        tSeries{r} = zeros(nFrames,1);
        tSerr{r} = zeros(nFrames, 1);
    else
        tSeries{r} = tSeries{r} ./ numPts{r};
        tSerr{r} = sqrt((tSerr{r} ./ numPts{r}.^2) - tSeries{r}.^2./numPts{r});
    end
end

if (nROIs==1)
    tSeries = tSeries{1};
    tSerr = tSerr{1};
end

% Clean up (because didn't detrend the whole tSeries properly)
vw.tSeries=[];
vw.tSeriesScan=NaN;
vw.tSeriesSlice=NaN;

return;

