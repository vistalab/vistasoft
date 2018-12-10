function test_getCurDataROI
%Validate getting data from an INPLANE ROI
%
%  test_getCurDataROI()
% 
% Tests: loadCoranal, getCurDataROI
%
% INPUTS
%  No inputs
%
% RETURNS
%  No returns
%
% Example: test_getCurDataROI()
%
% See also MRVTEST
%
% Copyright Stanford team, mrVista, 2011

%% Initialize the key variables and data path
% Data directory (where the mrSession file is located)
dataDir = mrtInstallSampleData('functional','mrBOLD_01');

% This is the validation file
storedROIdata = mrtGetValididationData('getCurDataROIfromINPLANE');

% These are the items we stored in the validation file
% 
% val.codim      = size(co);
% val.comn       = nanmean(co);
% val.indsdim    = size(inds);
% val.cosample   = co(100);
% val.indssample = inds(100);
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

vw = loadCorAnal(vw);

[co, inds] = getCurDataROI(vw, 'co', scan);

%% Go home
cd(curDir)

%% Validate..

% check the dimensions of coherence map and voxel indices
assertEqual(storedROIdata.codim, size(co));
assertEqual(storedROIdata.indsdim, size(inds));

% check the mean coherence value
assertElementsAlmostEqual(storedROIdata.comn,nanmean(co));

% check the coherence value and voxel index for an arbitrary sample voxel
% (to make sure the sequence is correct)
assertElementsAlmostEqual(storedROIdata.cosample, co(100));
assertEqual(storedROIdata.indssample, inds(100));

mrvCleanWorkspace;