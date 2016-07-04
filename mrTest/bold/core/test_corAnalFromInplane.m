function test_corAnalFromInplane
%Validate calculation of coranal.
%
%  test_corAnalFromInplane()
% 
% Tests: computeCorAnalSeries
%
% INPUTS
%  No inputs
%
% RETURNS
%  No returns
%
% Example: test_corAnalFromInplane()
%
% See also MRVTEST
%
% Copyright Stanford team, mrVista, 2011

%% Initialize the key variables and data path

% Data directory (where the mrSession file is located)
dataDir = mrtInstallSampleData('functional','mrBOLD_01');

% This is the validation file
storedCorAnal = mrtGetValididationData('coranalFromInplane');

% These are the items we stored in the validation file
% 
% val.dim    = size(coSeries);
% val.comn   = nanmean(coSeries);
% val.ampmn  = nanmean(ampSeries);
% val.phmn   = nanmean(phSeries);
% val.comax  = max(coSeries);
% val.ampmax = max(ampSeries);
% val.phmax  = max(phSeries);
% save(vFile, '-struct', 'val')


%% Retain original directory, change to data directory
curDir = pwd;
cd(dataDir);

% There can be several data types - name the one you want to use for computing coranal
dataType = 'Original';

% We will compute a coranal for just one scan...
scan = 1;

% and just one slice.
slice = 1;

%% Get data structure and calculate coranal
vw = initHiddenInplane(); % Foregoes interface - loads data silently

% Set dataTYPE:
vw = viewSet(vw, 'Current DataType', dataType);

% Get the number of cycles for the block design
nCycles = viewGet(vw, 'num cycles', scan);

% calculate the coranal
[coSeries,ampSeries,phSeries] = ...
    computeCorAnalSeries(vw, scan, slice, nCycles);

%% Return to original directory
cd(curDir)

%% Validate the results
assertEqual(storedCorAnal.dim, size(coSeries));

assertElementsAlmostEqual(storedCorAnal.comn,nanmean(coSeries));

assertElementsAlmostEqual(storedCorAnal.ampmn, nanmean(ampSeries));

assertElementsAlmostEqual(storedCorAnal.phmn, nanmean(phSeries));

assertElementsAlmostEqual(storedCorAnal.comax, max(coSeries));

assertElementsAlmostEqual(storedCorAnal.ampmax, max(ampSeries));

assertElementsAlmostEqual(storedCorAnal.phmax, max(phSeries));

mrvCleanWorkspace;

%% End Script