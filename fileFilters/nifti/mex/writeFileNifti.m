function writeFileNifti(ni)
% Write a VISTASOFT nifti structure into a file compatible with the NIFTI-1
% standard.
% 
%   writeFileNifti(ni)
% 
% INPUTS:
%   ni - a nifti file structure (.nii or .nii.gz)
%
% OUTPUTS:
%   none.
%
% Web Resources:
%   mrvBrowseSVN('writeFileNifti')
%
% Example:
%   ni = 
%               data: [256x256x21 double]
%              fname: 'nifti_filename.nii.gz'
%               ndim: 3
%                dim: [256 256 21]
%             pixdim: [0.5000 0.5000 1.9999]
%          scl_slope: 1
%          scl_inter: 0
%            cal_min: 0
%            cal_max: 0
%         qform_code: 0
%         sform_code: 1
%           freq_dim: 0
%          phase_dim: 0
%          slice_dim: 0
%         slice_code: 0
%        slice_start: 0
%          slice_end: 0
%     slice_duration: 0
%          quatern_b: 0
%          quatern_c: 0
%          quatern_d: 0
%          qoffset_x: 0
%          qoffset_y: 0
%          qoffset_z: 0
%               qfac: 0
%            qto_xyz: [4x4 double]
%            qto_ijk: [4x4 double]
%            sto_xyz: [4x4 double]
%            sto_ijk: [4x4 double]
%            toffset: 0
%          xyz_units: 'mm'
%         time_units: 'sec'
%         nifti_type: 1
%        intent_code: 0
%          intent_p1: 0
%          intent_p2: 0
%          intent_p3: 0
%        intent_name: ''
%            descrip: ''
%           aux_file: ''
%            num_ext: 0
% 
% >> writeFileNifti(ni);
%	
% Franco (c) Stanford VISTA team, 2012
%
% This matlab version has been adapted by Franco from Bob's c-code

% datatype (optional):	Storage data type. Default is float32 [16]:
% 		2 - uint8,  4 - int16,  8 - int32,  16 - float32,
% 		32 - complex64,  64 - float64,  128 - RGB24,
% 		256 - int8,  512 - uint16,  768 - uint32, 1792 - complex128
%

%% Get a Jimmy Shen structure
% http://www.mathworks.com/matlabcentral/fileexchange/authors/20638
fileName   = ni.fname;
voxel_siz  = diag(ni.qto_xyz(1:3,1:3));
originator = ni.qto_ijk(1:3,end);
% Get NIFTI-1 the data type from the data type of the data field in the
% structure.
data_type  = niftiDataTypeFromString(class(ni.data));
nii        = make_nii(ni.data,voxel_siz,originator,data_type);

% clear data to save memory.
nii.data = [];

%% hdr fields.
% --- dime field.
nii.hdr.dime.pixdim(2:ni.ndim+1) = ni.pixdim;
nii.hdr.dime.scl_slope           = ni.scl_slope;
nii.hdr.dime.scl_inter           = ni.scl_inter;
nii.hdr.dime.cal_min             = ni.cal_min;
nii.hdr.dime.cal_max             = ni.cal_max;
nii.hdr.dime.slice_code          = ni.slice_code;
nii.hdr.dime.slice_start         = ni.slice_start;
nii.hdr.dime.slice_end           = ni.slice_end;
nii.hdr.dime.slice_duration      = ni.slice_duration;
nii.hdr.dime.toffset             = ni.toffset;
nii.hdr.dime.xyzt_units          = ni.xyz_units;
nii.hdr.dime.xyzt_units          = ni.time_units;
nii.hdr.dime.intent_code         = ni.intent_code;
nii.hdr.dime.intent_p1           = ni.intent_p1;
nii.hdr.dime.intent_p2           = ni.intent_p2;
nii.hdr.dime.intent_p3           = ni.intent_p3;
nii.hdr.dime.datatype            = ni.nifti_type;
nii.hdr.dime.pixdim(1)           = ni.qfac;

% --- hist field
nii.hdr.hist.intent_name         = ni.intent_name;
nii.hdr.hist.qform_code          = ni.qform_code;
nii.hdr.hist.sform_code          = ni.sform_code;
nii.hdr.hist.descrip             = ni.descrip;
nii.hdr.hist.aux_file            = ni.aux_file;
nii.hdr.hist.quatern_b           = ni.quatern_b;
nii.hdr.hist.quatern_c           = ni.quatern_c;
nii.hdr.hist.quatern_d           = ni.quatern_d;

% When reading files we need to add 1 voxel to the header information to
% complaint with matlab 1-based indexing.
%
% Here we undo such operation, we subtract one before writing the file to
% disk.
if(~all(ni.qto_xyz(1:9)==0))
    ni.qto_ijk(1:3,4) = ni.qto_ijk(1:3,4) - 1;
    q_xyz = inv(ni.qto_ijk);
    q = matToQuat(q_xyz);
    nii.hdr.hist.qoffset_x = q.quatern_x;
    nii.hdr.hist.qoffset_y = q.quatern_y;
    nii.hdr.hist.qoffset_z = q.quatern_z;
else
    nii.hdr.hist.qoffset_x = 0;
    nii.hdr.hist.qoffset_y = 0;
    nii.hdr.hist.qoffset_z = 0;
end

if(~all(ni.sto_xyz(1:9)==0))
    sto_ijk = ni.sto_ijk;
    sto_ijk(1:3,4) = ni.sto_ijk(1:3,4) - 1;
    sto_xyz = inv(sto_ijk);
    nii.hdr.hist.srow_x = sto_xyz(1,:);
    nii.hdr.hist.srow_y = sto_xyz(2,:);
    nii.hdr.hist.srow_z = sto_xyz(3,:);
else
    nii.hdr.hist.srow_x = 0;
    nii.hdr.hist.srow_y = 0;
    nii.hdr.hist.srow_z = 0;
end
  
% --- nk fields
% The fields freq_dim, phase_dim, slice_dim are all squished into the single
% byte field dim_info (2 bits each, since the values for each field are
% limited to the range 0..3):
% ni.freq_dim =  bitand(uint8(3),          uint8(nii.hdr.hk.dim_info)    );
% ni.phase_dim = bitand(uint8(3), bitshift(uint8(nii.hdr.hk.dim_info),-2));
% ni.slice_dim = bitand(uint8(3), bitshift(uint8(nii.hdr.hk.dim_info),-4));
% Here we undo the previous operations perfrmed during the file load.
nii.hdr.hk.dim_info = ni.freq_dim + 4*ni.phase_dim + 16*ni.slice_dim;

%% Save the file to disk using Shen's code.
[p,n,e] = fileparts(fileName);
save_nii(nii,fullfile(p,n));

%% Zip the file
gzip(fullfile(p,n));

%% Delete the unzipped file created by save_nii.m:
system(sprintf('rm %s',fullfile(p,n)));

end

%----------------------------------%
function dt = niftiDataTypeFromString(matlabType)
% 
% Transform string (some matlab) data types into 
% numerical codes for NIFTI-1 data types.
%
%  String (Matlab) ----> NIFTI-1
% -------------------------------
%            uint8 ----> 2
%            int16 ----> 4
%            int32 ----> 8
%          float32 ----> 16
%        complex64 ----> 32
%          float64 ----> 64
%            RGB24 ----> 128
%             int8 ----> 256
%           unit16 ----> 512
%           uint32 ----> 768
%       complex128 ----> 1792
%
% Franco (c) Stanford Vista team, 2012

matlabType = mrvParamFormat(matlabType);
switch matlabType
  case {'uint8'},      dt = 2;
  case {'int16'},      dt = 4;
  case {'int32'},      dt = 8;
  case {'float32','single'}, dt = 16;
  case {'complex64'},  dt = 32';
  case {'float64','double'}, dt = 64;
  case {'rgb64'},      dt = 128;
  case {'int8'},       dt = 256;
  case {'uint16'},     dt = 512;
  case {'uint32'},     dt = 768;
  case {'complex128'}, dt = 1792;
  otherwise,           keyboard
end

end

