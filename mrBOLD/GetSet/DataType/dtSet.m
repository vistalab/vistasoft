function dt = dtSet(dt,param,val,varargin)
% Set value in the dataTYPES structure
%
%   dt = dtSet(dt,param,val,varargin)
%
% USAGE
%  val = dtGet(dataTYPES(1),'atype',newValue);
%
% INPUTS
%  dataTYPES struct - one member of the dataTYPES struct array
%  param - String parameter specifying the value to set
%  val - The new value that will be set
%
% RETURNS
%  Value (or values) stored in dataTYPES or calculated from values stored
%  in dataTYPES
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
        
	case {'inplanepath'}
        % dt = dtSet(dt,'nFrames','/tmp/inplanepath.nii.gz/',scan)
        if isempty(varargin), dt.scanParams(:).inplanePath = val;
        else dt.scanParams(varargin{1}).inplanePath = val;
        end
        
    case {'keepframes'}
        % dt = dtSet(dt,'nFrames',[1 -1],scan)
        if isempty(varargin), dt.scanParams(:).keepFrames = val;
        else dt.scanParams(varargin{1}).keepFrames = val;
        end
        
    case {'name'}
        dt.name = val;
        
    case {'nframes'}
        % dt = dtSet(dt,'nFrames',128,scan)
        if isempty(varargin), dt.scanParams(:).nFrames = val;
        else dt.scanParams(varargin{1}).nFrames = val;
        end
        
    case {'tr' 'framedur' 'frameduration' 'frameperiod'}
        % dt = dtSet(dt,'tr',1.5,scan)
        if isempty(varargin), dt.scanParams(:).framePeriod = val;
        else dt.scanParams(varargin{1}).framePeriod = val;
        end
        
        
    case {'withinscanmotion'}
        % nFrames = dtGet(dt, 'nFrames', scan);
        % dt = dtSet(dt,'withinscanmotion',randn(2, nFrames), scan)
        if isempty(varargin), dt.scanParams(:).WithinScanMotion = val;
        else dt.scanParams(varargin{1}).WithinScanMotion = val;
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
        
    case {'size'}
        % dt = dtSet(dt,'nFrames',128,scan)
        if isempty(varargin), dt.scanParams(:).cropSize = val;
        else dt.scanParams(varargin{1}).cropSize = val;
        end

    otherwise
        error('Unknown parameter %s\n',param);
        
end


return;
