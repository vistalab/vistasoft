%% t_tseriesLoadFromROI
%
% Illustrates how to load a time series from a functional data set.
%
% Tested 01/05/2011 - MATLAB r2008a, Fedora 12, Current Repos
%
% Stanford VISTA
%

%% Initialize the key variables and data path
% Data directory (where the mrSession file is located)
dataDir = fullfile(mrvDataRootPath,'functional','vwfaLoc');

%% Retain original directory, change to data directory
curDir = pwd;
cd(dataDir);

% There can be several data types - name the one you want to plot
dataType = 'Original';

% An ROI currently located in the ROIs directory of the relevant dataType
roiName  = 'LV1';

% Which scan number from that data type?
scan = 1;

% Would you like the raw time series?
isRawTSeries = false;

%% Get data structure:
vw = initHiddenInplane(); % Foregoes interface - loads data silently

%% Set data structure properties:
vw = viewSet(vw, 'CurrentDataType', dataType); % Data type
vw = viewSet(vw, 'ROI', roiName); % Region of interest

%% Get time series from ROI:
tSeries = getTseriesOneROI(vw, viewGet(vw, 'ROICoords'), scan, isRawTSeries);

%% Compute the mean time series:
tSeriesMean = mean(tSeries{1}(:,:), 2); % Mean across voxels

%% Plot time series:
plot(tSeriesMean);

%% Restore original directory
cd(curDir);

%% END
