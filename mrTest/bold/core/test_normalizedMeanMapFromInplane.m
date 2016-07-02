function test_normalizedMeanMapFromInplane
%Validate calculation of normalized mean map
%
%  test_normalizedMeanMapFromInplane()
%
% Tests: loadMeanMap
%
% INPUTS
%  No inputs
%
% RETURNS
%  No returns
%
% Example: test_normalizedMeanMapFromInplane()
%
% See also MRVTEST
%
%  Copyright Stanford team, mrVista, 2012


%% Initialize the key variables and data path
% Data directory (where the mrSession file is located)
dataDir = mrtInstallSampleData('functional','mrBOLD_01');

% This is the validation file
storedmeanMap = mrtGetValididationData('normalizedMeanMapFromInplane');
%
% These are the items we storedCorAnal in the validation file
% 
% val.dim   = size(map);
% val.mn    = nanmean(map(:));
% val.max   = max(map(:));
% val.min   = min(map(:));
% val.med   = nanmedian(map(:));
% save(vFile, '-struct', 'val')


%% Retain original directory, change to data directory
curDir = pwd;
cd(dataDir);

% There can be several data types - name the one you want to plot
dataType = 'Original';

%% Get data structure:
vw = initHiddenInplane(); % Foregoes interface - loads data silently

%% Set dataTYPE:
vw = viewSet(vw, 'CurrentDataType', dataType); % Data type

%% Load mean map
vw = loadMeanMap(vw,true);  % true means load normalized mean map ([0 1])

map = viewGet(vw, 'map');

map = map{1};

cd(curDir)

% validate
assertElementsAlmostEqual(storedmeanMap.dim, size(map));

assertElementsAlmostEqual(storedmeanMap.mn,nanmean(map(:)));

assertElementsAlmostEqual(storedmeanMap.max, max(map(:)));

assertElementsAlmostEqual(storedmeanMap.min, min(map(:)));

assertElementsAlmostEqual(storedmeanMap.med, median(map(:)));


%% End Script

mrvCleanWorkspace;


