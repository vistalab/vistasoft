function dt = dtSet(dt,param,val,varargin)
% Set value from dataTYPES structure
%
%   dt = dtSet(dt,param,val,varargin)
%
% dataTYPES is a global structure, paralleling mrSESSION in some ways. The
% dataTYPES structure contains a great deal of information about the scans.
% This information includes scanning parameters as well as specific
% features about the timing and analysis in the individual scans.
%
% The basic layout of the dataTYPES is
%
%                      name: 'Original'
%                scanParams: [1x1 struct]
%     blockedAnalysisParams: [1x1 struct]
%       eventAnalysisParams: [1x1 struct]
%     retinotopyModelParams: [1x1 struct]  (Optional)
%

if notDefined('dt'), error('dataTYPES parameter required'); end
if notDefined('param'), error('param required'); end

% This can be empty, but it must be there
if ~exist('val','var'), error('val required'); end

param = mrvParamFormat(param);

switch param
    case {'annotation'}
        % dt = dtSet(dt,'annotation',description,scan)
        if isempty(varargin), dt.scanParams(:).annotation = val;
        else dt.scanParams(varargin{1}).annotation = val;
        end
        
    case {'blockedanalysisparams','blockparams','bparams'}
        %dt.blockedAnalysisParams = val;
        if isempty(varargin), dt.blockedAnalysisParams = val;
        else dt.blockedAnalysisParams(varargin{1}) = val;
        end
        
    case {'eventanalysisparams','eventparams','eparams'}
        %dt.eventAnalysisParams = val;
        if isempty(varargin), dt.eventAnalysisParams = val;
        else dt.eventAnalysisParams(varargin{1}) = val;
        end
        
        % Retinotopy model parameter
        
    case {'name'}
        dt.name = val;
        
    case {'nframes'}
        % dt = dtSet(dt,'nFrames',128,scan)
        if isempty(varargin), dt.scanParams(:).nFrames = val;
        else dt.scanParams(varargin{1}).nFrames = val;
        end
        
    case {'rmstimparams','retinomodelparams','retinotopymodelstimulusparams','rmparams','retinotopymodelparams'}
        % dtSet(dt,'rmStimParams',v,scan);
        % Unfortunately, this slot is only the stim params, although it is
        % named as the full rm params. We can rename the slot after the
        % other code is broadly under control (everyone using dtSet's) by
        % changing things in here. - BW
        if isempty(varargin),dt.retinotopyModelParams = val;
        else dt.retinotopyModelParams(varargin{1}) = val;
        end
        
    case {'scanparams'}
        % Scan params
        if isempty(varargin), dt.scanParams = val;
        else dt.scanParams(varargin{1}) = val;
        end
        
    otherwise
        error('Unknown parameter %s\n',param);
        
end


return;
