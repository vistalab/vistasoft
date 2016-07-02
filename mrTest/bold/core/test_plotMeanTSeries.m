function test_plotMeanTSeries
%Validate getting plotting the mean TSeries from an INPLANE ROI
%
%  test_plotMeanTSeries()
% 
% Tests: meanTSeries, plotMeanTSeries
%
% INPUTS
%  No inputs
%
% RETURNS
%  No returns
%
% Example: test_plotMeanTSeries()
%
% See also MRVTEST
%
% Copyright Stanford team, mrVista, 2011

%% Initialize the key variables and data path
% Data directory (where the mrSession file is located)
dataDir = mrtInstallSampleData('functional','mrBOLD_01');

% This is the validation file
val = mrtGetValididationData('plotMeanTSeriesFromINPLANE');

% These are the items we stored in the validation file
%
% val.detrendDim  = size(d.detrend.frameNumbers);
% val.rawDim      = size(d.raw.frameNumbers);
% val.detrendMn   = mean(d.detrend.tSeries);
% val.detrendMd   = median(d.detrend.tSeries);
% val.detrendMx   = max(d.detrend.tSeries);
% val.detrendMin  = min(d.detrend.tSeries);
% val.rawMn       = mean(d.raw.tSeries);
% val.rawMd       = median(d.raw.tSeries);
% val.rawMx       = max(d.raw.tSeries);
% val.rawMin      = min(d.raw.tSeries);
% 
% save(vFile, '-struct', 'val')

%% Retain original directory, change to data directory
curDir = pwd;
cd(dataDir);

% There can be several data types - name the one you want to probe
dataType = 'Original';

% Which scan number from that data type?
scan = 1;

%% Get data structure:
vw = initHiddenInplane(); % Foregoes interface - loads data silently

%% Set dataTYPE:
vw = viewSet(vw, 'Current DataType', dataType); % Data type

%% Load an ROI and coranal
vw = loadROI(vw, 'LV1.mat');

detrend = true;

% open a plot figure
newGraphWin;

% load both raw and detrended tSeries so we can validate both
d.detrend = plotMeanTSeries(vw, scan, [], ~detrend);
d.raw     = plotMeanTSeries(vw, scan, [], detrend);

% close it
closeGraphWin;

%% Go home
cd(curDir)

%% Validate..

% check the number of time points 
assertEqual(val.detrendDim, size(d.detrend.frameNumbers));
assertEqual(val.rawDim,     size(d.raw.frameNumbers));

% check detrended t-series
assertElementsAlmostEqual(val.detrendMn,mean(d.detrend.tSeries));
assertElementsAlmostEqual(val.detrendMd,median(d.detrend.tSeries));
assertElementsAlmostEqual(val.detrendMx,max(d.detrend.tSeries));
assertElementsAlmostEqual(val.detrendMin,min(d.detrend.tSeries));

% check raw t-series
assertElementsAlmostEqual(val.rawMn,mean(d.raw.tSeries));
assertElementsAlmostEqual(val.rawMd,median(d.raw.tSeries));
assertElementsAlmostEqual(val.rawMx,max(d.raw.tSeries));
assertElementsAlmostEqual(val.rawMin,min(d.raw.tSeries));

%% Clear workspace

mrvCleanWorkspace;