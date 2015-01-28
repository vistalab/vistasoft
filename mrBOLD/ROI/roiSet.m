function roi = roiSet(roi,param,val,varargin)
%Set ROI parameters - not used much now, see comments

%
%   roi = roiSet(roi,'param',varargin)
%
% Examples:
%
% See also:  roiCreate, roiGet
% Wandell

if notDefined('roi'), error('ROI required'); end
if notDefined('param'), error('Param required'); end
if ~exist('val','var'), error('Value required'); end  % Can be empty

% Remove spaces and upper case from the parameter
param = mrvParamFormat(param);

switch lower(param)
    case {'name'}
        roi.name = val;
	case {'color'}
		roi.color = val;
    case {'coords'}
        roi.coords = val;
    case {'comments'}
        roi.comments = val;
    otherwise
        error('Unknown roi parameter %s\n');
end


return;
