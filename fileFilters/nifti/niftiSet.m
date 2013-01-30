function ni = niftiSet(ni,param,val,varargin)
% Set data for various nifti data structures
%

if notDefined('ni'), error('Nifti data structure variable required'); end
if notDefined('param'), error('Parameter field required.'); end
if ~exist('val','var'), error('Val required'); end

param = mrvParamFormat(param);

%TODO: Add a nifti paramaterMapField

switch param
    case 'voxelsize'
        ni.voxelSize = val;
    case 'filepath'
        ni.fname = val;


end %switch



return
