function test_meanMapFromInplane
%Validate calculation of mean map.
%
%  test_meanMapFromInplane()
% 
% Tests: computeMeanMap
%
% INPUTS
%  No inputs
%
% RETURNS
%  No returns
%
% Example: test_meanMapFromInplane()
%
% See also MRVTEST
%
% Copyright Stanford team, mrVista, 2012

%% Initialize the key variables and data path
% Data directory (where the mrSession file is located)
dataDir = mrtInstallSampleData('functional', 'mrBOLD_01');

% This is the validation file
storedmeanMap = mrtGetValididationData('meanMapFromInplane');

% These are the items we stored in the validation file
%
% val.dim   = size(map);
% val.mn    = nanmean(map(:));
% val.max   = max(map(:));
% val.min   = min(map(:));
% val.med   = nanmedian(map(:));
% save(vFile, '-struct', 'val');


%% Retain original directory, change to data directory
curDir = pwd;
cd(dataDir);

% There can be several data types - name the one you want to plot
dataType = 'Original';

% Which scan number from that data type?
scan = 1;

%% Get data structure:
vw = initHiddenInplane(); % Foregoes interface - loads data silently

%% Set dataTYPE:
vw = viewSet(vw, 'CurrentDataType', dataType); % Data type

%% Calculate mean map
vw = computeMeanMap(vw,scan, -1); % -1 means do not save

map = viewGet(vw, 'map');
map = map{1};

cd(curDir)

assertElementsAlmostEqual(storedmeanMap.dim, size(map));

assertElementsAlmostEqual(storedmeanMap.mn,nanmean(map(:)));

assertElementsAlmostEqual(storedmeanMap.max, max(map(:)));

assertElementsAlmostEqual(storedmeanMap.min, min(map(:)));

assertElementsAlmostEqual(storedmeanMap.med, median(map(:)));


mrvCleanWorkspace;


