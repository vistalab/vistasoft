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
vw = mrVista('3') ; %initHiddenGray;
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
%vw = rmMain(vw, [], 'grid fit', 'model', {'css'}, 'matfilename', sprintf('css_%s', ROI));
vw = rmMain(vw, [], 'coarse to fine', 'model', {'css'}, 'matfilename', sprintf('css_%s', ROI));

%% Linear model
%    Define scan/stim and analysis parameters for linear model
params = rmDefineParameters(vw, 'model', {'onegaussian'});
params = rmMakeStimulus(params);
vw  = viewSet(vw,'rmParams',params);

%    Run the linear model
%vw = rmMain(vw, [], 'grid fit', 'model', {'onegaussian'}, 'matfilename', sprintf('onegaussian_%s', ROI));
vw = rmMain(vw, [], 'coarse to fine', 'model', {'onegaussian'}, 'matfilename', sprintf('onegaussian_%s', ROI));

%% Compare the linear and CSS models
model_type = {'css', 'onegaussian'};
which_param = 'varexp';

for ii = 1:2
    m(ii).g=load(fullfile(dataDir, 'Gray', dataType,  sprintf('%s_%s-gFit', model_type{ii},ROI)));
    m(ii).s=load(fullfile(dataDir, 'Gray', dataType,  sprintf('%s_%s-sFit', model_type{ii}, ROI)));
    m(ii).f=load(fullfile(dataDir, 'Gray', dataType,  sprintf('%s_%s-fFit', model_type{ii}, ROI)));
    param(ii).g = rmGet(m(ii).g.model{1}, which_param);
    param(ii).s = rmGet(m(ii).s.model{1}, which_param);
    param(ii).f = rmGet(m(ii).f.model{1}, which_param);
    param(ii).var  = rmGet(m(ii).g.model{1}, 'varexp');
end




% Plot it

for ii = 1:2
    figure_name = sprintf('%s %s', model_type{ii}, which_param);
    fH = figure(ii); clf, set(gcf, 'name', figure_name)
    inds = m(ii).g.model{1}.roi.coordsIndex;
    inds_good = param(ii).var > .1;
    
    subplot(2,2,1), hold on
    scatter(param(ii).g(inds), param(ii).s(inds)), xlabel('grid'), ylabel('search')
    scatter(param(ii).g(inds_good), param(ii).s(inds_good), 'r')
    xl = get(gca, 'XLim'); axis([xl xl]); plot(xl, xl, 'k-'), axis square
    
    subplot(2,2,2), hold on
    scatter(param(ii).g(inds), param(ii).f(inds)), xlabel('grid'), ylabel('final')
    scatter(param(ii).g(inds_good), param(ii).f(inds_good), 'r')
    xl = get(gca, 'XLim'); axis([xl xl]); plot(xl, xl, 'k-'), axis square
    
    subplot(2,2,3), hold on
    scatter(param(ii).s(inds), param(ii).f(inds)), xlabel('search'), ylabel('final')
    scatter(param(ii).s(inds_good), param(ii).f(inds_good), 'r')
    xl = get(gca, 'XLim'); axis([xl xl]); plot(xl, xl, 'k-'), axis square
    
    % hgexport(fH, [figure_name '.eps']);
end

figure_name = sprintf('CSS v Linear %s',  which_param);
fH = figure(3); clf, set(gcf, 'name', figure_name)
inds = m(1).g.model{1}.roi.coordsIndex;
inds_good = param(1).var > .1;

subplot(2,2,1), hold on
scatter(param(1).g(inds), param(2).g(inds)), xlabel(model_type{1}), ylabel(model_type{2}), title('GRID')
scatter(param(1).g(inds_good), param(2).g(inds_good), 'r')
xl = get(gca, 'XLim'); axis([xl xl]); plot(xl, xl, 'k-'), axis square


subplot(2,2,2), hold on
scatter(param(1).s(inds), param(2).s(inds)), xlabel(model_type{1}), ylabel(model_type{2}), title('SEARCH')
scatter(param(1).s(inds_good), param(2).s(inds_good), 'r')
xl = get(gca, 'XLim'); axis([xl xl]); plot(xl, xl, 'k-'), axis square

subplot(2,2,3), hold on
scatter(param(1).f(inds), param(2).f(inds)), xlabel(model_type{1}), ylabel(model_type{2}), title('FINAL')
scatter(param(1).f(inds_good), param(2).f(inds_good), 'r')
xl = get(gca, 'XLim'); axis([xl xl]); plot(xl, xl, 'k-'), axis square

% hgexport(fH, [figure_name '.eps']);