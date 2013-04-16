function s = sessionSet(s,param,val,varargin)
%Set mrSESSION parameter value
%
%   s = sessionSet(s,param,val,varargin)
%
% Examples:
%   mrSESSION = sessionSet(mrSESSION,'title','Retinotopy');
%   scan = 1;
%   mrSESSION = sessionSet(mrSESSION,'sliceOrder',[ 3 1 5 4 2],scan);
%

if notDefined('s'), error('mrSESSION variable required'); end
if notDefined('param'), error('Parameter field required.'); end
if ~exist('val','var'), error('Val required'); end

param = mrvParamFormat(param);

param = sessionMapParameterField(param);

switch param
    case 'alignment'
        s.alignment =val;
        
    case 'comments'
        s.comments = val;
        
    case 'description'
        s.description = val;
        
    case 'examnum'
        s.examNum = val;
        
    case 'functionals'
        % We can set either the entire functional structure or just one scan
        if isempty(varargin), s.functionals = val;
        else s.functionals(varargin{1}) = val;
        end
        
    case 'inplane'
        s.inplanes = val;
        % Information about the functional scans
        
    case 'inplanepath'
        s.inplanes.inplanePath = val;
        
    case {'nsamples','nframes'}
        if isempty(varargin), scan = 1;
        else                  scan = varargin{1};
        end
        s.functionals(scan).nFrames = val;
        
    case 'screensavesize'
        s.screenSaveSize = val;
        
    case 'sessioncode'
        s.sessionCode = val;
        
    case 'sliceorder'
        if isempty(varargin), scan = 1;
        else scan = varargin{1};
        end
        s.functionals(scan).sliceOrder = val;
        
    case 'subject'
        s.subject = val;
        
    case 'title'
        s.title = val;
        
    otherwise
        error('Unknown parameter %s\n',param);
        
end

return;
