%%  Script to run CSS and linear pRF model on sample data set
%
% Illustrates how to run CSS (compressive spatial summation) pRF model and
% compares the results to a linear model.
%
%
% See also T_PRFMODEL (NYI)
%
% Tested 03/30/2015 - MATLAB r2014b
%
% Dependency: vistadata repository

%% Initialize the key variables and data path:
% Data directory (where the mrSession file is located)
dataDir  = fullfile(mrvDataRootPath,'functional','prfInplane');
dataType = 'Averages';
ROI      = 'RV1';

%% Retain original directory, change to data directory
curdir = pwd; cd(dataDir);

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
vw = rmMain(vw, [], 'coarse to fine', 'model', {'css'}, 'matfilename', sprintf('css_%s', ROI));

%% Linear model
%    Define scan/stim and analysis parameters for linear model
params = rmDefineParameters(vw, 'model', {'onegaussian'});
params = rmMakeStimulus(params);
vw  = viewSet(vw,'rmParams',params);

%    Run the linear model
vw = rmMain(vw, [], 'coarse to fine', 'model', {'onegaussian'}, 'matfilename', sprintf('onegaussian_%s', ROI));

%% Load the solutions from the linear and CSS models and extract a parameter of interest
model_types = {'css', 'onegaussian'};

% Examine variance explained across models. This could be replaced with
%   'x', 'y', 'sigma', 'ecc', 'polarangle', etc.
which_param = 'varexp';

% Get the values for one parameter (which_param) for the grid fit, search
% fit, and final fit for each of the two model types, css and linear
m = []; param = [];
for ii = 1:2
    m(ii).g=load(fullfile(dataDir, 'Gray', dataType,  sprintf('%s_%s-gFit', model_types{ii},ROI)));
    m(ii).s=load(fullfile(dataDir, 'Gray', dataType,  sprintf('%s_%s-sFit', model_types{ii}, ROI)));
    m(ii).f=load(fullfile(dataDir, 'Gray', dataType,  sprintf('%s_%s-fFit', model_types{ii}, ROI)));
    param(ii).g = rmGet(m(ii).g.model{1}, which_param);
    param(ii).s = rmGet(m(ii).s.model{1}, which_param);
    param(ii).f = rmGet(m(ii).f.model{1}, which_param);
    param(ii).var  = rmGet(m(ii).g.model{1}, 'varexp');
end

%% Compare the CSS fits and the linear fits
figure_name = sprintf('CSS v Linear %s',  which_param);
fH = figure; set(fH, 'name', figure_name)
indsAll = m(1).g.model{1}.roi.coordsIndex;
indsGood = param(1).var > .1;

subplot(2,2,1), hold on
scatter(param(1).g(indsAll),  param(2).g(indsAll)), xlabel(model_types{1}), ylabel(model_types{2}), title('GRID')
scatter(param(1).g(indsGood), param(2).g(indsGood), 'r')
xl = get(gca, 'XLim'); axis([xl xl]); plot(xl, xl, 'k-'), axis square

subplot(2,2,2), hold on
scatter(param(1).s(indsAll),  param(2).s(indsAll)), xlabel(model_types{1}), ylabel(model_types{2}), title('SEARCH')
scatter(param(1).s(indsGood), param(2).s(indsGood), 'r')
xl = get(gca, 'XLim'); axis([xl xl]); plot(xl, xl, 'k-'), axis square

subplot(2,2,3), hold on
scatter(param(1).f(indsAll),  param(2).f(indsAll)), xlabel(model_types{1}), ylabel(model_types{2}), title('FINAL')
scatter(param(1).f(indsGood), param(2).f(indsGood), 'r')
xl = get(gca, 'XLim'); axis([xl xl]); plot(xl, xl, 'k-'), axis square

% hgexport(fH, [figure_name '.eps']);

%% Plot the model parameter, comparing grid fit, search fit, and final fit for
% each of the two model types, css and linear
for ii = 1:2
    figure_name = sprintf('%s %s', model_types{ii}, which_param);
    fH = figure; set(fH, 'name', figure_name)
    indsAll = m(ii).g.model{1}.roi.coordsIndex;
    indsGood = param(ii).var > .1;
    
    subplot(2,2,1), hold on
    scatter(param(ii).g(indsAll), param(ii).s(indsAll)), xlabel('grid'), ylabel('search')
    scatter(param(ii).g(indsGood), param(ii).s(indsGood), 'r')
    xl = get(gca, 'XLim'); axis([xl xl]); plot(xl, xl, 'k-'), axis square
    
    subplot(2,2,2), hold on
    scatter(param(ii).g(indsAll), param(ii).f(indsAll)), xlabel('grid'), ylabel('final')
    scatter(param(ii).g(indsGood), param(ii).f(indsGood), 'r')
    xl = get(gca, 'XLim'); axis([xl xl]); plot(xl, xl, 'k-'), axis square
    
    subplot(2,2,3), hold on
    scatter(param(ii).s(indsAll), param(ii).f(indsAll)), xlabel('search'), ylabel('final')
    scatter(param(ii).s(indsGood), param(ii).f(indsGood), 'r')
    xl = get(gca, 'XLim'); axis([xl xl]); plot(xl, xl, 'k-'), axis square
    
    % hgexport(fH, [figure_name '.eps']);
end



%% Return
cd(curdir)