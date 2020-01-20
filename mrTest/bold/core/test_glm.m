function test_glm
%Validate calculation of general linear model
%
%  test_glm()
% 
% Tests: applyGlm, computeContrastMap2
%
% INPUTS
%  No inputs
%
% RETURNS
%  No returns
%
% Example: test_glm()
%
% See also MRVTEST
%
% Copyright Stanford team, mrVista, 2013

%% Initialize the key variables and data path
% Data directory (where the mrSession file is located)
dataDir = mrtInstallSampleData('functional','vwfaLoc');

% This is the validation file
storedGLM = mrtGetValididationData('glm');

% These are the items we stored in the validation file
% 
% val.dim             = size(contrastMap);
% val.contrastMean    = nanmean(contrastMap(:));
% val.contrastMed     = median(contrastMap(:));
% val.contrastMax     = max(contrastMap(:));
% val.contrastVoc     = contrastMap(40,40,10);
% 
% save(vFile, '-struct', 'val')

%% Retain original directory, change to data directory
curDir = pwd;
cd(dataDir);


% There can be several data types - name the one you want to use for
% computing GLM. 
dataType = 'MotionComp';

% We will compute a GLM for 2 scans ...
scans = 1:2;

%% Get data structure and calculate glm

% open a session
vw = initHiddenInplane;

% set to motion comp dataTYPES
vw = viewSet(vw, 'current data type', dataType);


% get the GLM params
params = er_getParams(vw, scans(1), dataType);

% run the GLM
vw = applyGlm(vw, dataType, scans, params, 'GLM');


% Compute a contrast map from command line
stim     = er_concatParfiles(vw);
active   = find(strcmpi(stim.condNames, 'Word'));
control  = find(strcmpi(stim.condNames, 'Fix'));
saveName = 'WordVFix';
vw       = computeContrastMap2(vw, active, control, saveName);

contrastMap = viewGet(vw, 'map', 1); contrastMap = contrastMap{1};

%% Return to original directory
cd(curDir)

%% Validate the results

assertEqual(storedGLM.dim, size(contrastMap));
assertElementsAlmostEqual(storedGLM.contrastMean, nanmean(contrastMap(:)), 'relative', .00001);
assertElementsAlmostEqual(storedGLM.contrastMed,  median(contrastMap(:)), 'relative', .00001);
assertElementsAlmostEqual(storedGLM.contrastMax,  max(contrastMap(:)), 'relative', .00001);
assertElementsAlmostEqual(storedGLM.contrastVoc,  contrastMap(40,40,10), 'relative', .00001);

mrvCleanWorkspace;

