function test_prf()
%Validate calculation of prf model.
%
%  test_prf()
% 
% Tests: ip2volTSeries, rmMain, rmGridFit
%
% INPUTS
%  No inputs
%
% RETURNS
%  No returns
%
% Example: test_prf()
%
% See also MRVTEST
%
% Copyright Stanford team, mrVista, 2015

%% Initialize the key variables and data path
% Data directory (where the mrSession file is located)
dataDir = mrtInstallSampleData('functional','prfInplane');

% This is the validation file
storedPRF = mrtGetValididationData('prfInplane');

% These are the items we stored in the validation file
% 
% val.roiname    = rmGet(m.model{1}, 'roiname');
% val.eccmn      = nanmean(ecc);
% val.sigmn      = nanmean(sig);
% val.xmax       = max(x);
% val.vemax      = max(ve);
% val.coordsSz   = length(coords);
% save(vFile, '-struct', 'val')


%% Retain original directory, change to data directory
curDir = pwd;
cd(dataDir);

% There can be several data types - we will compute PRF model from Averages
dataType = 'Averages';

%% Transfer time series from inplane to gray
ip = initHiddenInplane(); % Foregoes interface - loads data silently

% Set dataTYPE:
ip = viewSet(ip, 'Current DataType', dataType);

% Same for Gray view - initialize hidden view and set dataTYPE
vw = initHiddenGray();
vw = viewSet(vw, 'Current DataType', dataType);

% Transfer time series from inplane to gray
vw = ip2volTSeries(ip,vw,1,'linear'); clear ip;

%% calculate the pRF model
vw = loadROI(vw, 'RV1.mat', 3, [], 0, 1);
vw = rmMain(vw,'RV1.mat' ,1,'min pRF size', 0.5, 'max pRF size', 3,...
    'number of sigmas', 6, 'outerlimit', 0, ...
    'coarse sample', false, 'decimate', 0);

m = load(viewGet(vw, 'rm file'));

coords = rmGet(m.model{1}, 'roiindices');
ecc = rmCoordsGet('gray', m.model{1}, 'ecc', coords);
sig = rmCoordsGet('gray', m.model{1}, 'sigma', coords);
x   = rmCoordsGet('gray', m.model{1}, 'x', coords);
ve  = rmCoordsGet('gray', m.model{1}, 've', coords);
%% Return to original directory
cd(curDir)

%% Validate the results
assertEqual(storedPRF.roiname,rmGet(m.model{1}, 'roiname'));

assertElementsAlmostEqual(storedPRF.eccmn, nanmean(ecc));

assertElementsAlmostEqual(storedPRF.sigmn, nanmean(sig));

assertElementsAlmostEqual(storedPRF.xmax, max(x));

assertElementsAlmostEqual(storedPRF.vemax, max(ve));

assertElementsAlmostEqual(storedPRF.coordsSz, length(coords));


% clean up vistadata repository because this test script wrote new data
%test_CleanUpSVN
mrvCleanWorkspace;

%% End Script



