function ni = niftiSet(ni,param,val,varargin)
% Set data for various nifti data structures
%

if notDefined('ni'), error('Nifti data structure variable required'); end
if notDefined('param'), error('Parameter field required.'); end
if ~exist('val','var'), error('Val required'); end

param = mrvParamFormat(param);

%TODO: Add a nifti paramaterMapField

switch param
    case 'data'
        ni.data = val;
    case 'dim'
        ni.dim = val;
    case 'filepath'
        ni.fname = val;
    case 'freqdim'
        ni.freq_dim = val;
    case 'nifti'
        ni = val; %This means that we are passing in an entire Nifti!
    case 'phasedim'
        ni.phase_dim = val;
    case 'pixdim'
        ni.pixdim = val;
	case 'qfac'
        ni.qfac= val;
    case 'qform_code'
        ni.qform_code = val;
	case 'qoffset_x'
        ni.qoffset_x = val;
	case 'qoffset_y'
        ni.qoffset_y = val;
	case 'qoffset_z'
        ni.qoffset_z = val;
    case 'qto_ijk'
        ni.qto_ijk = val;
    case 'qto_xyz'
        ni.qto_xyz = val;
	case 'quatern_b'
        ni.quatern_b = val;
	case 'quatern_c'
        ni.quatern_c = val;
	case 'quatern_d'
        ni.quatern_d = val;    
    case 'slicedim'
        ni.slice_dim = val;
    case 'sto_ijk'
        ni.sto_ijk = val;
    case 'sto_xyz'
        ni.sto_xyz = val;
	case 'voxelsize'
        ni.voxelSize = val;
    otherwise
        warning('vista:nifti:niftiSet', 'The parameter supplied does not exist. Returning without change.');
        return
end %switch

return
