%% t_tseriesLoadFromInplane
%
% Illustrates how to load a time series from a functional data set.
%
% Tested 01/05/2011 - MATLAB r2008a, Fedora 12, Current Repos
%
% Stanford VISTA
%

%% Initialize the key variables and data path
% Data directory (where the mrSession file is located)
dataDir = mrtInstallSampleData('functional','vwfaLoc');

%% Retain original directory, change to data directory
curDir = pwd;
cd(dataDir);

% There can be several data types - name the one you want to plot
dataType = 'MotionComp';

% Which scan number from that data type?
scan = 1;

% Would you like the raw time series?
isRawTSeries = true;

%% Get data structure:
vw = initHiddenInplane(); % Foregoes interface - loads data silently

%% Set data structure properties:
vw = viewSet(vw, 'CurrentDataType', dataType); % Data type

%% Get time series from ROI:
% Format returned is rows x cols x slices x time
tSeries = tSeries4D(vw, scan, [], 'usedefaults', ~isRawTSeries);

%% Show movie of a single slice across the given scan
figure;
colormap autumn;
nSlices = size(tSeries, 3);
nTimePoints = size(tSeries, 4);
rg = [-1 1] * max(abs(tSeries(:)));
for i = 1:nTimePoints
    imagesc(tSeries(:, :, ceil(nSlices/2), i), rg);
    axis image; colormap gray
    title(sprintf('Volume %d', i))
    pause(.1);
end
close;

%% Show movie of slices at a single time point
figure;
colormap autumn;
for i = 1:nSlices
    imagesc(tSeries(:, :, i, ceil(nTimePoints/2)));
    colormap gray
    axis image;
    title(sprintf('Slice %d', i))
    pause(.1);
end
close;

%% Restore original directory
cd(curDir);

%% END
