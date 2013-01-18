function val = roiGet(roi,'param',varargin)
%Get parameters from an ROI structure
%
%    val = roiGet(roi,'param',varargin)
%
%Examples:
%    val = roiGet(roi,'name');   
%    
% Wandell

val = [];
if notDefined('roi'), error('ROI required'); end
if notDefined('param'), error('PARAM required'); end

switch lower(param)
    case {'name'}
        val = roi.name;
    otherwise
end

return;
