function parPath = er_deconvolvedParfile(view, stim, params);
%
% parPath = er_deconvolvedParfile(view, <stim>, <params>);
%
% Create a parfile representing the deconvolved time courses
% from a GLM. The format the data are stored in is alternating
% beta values and residual variance from the GLM, each taking
% [nh] time points, where nh is the number of temporal frames in the
% estimated hemodynamic response. (This should correspond to the number of
% MR frames contained within the event-related 'timeWindow' parameter.
%
% stim: stim/'trials' struct loaded from er_concatParfiles for the 
%       source scans from the deconvolution.
% params: event-related parameters from the source scans for the 
%       deconvolution. 
% <default: get stim / params from the view's current scan group.>
%
% ras, 02/2006.
if notDefined('view'),      view = getSelectedInplane;          end
if notDefined('stim'),      stim = er_concatParfiles(view);     end
if notDefined('params'),    params = er_getParams(view);        end

tr = params.framePeriod;
frameWindow = unique(round(params.timeWindow/tr));
nh = length(frameWindow);
nConds = sum(stim.condNums>=1);

% construct the par struct 
par.cond = [1:nConds 0];
par.onset = 0:2*nh:2*nh*nConds;
par.label = stim.condNames([2:nConds+1 1]);
par.color = stim.condColors([2:nConds+1 1]);
        
% write out the parfile
mrGlobals
dt = existDataType('Deconvolved');
if dt==0, 
    scan = 1;
else
    scan = length(dataTYPES(dt).scanParams); % assume last deconvolved scan
end
parFileName = sprintf('deconvolved_scan%i.par', scan);
parPath = fullfile(parfilesDir(view), parFileName);
writeParfile(par, parPath);

return