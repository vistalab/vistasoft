function model = applyGlmROI(view,roi,scans,params);
%
% model = applyGlmROI(view,[roi],[scans],[params]);
% 
% Apply a General Linear Model to the time series
% within an ROI, for the selected scans and
% event-related analysis parameters.
% 
% ROI can be specified as a name, index into the 
% loaded ROIs of the view, or ROI struct. If omitted
% the view's selected ROI will be used.
%
% scans defaults to the scan group assigned to the
% current scan. See er_groupScans.
%
% params defaults to the event-related analysis params
% for the current scan. See er_getParams.
% 
% Returns a model struct with results of the GLM.
%
% ras, 04/18/05.
if ieNotDefined('view')
    view = getSelectedInplane;
    if isempty(view)
        help(mfilename);
        return
    end
end

if ieNotDefined('scans')
    scans = er_getScanGroup(view);
end

if ieNotDefined('params')
    params = er_getParams(view,scans(1));
end

if ieNotDefined('roi')
    roi = viewGet(view,'selectedRoi');
end

roi = tc_roiStruct(view,roi);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Grab useful parameters for easy access
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tr = params.framePeriod;
trials = er_concatParfiles(view,scans);
nConds = sum(trials.condNums>0);
nScans = length(scans);
for s = 1:nScans
	framesPerRun(s) = numFrames(view,scans(s));
end
nFrames = max(framesPerRun);
nVoxels = size(roi.coords,2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get Data Matrix Y
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% initialize Y matrix
Y = []; %repmat(NaN,[nFrames nVoxels nScans]);

% get voxel data from ROI:
for s = 1:nScans
    data = er_voxelData(view,roi,scans(s));
    
    % this code
    % mimics what er_selxavg does:
    off_est = repmat(mean(data.tSeries),[size(data.tSeries,1) 1]);
    data.tSeries = removeBaseline2(data.tSeries,60/tr) + off_est;
    
    Y = [Y; data.tSeries];
end

% this may cause a memory problem for huge #s of voxels,
% but it's regrettably necessary:
Y = double(Y);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get Predictors Matrix X 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[X, nh, hrf] = glm_createDesMtx(trials,params,Y,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Apply the GLM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
model = glm(Y,X,tr,nh);

model.hrf = hrf;

% Note where the data came from in the glm result:
model.roiName = roi.name;


return
