function test_prf_full()
%Validate calculation of prf model, including gFit, sFit, hrfFit, final fit
%
%  test_prf()
% 
% Tests: ip2volTSeries, rmMain, rmGridFit, rmSearchFit, rmHrfSearchFit
%
% INPUTS
%  No inputs
%
% RETURNS
%  No returns
%
% Example: test_prf_full()
%
% See also MRVTEST
%
% Copyright Stanford team, mrVista, 2015

%% Initialize the key variables and data path
% Data directory (where the mrSession file is located)
dataDir = mrtInstallSampleData('functional','prfInplane');

% This is the validation file
storedPRF = mrtGetValididationData('prfFull');

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
vw = rmMain(vw,'RV1.mat' ,5,'min pRF size', 0.5, 'max pRF size', 3,...
    'number of sigmas', 6, 'outerlimit', 0, ...
    'coarse sample', false, 'decimate', 0);
mGauss = load(viewGet(vw, 'rm file'));

coords = rmGet(mGauss.model{1}, 'roiindices');
eccGauss = rmCoordsGet('gray', mGauss.model{1}, 'ecc', coords);
sigGauss = rmCoordsGet('gray', mGauss.model{1}, 'sigma', coords);
xGauss   = rmCoordsGet('gray', mGauss.model{1}, 'x', coords);
veGauss  = rmCoordsGet('gray', mGauss.model{1}, 've', coords);
%% Return to original directory
cd(curDir)

%% Validate the results
tol = 1e-4;

assertEqual(storedPRF.roiname,rmGet(mGauss.model{1}, 'roiname'));

assertEqual(storedPRF.coordsSz, length(coords));

assertElementsAlmostEqual(storedPRF.eccmn, nanmean(eccGauss), 'relative', tol);

assertElementsAlmostEqual(storedPRF.sigmn, nanmean(sigGauss), 'relative', tol);

assertElementsAlmostEqual(storedPRF.xmax, max(xGauss), 'relative', tol);

assertElementsAlmostEqual(storedPRF.vemax, max(veGauss), 'relative', tol);

mrvCleanWorkspace;

%% Test CSS pRF model separately
% [ERK 11/17/21]: While one can request multiple models within one command
% using the variable input 'pRFModel',{'onegaussian','css'}, here we test
% the css model separately as it avoids getting exponents fixed to 1. This
% is because the rmDefineParameters.m function only defines parameters
% based on the first model ('one gaussian', not the second 'css').
vw = rmMain(vw,'RV1.mat' ,5,'min pRF size', 0.5, 'max pRF size', 3,...
    'number of sigmas', 6, 'outerlimit', 0, ...
    'coarse sample', false, 'decimate', 0, 'pRFModel',{'css'});
mCSS = load(viewGet(vw, 'rm file'));

coords = rmGet(mCSS.model{1}, 'roiindices');

% Check if css exponent ranges between 0-1.
expCSS  = rmCoordsGet('gray', mCSS.model{1}, 'exponent', coords);
assert(min(expCSS)>=0);
assert(max(expCSS)<=1);

%% TO DO: Store PRF results and compare against current output %%
eccCSS = rmCoordsGet('gray', mCSS.model{1}, 'ecc', coords);
sigCSS = rmCoordsGet('gray', mCSS.model{1}, 'sigma', coords);
xCSS   = rmCoordsGet('gray', mCSS.model{1}, 'x', coords);
veCSS  = rmCoordsGet('gray', mCSS.model{1}, 've', coords);


%% End Script



