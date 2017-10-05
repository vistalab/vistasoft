function [model, vw] = applyGlmSlice(vw, slice, scans, params)
% Apply a General Linear Model to the time series for one slice of a view
%
% [model, vw] = applyGlmSlice(vw, [slice], [scans], [params])
% 
% The GLM uses a set of  event-related analysis parameters specified by 
% the user elsewhere (see er_editParams, er_setParams, er_defaultParams).
% This function returns a struct (model) with results of the GLM. 
%
% ras,  04/18/05.
if notDefined('vw')
    vw = getSelectedInplane;
    if isempty(vw),
        help(mfilename);
        return
    end
end

if ~exist('slice', 'var') || isempty(slice)
    slice = viewGet(vw, 'curSlice');
end

if ~exist('scans', 'var') || isempty(scans)    
    [scans, dt] = er_getScanGroup(vw);     
    vw = selectDataType(vw, dt);
end

if ~exist('params', 'var') || isempty(params)
    params = er_getParams(vw, scans(1));
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Grab useful parameters for easy access
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tr     = params.framePeriod;
trials = er_concatParfiles(vw, scans);
nConds = sum(trials.condNums>0);
nScans = length(scans);

if ~isfield(params, 'lowPassFilter'), params.lowPassFilter = 0; end

verbose = prefsVerboseCheck;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get Data Matrix Y
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Y = []; 

% get paraeters for time series processing from params
detrend = params.detrend;
ic = params.inhomoCorrect;
tn = params.temporalNormalization;
% no mean remove: if using spatial grad (inhomoCorrect==3), don't remove mean
if ic==3, nmr = 1; else nmr = 0; end

% load tSeries from selected slice
if verbose, hwait = mrvWaitbar(0, 'Loading tSeries...'); end
for s = 1:nScans
    vw = percentTSeries(vw, scans(s), slice, detrend, ic, tn, nmr);
    scanTSeries = viewGet(vw, 'tSeries');
    
    % JW: is it necessary to convert to single?
    % Y = [Y; single(scanTSeries)];
    Y = cat(1, Y, scanTSeries); clear scanTSeries;
    if verbose, mrvWaitbar(s/(nScans + params.lowPassFilter), hwait); end
end

dims = size(Y);
Y = reshape(Y, dims(1), []);

% apply low-pass filter if asked
% (TODO: replace with a more formal filtering method)
if params.lowPassFilter==1
    if verbose, mrvWaitbar(1, hwait, 'Low-Pass Filtering Time Series'); end
    for ii = 1:size(Y, 2)
        Y(:,ii) = imblur(Y(:,ii));
    end
end

if verbose, close(hwait); end

% remove NaNs
Y(isnan(Y)) = 0;

% this may cause a memory problem for huge #s of voxels, 
% but it's regrettably necessary:
Y = single(Y);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get Predictors Matrix X 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[X, nh, hrf] = glm_createDesMtx(trials, params, Y);

% count # of trials per predictor, for SEM estimates
trial_count = ones(1, size(X, 2));
for c = 1:nConds
    trial_count(c) = sum(trials.cond==c);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Apply the GLM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% test if we can do this in one large step, or break into smaller steps:
% for data matrices beyond a certain size, we'll break the GLM into several
% steps
if numel(Y) < 10^5
	% do it in one step
	model = glm(Y, X, tr, nh, params.glmWhiten, trial_count);
else
	% do it in a number of small steps
	stepSize = 1000; % this size will determine how fast we go
	
	for v = 1:stepSize:size(Y,2)
		% get voxel range
		I = (0:stepSize-1) + v;
		I = I(I <= size(Y,2) );
		
		if v==1
			model = glm(Y(:,I), X, tr, nh, params.glmWhiten, trial_count);
		else
			% model for this step
			tmp = glm(Y(:,I), X, tr, nh, params.glmWhiten, trial_count);
			
			% append to main model
			model.betas(:,:,I) = tmp.betas;
			model.residual(:,I) = tmp.residual;
			model.stdevs = cat(3, model.stdevs, tmp.stdevs);
			model.sems = cat(3, model.sems, tmp.sems);
		end
	end
end

model.hrf = hrf;

% get the proportion variance explained
% (b/c sometimes Y will have zero variance, e.g NaNs,  we explictly 
% deal with the 0-denominator case, and temp. disable warnings)
warning off MATLAB:divideByZero
model.varExplained = 1 - var(model.residual) ./ var(Y);
model.varExplained(isnan(model.varExplained) | isinf(model.varExplained)) = 0;
warning on MATLAB:divideByZero

% Note where the data came from in the glm result:
model.roiName = sprintf('Slice %s', num2str(slice));

% If we applied GLM to multiple slices, then reshape model solutions
if numel(dims) > 2
    whichfields = {'betas' 'residual' 'stdevs' 'sems' 'varExplained'};
    for ii= 1:length(whichfields)
        thisfield = whichfields{ii};
        oldsz = size(model.(thisfield));
        newsz = [oldsz(1:end-1) dims(2:3)];
        model.(thisfield) = reshape(model.(thisfield), newsz);
    end
end
return
