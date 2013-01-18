function niiv = niftiNi2Vista(nii)
% 
% Transforms a NIFTI-1 structure to an old VISTASOFT nifti-1 structure.
%
% niiv = niftiNi2Vista(nii)
%
% INPUT
%  nii - nifti-1 structure
%
% OUTPUTS:
%   niiv - OLD VISTASOFT nifti-1 structure
%
% Web Resources:
%   mrvBrowseSVN('niftiNi2Vista')
%
% Example:
%   nii = make_nii(ones(256,256,80))
%
% (c) Stanford Vista 2012

% We then transform the nifti structure to our version.
niiv.data               = nii.img; nii.img = [];
niiv.ndim               = ndims(niiv.data);
niiv.dim                = size(niiv.data);

% Dime field
niiv.pixdim             = nii.hdr.dime.pixdim(2:niiv.ndim+1);
niiv.scl_slope          = nii.hdr.dime.scl_slope;
niiv.scl_inter          = nii.hdr.dime.scl_inter;
niiv.cal_min            = nii.hdr.dime.cal_min;
niiv.cal_max            = nii.hdr.dime.cal_max;
niiv.slice_code         = nii.hdr.dime.slice_code;
niiv.slice_start        = nii.hdr.dime.slice_start;
niiv.slice_end          = nii.hdr.dime.slice_end;
niiv.slice_duration     = nii.hdr.dime.slice_duration;
niiv.toffset            = nii.hdr.dime.toffset;
niiv.xyz_units          = nii.hdr.dime.xyzt_units;
niiv.time_units         = nii.hdr.dime.xyzt_units;
niiv.intent_code        = nii.hdr.dime.intent_code;
niiv.intent_p1          = nii.hdr.dime.intent_p1;
niiv.intent_p2          = nii.hdr.dime.intent_p2;
niiv.intent_p3          = nii.hdr.dime.intent_p3;
niiv.intent_name        = nii.hdr.hist.intent_name;
niiv.nifti_type         = nii.hdr.dime.datatype;
niiv.qfac               = nii.hdr.dime.pixdim(1);

% The fields freq_dim, phase_dim, slice_dim are all squished into the single
% byte field dim_info (2 bits each, since the values for each field are
% limited to the range 0..3):
niiv.freq_dim  = bitand(uint8(3),          uint8(nii.hdr.hk.dim_info)    );
niiv.phase_dim = bitand(uint8(3), bitshift(uint8(nii.hdr.hk.dim_info),-2));
niiv.slice_dim = bitand(uint8(3), bitshift(uint8(nii.hdr.hk.dim_info),-4));

% hist field
niiv.qform_code = nii.hdr.hist.qform_code;
niiv.sform_code = nii.hdr.hist.sform_code;
niiv.quatern_b  = nii.hdr.hist.quatern_b;
niiv.quatern_c  = nii.hdr.hist.quatern_c;
niiv.quatern_d  = nii.hdr.hist.quatern_d;
niiv.qoffset_x  = nii.hdr.hist.qoffset_x;
niiv.qoffset_y  = nii.hdr.hist.qoffset_y;
niiv.qoffset_z  = nii.hdr.hist.qoffset_z;
niiv.descrip    = nii.hdr.hist.descrip;
niiv.aux_file   = nii.hdr.hist.aux_file;

% Create a 4x4 matrix version of the quaternion, by taking care fo the
% difference in indexing the pixel dimensions between c-code (0-based
% indexing) and matlab (1-based indexing).
%
% We need to apply the 0-to-1 correction to qto and sto matrices.

% q* fields
niiv.qto_xyz = quatToMat(niiv.quatern_b, niiv.quatern_c, niiv.quatern_d, niiv.qoffset_x, niiv.qoffset_y, niiv.qoffset_z, niiv.qfac, niiv.pixdim);
if(~all(niiv.qto_xyz(1:9)==0))
    niiv.qto_ijk = inv(niiv.qto_xyz);
    niiv.qto_ijk(1:3,4) = niiv.qto_ijk(1:3,4) + 1;
    niiv.qto_xyz = inv(niiv.qto_ijk);
    niiv.qoffset_x = niiv.qto_xyz(1,4);
    niiv.qoffset_y = niiv.qto_xyz(2,4);
    niiv.qoffset_z = niiv.qto_xyz(3,4);
else
    niiv.qto_ijk = zeros(4);
end

% s*
niiv.sto_xyz = [nii.hdr.hist.srow_x; nii.hdr.hist.srow_y; nii.hdr.hist.srow_z; [0 0 0 1]];
if(~all(niiv.sto_xyz(1:9)==0))
    niiv.sto_ijk = inv(niiv.sto_xyz);
    niiv.sto_ijk(1:3,4) = niiv.sto_ijk(1:3,4) + 1;
    niiv.sto_xyz = inv(niiv.sto_ijk);
else
    niiv.sto_ijk = zeros(4);
end

end % End main function
