function params = rmRecomputeParams(view, params, allTimePoints)
% Retrieve retinotopy model parameters for prediction analyses,
% recomputing if needed.
%
%  params = rmRecomputeParams([view=cur view], [params], [allTimePoints=0]);
%
% INPUTS:
%   view: mrVista view structure.
%   params: pre-defined retinotopy model params, if any. (optional; will
%           get from view if omitted).
%   allTimePoints: flag for whether the recomputed params should reflect
%           the full stimulus sequence for each scan, or only a single
%           unique repetition. [default 0]
%
% OUTPUTS:
%   a params struct with 
%
%
% ras, 12/2006.
if notDefined('view'),              view = getCurView;              end
if notDefined('allTimePoints'),     allTimePoints = false;          end
if notDefined('params'),    
    % check if they are loaded
    try
        params = viewGet(view, 'rmParams');
    catch
        params = [];
    end;
end

% remake stimulus?
remakeStimulus = false;

% have to have params struct
if isempty(params),
    params = rmDefineParameters(view);
    remakeStimulus = true;
end

% if allTimePoints == 1 and if any of the params.stim(n).nUniqueRep>1, 
% then we should reset and remake params struct.
if allTimePoints && any([params.stim(:).nUniqueRep]-1),
    for n=1:length(params.stim),
        params.stim(n).nUniqueRep = 1;
    end;
    remakeStimulus = true;
end;

% one final check if we need to recompute: does the sampling grid
% (in params.analysis.X and Y) accurately reflect the image data?
if numel(params.stim(1).instimwindow) > numel(params.analysis.X) || ...
	numel(params.stim(1).instimwindow) > numel(params.analysis.Y)	
	remakeStimulus = true;
end

% % Making them is quite fast so perhaps we should always to that.
% params = [];
% ras, 12/06: the concern with always re-making it is that we may
% update the parameters in the StimulusDefinitions/ directory after
% we've run a model (e.g., if we change our scanning type). In this
% case, we'd want to use the parameters that were saved when the model
% was trained, or else we may get a bad mismatch.
% Now we only remake if we have to.
if remakeStimulus,
    fprintf(1,'[%s]:WARNING:Need to remake the stimulus.\n',mfilename);
	
    params = rmMakeStimulus(params);
end;

return
