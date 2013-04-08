function val = dtGet(dt,param,varargin)
% Get value from dataTYPES structure
%
%   val = dtGet(dt,param,varargin)
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
%
% Examples
%   global dataTYPES
%   dt = dataTYPES;
%   b = dtGet(dt,'bParams')
%   e = dtGet(dt,'eParams')
%   aType = dtGet(dt,'aType',1)

if notDefined('dt'),    error('dataTYPES parameter required'); end
if notDefined('param'), error('param required'); end
val = [];       % Default

param = mrvParamFormat(param);

switch param
    case 'name'
        val = dt.name;
    case 'annotation'
        % dtGet(dt,'annotation',scan)
        if isempty(varargin), val = dt.scanParams;
        else val = dt.scanParams(varargin{1}).annotation;
        end
    case 'scanparams'
        % dtGet(dt,'scanParams',scan)
        if isempty(varargin), val = dt.scanParams;
        else val = dt.scanParams(varargin{1});
        end
    case {'rmparams','retinomodelparams','retinotopymodelparams'}
        % dtGet(dt,'scanParams',scan)
        if checkfields(dt,'retinotopyModelParams')
            if isempty(varargin), val = dt.retinotopyModelParams;
            else val = dt.retinotopyModelParams(varargin{1});
            end
        end
    case {'funcsize','inplanesize'}
        % dtGet(dt,'funcSize',[scan]);
        % We assume all the crop sizes are the same as the first.
        if isempty(varargin),
            val = zeros(dtGet(dt,'nscans'),2);
            for ii=1:length(dt.scanParams)
                val(ii,:) = dt.scanParams(ii).cropSize;
            end
        else
            val = dt.scanParams(varargin{1}).cropSize;
        end
    case {'nscans'}
        val = length(dt.scanParams);
        
    case {'blockedanalysisparams','blockparams','bparams','bparms'}
        % dtGet(dt,'blockParams',scan)
        if isempty(varargin), val = dt.blockedAnalysisParams;
        else val = dt.blockedAnalysisParams(varargin{1});
        end
    case {'eventanalysisparams','eventparams','eparams','eparms'}
        % dtGet(dt,'eventParams',scan)
        if isempty(varargin), val = dt.eventAnalysisParams;
        else val = dt.eventAnalysisParams(varargin{1});
        end
        
        % Which analysis type for a specific scan
    case {'analysistype','atype','eventorblock'}
        % dtGet(dt,'aType',scan)
        % The logic of the scan type is broken because the structure is set
        % so that conflicting values can arise.  This should be changed in
        % the representation, and then we can fix this code.
        if isempty(varargin{1}), error('Scan parameter required');
        else scan = varargin{1};
        end

        if isfield(dt,'blockedAnalysisParams')
            bParms = dtGet(dt,'bparams',scan);
            if checkfields(bParms,'blockedAnalysis') && bParms.blockedAnalysis
                val = 'block';
            end
        end

        if isfield(dt,'eventAnalysisParams')
            eParms = dtGet(dt,'eparams',scan);
            if checkfields(eParms,'eventAnalysis') && eParms.eventAnalysis
                val = 'event';
            end
        end

        if isempty(val)
            val = 'block';
            warning('Neither blocked nor event analysis set! Re-run mrInitRet');
        end
        
    case {'nframes'}
        % dtGet(dt,'nframes',scan)
        % dtGet(dt,'nframes',scan,vw)
        if isempty(varargin), error('Scan field required'); end
        val = dt.scanParams(varargin{1}).nFrames;
    case {'smoothframes'}
        % dtGet(dt,'smoothFrames',scan)
        % dtGet(dt,'smoothFrames',scan,vw)  % For block analysis
        scan = varargin{1};
        aType = dtGet(dt,'eventOrBlock',scan);
        switch aType
            case 'event'
                val = dt.eventAnalysisParams(scan).detrendFrames;
            case 'block'
                if length(varargin) < 2, error('smooth frames block'); end
                vw = varargin{2};
                nCycles = viewGet(vw,'num cycles', scan);
                nFrames = viewGet(vw, 'numFrames',scan);
                val = ceil(nFrames / nCycles);
            otherwise
                error('Unknown analysis %s\n',aType);
        end

    otherwise
        error('Unknown parameter %s\n',param);
end


return;
