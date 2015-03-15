%%  Script to run CSS and linear pRF model on sample data set
%
% Illustrates how to run CSS (compressive spatial summation) pRF model and
% compares the results to a linear model.
%
% 
% See also T_PRFMODEL (NYI)
%
% Tested 03/15/2015 - MATLAB r2014b
%
% Dependency: vistadata repository 

%% Initialize the key variables and data path:
% Data directory (where the mrSession file is located)
dataDir  = fullfile(mrvDataRootPath,'functional','prfInplane');
dataType = 'Averages';
ROI      = 'RV1';

%% Retain original directory, change to data directory
cd(dataDir);

%% Retrieve data structure and set data type:
vw = initHiddenGray;
vw = viewSet(vw, 'Current DataTYPE', dataType);
vw = loadROI(vw, ROI, [], [], 0, 1);

%% Open an inplane view and xform the time series
ip = initHiddenInplane;
ip = viewSet(ip, 'Current DataTYPE', 'Averages');
vw = ip2volTSeries(ip ,vw,0,'linear');

%% CSS model 
%    Define scan/stim and analysis parameters for CSS model
params = rmDefineParameters(vw, 'model', {'css'});
params = rmMakeStimulus(params);
vw  = viewSet(vw,'rmParams',params);

%    Run the CSS model
vw = rmMain(vw, [], 'grid fit', 'model', {'css'}, 'matfilename', sprintf('css_%s', ROI)); 

%% Linear model
%    Define scan/stim and analysis parameters for linear model
params = rmDefineParameters(vw, 'model', {'onegaussian'});
params = rmMakeStimulus(params);
vw  = viewSet(vw,'rmParams',params);

%    Run the linear model
vw = rmMain(vw, [], 'grid fit', 'model', {'onegaussian'}, 'matfilename', sprintf('onegaussian_%s', ROI)); 


%% Compare the linear and CSS models

css=load(fullfile(dataDir, 'Gray', dataType,  sprintf('css_%s-gFit', ROI)));
lin=load(fullfile(dataDir, 'Gray', dataType, sprintf('onegaussian_%s-gFit', ROI))); 

% Load the variance explained from both models. For every voxel, the CSS
% variance explained should be equal to or greater than the variance
% explained from the linear model, since the linear model is a subset of
% the CSS model
varexp{1} = rmGet(css.model{1}, 'varexp');
varexp{2} = rmGet(lin.model{1}, 'varexp');

% Plot it
figure; set(gca, 'FontSize', 20); hold all
scatter(varexp{1}(css.model{1}.roi.coordsIndex), varexp{2}(lin.model{1}.roi.coordsIndex))
plot([0 1], [0 1], 'k-', 'LineWidth', 4)
xlabel('css')
ylabel('linear')
title('var exp')