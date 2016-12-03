function nii = niftiVista2ni(niiv)
% Transforms a VISTASOFT nifti structure to a NIFTI-1 structure.
%
% nii = niftiVista2ni(niiv)
%
% INPUT
%  niiv - Old VISTASOFT nifti-1 structure
%
% OUTPUTS:
%   nii - nifti-1 structure
%
% Web Resources:
%   mrvBrowseSVN('niftiVista2ni')
%
% Example:
%   nii = make_nii(ones(256,256,80))
%   
% (c) Stanford Vista 2012

% Get NIFTI-1 the data type from the data type of the data field in the
% structure.
voxel_siz  = diag(niiv.qto_xyz(1:3,1:3));
originator = niiv.qto_ijk(1:3,end);
data_type  = niftiClass2DataType(class(niiv.data));
nii        = make_nii(niiv.data,voxel_siz,originator,data_type);

% hdr fields.
% --- dime field.
nii.hdr.dime.pixdim(2:niiv.ndim+1) = niiv.pixdim;
nii.hdr.dime.scl_slope           = niiv.scl_slope;
nii.hdr.dime.scl_inter           = niiv.scl_inter;
nii.hdr.dime.cal_min             = niiv.cal_min;
nii.hdr.dime.cal_max             = niiv.cal_max;
nii.hdr.dime.slice_code          = niiv.slice_code;
nii.hdr.dime.slice_start         = niiv.slice_start;
nii.hdr.dime.slice_end           = niiv.slice_end;
nii.hdr.dime.slice_duration      = niiv.slice_duration;
nii.hdr.dime.toffset             = niiv.toffset;

% XYZ units
switch lower(niiv.xyz_units)
    case 'microns', xyzscale = 3;
    case 'mm',      xyzscale = 2;
    case 'm',       xyzscale = 1;
    otherwise, error('XYZ units cannot be determined');
end

switch lower(niiv.time_units)
    case {'s' 'seconds' 'sec'},        tscale = 8;
    case {'msec' 'millseconds' 'ms'},  tscale = 16;
    case {'microsec' 'microseconds' 'us' 'usec'}, tscale = 32;
    otherwise, error('Time units cannot be determined');
end


nii.hdr.dime.xyzt_units          = tscale + xyzscale;
nii.hdr.dime.intent_code         = niiv.intent_code;
nii.hdr.dime.intent_p1           = niiv.intent_p1;
nii.hdr.dime.intent_p2           = niiv.intent_p2;
nii.hdr.dime.intent_p3           = niiv.intent_p3;
nii.hdr.dime.pixdim(1)           = niiv.qfac;

% --- hist field
nii.hdr.hist.intent_name         = niiv.intent_name;
nii.hdr.hist.qform_code          = niiv.qform_code;
nii.hdr.hist.sform_code          = niiv.sform_code;
nii.hdr.hist.descrip             = niiv.descrip;
nii.hdr.hist.aux_file            = niiv.aux_file;
nii.hdr.hist.quatern_b           = niiv.quatern_b;
nii.hdr.hist.quatern_c           = niiv.quatern_c;
nii.hdr.hist.quatern_d           = niiv.quatern_d;

% When reading files we need to add 1 voxel to the header information to
% complaint with matlab 1-based indexing.
%
% Here we undo such operation, we subtract one before writing the file to
% disk.
if(~all(niiv.qto_xyz(1:9)==0))
    niiv.qto_ijk(1:3,4) = niiv.qto_ijk(1:3,4) - 1;
    q_xyz = inv(niiv.qto_ijk);
    q = matToQuat(q_xyz);
    nii.hdr.hist.qoffset_x = q.quatern_x;
    nii.hdr.hist.qoffset_y = q.quatern_y;
    nii.hdr.hist.qoffset_z = q.quatern_z;
else
    nii.hdr.hist.qoffset_x = 0;
    nii.hdr.hist.qoffset_y = 0;
    nii.hdr.hist.qoffset_z = 0;
end

if(~all(niiv.sto_xyz(1:9)==0))
    sto_ijk = niiv.sto_ijk;
    sto_ijk(1:3,4) = niiv.sto_ijk(1:3,4) - 1;
    sto_xyz = inv(sto_ijk);
    nii.hdr.hist.srow_x = sto_xyz(1,:);
    nii.hdr.hist.srow_y = sto_xyz(2,:);
    nii.hdr.hist.srow_z = sto_xyz(3,:);
else
    nii.hdr.hist.srow_x = [0 0 0 0];
    nii.hdr.hist.srow_y = [0 0 0 0];
    nii.hdr.hist.srow_z = [0 0 0 0];
end
  
% --- nk fields
% The fields freq_dim, phase_dim, slice_dim are all squished into the single
% byte field dim_info (2 bits each, since the values for each field are
% limited to the range 0..3):
% niiv.freq_dim =  bitand(uint8(3),          uint8(nii.hdr.hk.dim_info)    );
% niiv.phase_dim = bitand(uint8(3), bitshift(uint8(nii.hdr.hk.dim_info),-2));
% niiv.slice_dim = bitand(uint8(3), bitshift(uint8(nii.hdr.hk.dim_info),-4));
% Here we undo the previous operations perfrmed during the file load.
nii.hdr.hk.dim_info = niiv.freq_dim + 4*niiv.phase_dim + 16*niiv.slice_dim;

end % End main function

