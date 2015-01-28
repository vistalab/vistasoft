function val = roiGet(roi,param,varargin)
%Get parameters from an ROI structure - not used much now, see comments
%
%    val = roiGet(roi,param,varargin)
%
%Examples:
%    val = roiGet(roi,'name');   
%
% See also:  roiCreate, roiSet.
%
% Right now all the ROI interactions are handled by the viewGet/Set
% routines.  This means we have to buy into the vw to deal with the ROI.  I
% think we should the roiGet/Set stuff running independently.  It could get
% called from viewGet/Set, but roiGet/Set should exist so when we are
% programming without a vw structure, we still can mainpulate the ROIs
% easily.  That's my opinion, and that's the truth.
%
% Wandell

val = [];
if notDefined('roi'), error('ROI required'); end
if notDefined('param'), error('PARAM required'); end

switch lower(param)
    case {'name'}
        val = roi.name;
    case {'color'}
        val = roi.color;
    otherwise
        error('Unknown parameter %s\n',param);
end

return;
