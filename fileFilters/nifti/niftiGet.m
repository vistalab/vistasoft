function val = niftiGet(ni,param,varargin)
% Get data from various nifti data structures
%

if notDefined('ni'), error('Nifti data structure variable required'); end
if notDefined('param'), error('Parameter field required.'); end

param = mrvParamFormat(param);

%TODO: Add a nifti paramaterMapField

val = [];

switch param
    case 'voxelsize'
        if isfield(ni, 'voxelSize'), val = ni.voxel_size; end
    case 'pixdim'
        if isfield(ni, 'voxelSize'), val = ni.pixdim; end

        
    otherwise
        error('Unknown parameter %s\n',param);
        
end %switch



return
