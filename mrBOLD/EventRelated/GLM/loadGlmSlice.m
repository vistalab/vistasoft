function [model, params] = loadGlmSlice(view,slice,scan);
%
% [model, params] = loadGlmSlice(view,[slice,scan]);
% 
% Load the results of a General Linear Model applied to
% mrVista data. Returns an analysis model and the event-related
% parameters used in the model.
%
% The format of the saved file may vary depending
% on how we decide to minimize the footprint of each
% analysis (omitting some fields of the analysis
% which can be easily recomputed on the fly, and 
% maybe changing data types), but in general they'll
% be saved in the following place:
% 
% [sessionDir]/[viewType]/[dtName]/Scan[#]/glmSlice[#].mat
% 
% E.g.:
% 020405ras/Inplane/GLMs/Scan1/glmSlice1.mat
%
%
% ras 06/06.
if ~exist('slice','var') | isempty(slice)
    slice = viewGet(view,'curSlice');
end

if ~exist('scan','var') | isempty(scan)
    scan = viewGet(view,'curScan');
end

%% Get path for saved data 
modelPath = fullfile(dataDir(view),['Scan' num2str(scan)],...
                             ['glmSlice' num2str(slice) '.mat']);

%% Load model
model = load(modelPath);

% starting 02/21/07, I save the betas as single instead of int16
% (avoids some roundoff error). So, if they're single, we just
% need to recommpute the SEMs matrix and that's it. If they're int,
% we do the rescaling we did before (but use normalize, which is what
% we should have done all along):
if isfield(model, 'rng') & isinteger(model.betas)
	fields = fieldnames(model.rng);
	for i = 1:length(fields)
		lo = model.rng.(fields{i})(1);
		hi = model.rng.(fields{i})(2);
		model.(fields{i}) = double(normalize(model.(fields{i}), lo, hi));
	end
end

% recompute SEMs
model.trial_count = glm_trial_count(model.designMatrix, model.nh);
tmp = repmat(model.trial_count(:)',[model.nh 1 size(model.betas,3)]);
warning off MATLAB:divideByZero
model.sems = model.stdevs ./ sqrt(tmp-1);
warning on MATLAB:divideByZero


if nargout>1
    mrGlobals;
    params = dataTYPES(viewGet(view,'curdt')).eventAnalysisParams(scan);
end

return