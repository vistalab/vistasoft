function M = rmPlotGUI_getModel(view, roi, allTimePoints, preserveCoords)
% retrieve the model data for the specified retinotopy model, in a struct M.
%
%  M = rmPlotGUI_getModel(view, roi, allTimePoints, [preserveCoords])
%
% The M structure will reside as the GUI's UserData, and contain a compact
% description of both the model and the current state of the GUI. I broke
% off the accessor function, in case anyone wants to try to do command-line
% analyses.
%
% ras, 11/2008; broken off into its own function.
if notDefined('preserveCoords'), preserveCoords = 1;                end

% load file with data
rmFile = viewGet(view, 'rmFile');
if isempty(rmFile),
    fprintf('[%s]:No file selected\n', mfilename);
    return;
end;

% load model
try   
    model = viewGet(view, 'rmModel'); 
catch
    model = []; 
end;
if isempty(model),    
    load(viewGet(view, 'rmFile'), 'model');
    view  = viewSet(view, 'rmModel', model);
    model = viewGet(view, 'rmModel');
end;

% load params
try
    params = viewGet(view, 'rmParams');
catch
    params = [];
end;
params = rmRecomputeParams(view, params, allTimePoints);

modelNames = viewGet(view, 'rmModelNames');

% initialize the M struct with obvious fields
M.roi = roi;
M.model    = model;
M.modelNum = 1;
M.params = params;
M.modelNames = modelNames;
M.dataType = getDataTypeName(view);
M.viewType = view.viewType;

M.prevVoxel = 1;  % this keeps track of the last selected voxel, to detect changes

% get time series and roi-coords
[M.tSeries, M.coords, M.params] = rmLoadTSeries(view, params, roi, preserveCoords);

% detrend
% get/make trends
verbose = false;
trends  = rmMakeTrends(params);
%if isfield(M.params.analysis,'allnuisance')
%    trends = [trends M.params.analysis.allnuisance];
%end

% recompute
b = pinv(trends)*M.tSeries;
M.tSeries = M.tSeries - trends*b;
nt = size(trends,2);


% make x-axis for time series plot
nFramesInd = [M.params.stim(:).nFrames]./[M.params.stim(:).nUniqueRep];
TR = [M.params.stim(:).framePeriod];
nScans = length(M.params.stim);

x = (0:nFramesInd(1)-1)'.*TR(1);
for n=2:nScans,
    timend = x(end);
    % For scans 2:end, we need to start the indexing at 1, not 0, otherwise
    % the first time point of scan 2 and the last time point of scan 1 will
    % have the same x value. We do not want this.
    % x = [x; ((0:nFramesInd(n)-1)'.*TR(n))+timend]; 
    x = [x; ((1:nFramesInd(n))'.*TR(n))+timend];

end;
% this does not give the correct separator locations between scans
% M.sepx = cumsum(nFramesInd-1) .* TR;
% rather we want this:
M.sepx = (cumsum(nFramesInd)-1) .* TR;
M.x    = x;

return;


%% if we got here, we haven't changed the voxel: 
% we can adjust the rfParams, *if* the option is selected...

% test whether the 'adjust PRF' option is selected
if isequal( get(M.ui.movePRF, 'Checked'), 'on' )
	% either manually move the pRF according to slider values...
	mrvSliderSet(M.ui.moveX, 'Visible', 'on');
    mrvSliderSet(M.ui.moveY, 'Visible', 'on');
	mrvSliderSet(M.ui.moveSigma, 'Visible', 'on');
    rfParams(1) = get(M.ui.moveX.sliderHandle, 'Value');
    rfParams(2) = get(M.ui.moveY.sliderHandle, 'Value');
	rfParams(3) = get(M.ui.moveSigma.sliderHandle, 'Value');
	rfParams(5) = rfParams(3);   % circular case
	
else
	% ... or use stored values  (and keep the sliders hidden)
    mrvSliderSet(M.ui.moveX, 'Visible', 'off');
    mrvSliderSet(M.ui.moveY, 'Visible', 'off');
    mrvSliderSet(M.ui.moveSigma, 'Visible', 'off');

end

return
