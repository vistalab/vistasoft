function ni = nii_tool_read_wrapper(fileName)
% Wrapper over the nifti reading function nii_tool, available here:
%         https://github.com/xiangruili/dicm2nii   
% niftiRead was updated so that it could handle Nifti-2.

% 1./ Read empty structure, to have the original vistasoft struct
ni       = readFileNifti;

% 2./ Read volume
tmp      = nii_tool('load',fileName);
ni.data  = tmp.img;

% 3./ Read the Nifti1/Nifti2 header
tmphdr   = tmp.hdr;

% 4./ Assign the temporal header elements to the old struct to maintain
%     compatibility
    
    ni.fname = tmphdr.file_name;
    % Dimension
    ni.ndim               = ndims(ni.data);
    ni.dim                = size(ni.data);
    % Check dims
    if ~isequal(ni.dim,tmphdr.dim(2:ni.ndim+1)); error('Dimensions do not match');end

    % Dime field         
    ni.pixdim             = tmphdr.pixdim(2:ni.ndim+1);
    ni.scl_slope          = tmphdr.scl_slope;
    ni.scl_inter          = tmphdr.scl_inter;
    ni.cal_min            = tmphdr.cal_min;
    ni.cal_max            = tmphdr.cal_max;
    ni.slice_code         = tmphdr.slice_code;
    ni.slice_start        = tmphdr.slice_start;
    ni.slice_end          = tmphdr.slice_end;
    ni.slice_duration     = tmphdr.slice_duration;
    ni.toffset            = tmphdr.toffset;
    ni.xyz_units          = tmphdr.xyzt_units;
    ni.time_units         = tmphdr.xyzt_units;
    ni.intent_code        = tmphdr.intent_code;
    ni.intent_p1          = tmphdr.intent_p1;
    ni.intent_p2          = tmphdr.intent_p2;
    ni.intent_p3          = tmphdr.intent_p3;
    ni.intent_name        = tmphdr.intent_name;
    ni.nifti_type         = tmphdr.datatype;
    ni.qfac               = tmphdr.pixdim(1);

    % The fields freq_dim, phase_dim, slice_dim are all squished into the single
    % byte field dim_info (2 bits each, since the values for each field are
    % limited to the range 0..3):
    ni.freq_dim  = bitand(uint8(3),          uint8(tmphdr.dim_info)    );
    ni.phase_dim = bitand(uint8(3), bitshift(uint8(tmphdr.dim_info),-2));
    ni.slice_dim = bitand(uint8(3), bitshift(uint8(tmphdr.dim_info),-4));

    % hist field
    ni.qform_code = tmphdr.qform_code;
    ni.sform_code = tmphdr.sform_code;
    ni.quatern_b  = tmphdr.quatern_b;
    ni.quatern_c  = tmphdr.quatern_c;
    ni.quatern_d  = tmphdr.quatern_d;
    ni.qoffset_x  = tmphdr.qoffset_x;
    ni.qoffset_y  = tmphdr.qoffset_y;
    ni.qoffset_z  = tmphdr.qoffset_z;
    ni.descrip    = tmphdr.descrip;
    ni.aux_file   = tmphdr.aux_file;

    % Create a 4x4 matrix version of the quaternion, by taking care of the
    % difference in indexing the pixel dimensions between c-code (0-based
    % indexing) and matlab (1-based indexing).
    %
    % We need to apply the 0-to-1 correction to qto and sto matrices.

    % q* fields
    ni.qto_xyz = quatToMat(ni.quatern_b, ni.quatern_c, ni.quatern_d, ...
                           ni.qoffset_x, ni.qoffset_y, ni.qoffset_z, ...
                           ni.qfac, ni.pixdim);
    if(~all(ni.qto_xyz(1:9)==0))
        ni.qto_ijk = inv(ni.qto_xyz);
        ni.qto_ijk(1:3,4) = ni.qto_ijk(1:3,4) + 1;
        ni.qto_xyz = inv(ni.qto_ijk);
        ni.qoffset_x = ni.qto_xyz(1,4);
        ni.qoffset_y = ni.qto_xyz(2,4);
        ni.qoffset_z = ni.qto_xyz(3,4);
    else
        ni.qto_ijk = zeros(4);
    end

    % s*
    ni.sto_xyz = [tmphdr.srow_x; tmphdr.srow_y; tmphdr.srow_z; [0 0 0 1]];
    if(~all(ni.sto_xyz(1:9)==0))
        ni.sto_ijk = inv(ni.sto_xyz);
        ni.sto_ijk(1:3,4) = ni.sto_ijk(1:3,4) + 1;
        ni.sto_xyz = inv(ni.sto_ijk);
    else
        ni.sto_ijk = zeros(4);
    end
    % ADD EXTRA INFO TO THE VISTASOFT NIFTI
    ni.version    = tmphdr.version;
    ni.sizeof_hdr = tmphdr.sizeof_hdr;
    ni.magic      = tmphdr.magic;
    
end