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

%TODO: Add a sessionSet variable for each of the variables previously
%discussed: inplane.strPath, functionals.strPath, vAnatomy.strPath

if notDefined('s'), error('mrSESSION variable required'); end
if notDefined('param'), error('Parameter field required.'); end
if ~exist('val','var'), error('Val required'); end
ps -ef | grep parcel
%TODO: add param scrubbing code

param = mrvParamFormat(param);

param = sessionMapParameterField(param);

switch param

    case 'title'
        s.title = val;
    case 'subject'
        s.subject = val;
    case 'examnum'
        s.examNum = val;

    case 'screensavesize'
        s.screenSaveSize = val;
    case 'alignment'
        s.alignment =val;

    case 'sessioncode'
        s.sessionCode = val;
    case 'description'
        s.description = val;
    case 'comments'
        s.comments = val;
    case 'inplanepath'
        s.inplanes.path = val;
        

    % Information about the functional scans
    case 'functionals'
        % The entire functional structure is set here.
        s.functionals = val;

    % More functional parameters should be entered here.  Lots of
    % parameters are still left out and addressed badly in the code.
    case 'sliceorder'
        if isempty(varargin), scan = 1;
        else scan = varargin{1};
        end
        s.functionals(scan).sliceOrder = val;
    case {'nsamples','nframes'}
        if isempty(varargin), scan = 1;
        else                  scan = varargin{1};
        end
        s.functionals(scan).nFrames = val;
        
    otherwise
        error('Unknown parameter %s\n',param);

end

return;
