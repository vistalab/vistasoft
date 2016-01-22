function val = dtGet(dt,param,varargin)
% Get value from dataTYPES structure
%
%   val = dtGet(dt,param,varargin)
%
% USAGE
%  val = dtGet(dataTYPES(1),'atype');
%
% INPUTS
%  dataTYPES struct - one member of the dataTYPES struct array
%  param - String parameter specifying the value to get 
%
% RETURNS
%  Value (or values) stored in dataTYPES or calculated from values stored
%  in dataTYPES
%
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
%
%
%
% Copyright Stanford VistaLab 2013

if notDefined('dt'),    error('dataTYPES parameter required'); end
if notDefined('param'), error('param required'); end
val = [];       % Default

param = mrvParamFormat(param);
%TODO: Add a mapParameterField here

switch param
    case {'analysistype','atype','eventorblock'}
        % Which analysis type for a specific scan
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
        
    case {'annotation'}
        if checkfields(dt,'scanParams','annotation')
            if isempty(varargin), val = dt.scanParams(:).annotation;
            else val = dt.scanParams(varargin{1}).annotation;
            end
        else
           val = '(Empty Data Type)';
        end
        
    case {'blockedanalysisparams','blockparams','bparams','bparms'}
        % dtGet(dt,'blockParams',scan)
        if isempty(varargin), val = dt.blockedAnalysisParams;
        else val = dt.blockedAnalysisParams(varargin{1});
        end
        
    case {'cropsize'}
        if checkfields(dt,'scanParams','cropSize')
            if isempty(varargin), val = dt.scanParams(:).cropSize;
            else val = dt.scanParams(varargin{1}).cropSize;
            end
        end
        
    case {'eventanalysisparams','eventparams','eparams','eparms'}
        % dtGet(dt,'eventParams',scan)
        if isempty(varargin), val = dt.eventAnalysisParams;
        else val = dt.eventAnalysisParams(varargin{1});
        end
        
        
    case {'frameperiod'}
        if checkfields(dt,'scanParams','framePeriod')
            if isempty(varargin), val = dt.scanParams(:).framePeriod;
            else val = dt.scanParams(varargin{1}).framePeriod;
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
        
    case {'inplanepath'}
        if checkfields(dt,'scanParams','inplanePath')
            if isempty(varargin), val = dt.scanParams(:).inplanePath;
            else val = dt.scanParams(varargin{1}).inplanePath;
            end
        elseif checkfields(dt,'scanParams','PfileName')
            if isempty(varargin), val = dt.scanParams(:).PfileName;
            else val = dt.scanParams(varargin{1}).PfileName;
            end
        else warning('This parameter: %s, was not found in the datatype.',param);
        end
        
    case {'keepframes'}
        if checkfields(dt,'scanParams','keepFrames')
            if isempty(varargin), val = dt.scanParams(:).keepFrames;
            else val = dt.scanParams(varargin{1}).keepFrames;
            end
        end
        
    case {'name'}
        val = dt.name;
        
    case {'nframes'}
        % dtGet(dt,'nframes',scan);
        % dtGet(dt,'nframes');
        if checkfields(dt,'scanParams','nFrames')
            if isempty(varargin), val = dt.scanParams(:).nFrames;
            else val = dt.scanParams(varargin{1}).nFrames;
            end
        end
        
        %Now we need to apply keepFrames to this number
        
    case {'withinscanmotion'}
        % dtGet(dt, 'within scan motion')
        % dtGet(dt, 'within scan motion', scan)
        if checkfields(dt,'scanParams','WithinScanMotion')
            if isempty(varargin), val = dt.scanParams(:).WithinScanMotion;
            else val = dt.scanParams(varargin{1}).WithinScanMotion;
            end
        end   
        
    case {'nscans'}
        val = length(dt.scanParams);
        
    case {'nslices'}
        tmpVal = dtGet(dt,'Slices');
        val = length(tmpVal);
        
    case {'parfile'}
        if checkfields(dt,'scanParams','parfile')
            if isempty(varargin), val = dt.scanParams(:).parfile;
            else val = dt.scanParams(varargin{1}).parfile;
            end
        end
        
    case {'pfilename'}
        if checkfields(dt,'scanParams','PfileName')
            if isempty(varargin), val = dt.scanParams(:).PfileName;
            else val = dt.scanParams(varargin{1}).PfileName;
            end
        end
        
    case {'rmparams','retinomodelparams','retinotopymodelparams'}
        if checkfields(dt,'retinotopyModelParams')
            if isempty(varargin), val = dt.retinotopyModelParams;
            elseif length(dt.retinotopyModelParams) >= varargin{1},
                val = dt.retinotopyModelParams(varargin{1});
            else val = [];
            end
        end
        
    case {'scanparams'}
        % dtGet(dt,'scanParams',scan)
        if checkfields(dt,'scanParams')
            if isempty(varargin), val = dt.scanParams;
            else val = dt.scanParams(varargin{1});
            end
        end
        
    case {'slices'}
        if checkfields(dt,'scanParams','slices')
            if isempty(varargin), val = dt.scanParams(:).slices;
            else val = dt.scanParams(varargin{1}).slices;
            end
        end
        
    case {'smoothframes'}
        % dtGet(dt,'smoothFrames',scan)
        % dtGet(dt,'smoothFrames',scan,vw)  % For block analysis
        scan = varargin{1};
        aType = dtGet(dt,'eventOrBlock',scan);
        if strcmp(aType,'event')
            val = dt.eventAnalysisParams(scan).detrendFrames;
        elseif strcmp(aType,'block')
            if length(varargin) < 2, error('smooth frames block'); end
            vw = varargin{2};
            nCycles = viewGet(vw,'num cycles', scan);
            nFrames = viewGet(vw, 'numFrames',scan);
            val = ceil(nFrames / nCycles);
        else
            error('Unknown analysis %s\n',aType);
        end
        
        
    otherwise
        error('Unknown parameter %s\n',param);
        
end


return;
