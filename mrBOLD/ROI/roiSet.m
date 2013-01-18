function roi = roiSet(roi,param,val,varargin)
%Set ROI parameters
%
%   roi = roiSet(roi,'param',varargin)
%
% Wandell

if notDefined('roi'), error('ROI required'); end
if notDefined('param'), error('Param required'); end
if ~exist('val','var'), error('Value required'); end  % Can be empty

switch lower(param)
    case {'name'}
        roi.name = val;
	case {'color'}
		roi.color = val;
    otherwise
end

return;
