function test_tSeries4D
%Validate loading a raw time series from a functional data set.
%
%  test_tSeries4D()
%
% Tests: loadtseries, percentTseries, tSeries4D
%
% INPUTS
%  No inputs
%
% RETURNS
%  No returns
%
% Example: test_tSeries4D()
%
% See also MRVTEST
%
% Copyright Stanford team, mrVista, 2011

%% Initialize the key variables and data path
% Data directory (where the mrSession file is located)
dataDir = mrtInstallSampleData('functional','mrBOLD_01');

% This is the validation file
storedTSeries = mrtGetValididationData('tSeries4D');
%
% storedTSeries.dim = size(tSeries);
% storedTSeries.mn =  mean(double(tSeries(:)));
% storedTSeries.sd = std(double(tSeries(:)));
% save(vFile, '-struct',  'storedTSeries')



%% Retain original directory, change to data directory
curDir = pwd;
cd(dataDir);

% There can be several data types - name the one you want to plot
dataType = 'MotionComp';

% Which scan number from that data type?
scan = 1;

%% Get data structure:
vw = initHiddenInplane(); % Foregoes interface - loads data silently

%% Set data structure properties:
vw = viewSet(vw, 'CurrentDataType', dataType); % Data type

%% Get time series from ROI:
% Format returned is rows x cols x slices x time
% Setting 'usedefaults' to false means we get raw tseries (no detrending)
tSeries = tSeries4D(vw, scan, [], 'usedefaults', 0);

% Get back to the testing directory: 
cd(curDir)

assertEqual(storedTSeries.dim, size(tSeries));

assertVectorsAlmostEqual(storedTSeries.mn, mean(double(tSeries(:))), 'relative', 1e-10);

assertVectorsAlmostEqual(storedTSeries.sd, std(double(tSeries(:))),'relative',  1e-10);


mrvCleanWorkspace;

%% End Script




