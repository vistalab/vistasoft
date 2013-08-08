function ni = readFileNifti(fileName, volumesToLoad)
%
% Reads a NIFTI-1 file into a VISTASOFT nifti structure.
%       See http://nifti.nimh.nih.gov/nifti-1/
%
%  niftiImage = readFileNifti(fileName, [volumesToLoad=-1])
%
% fileName      - path to a .nii or nii.gz file.
% VolumesToLoad - The optional second argu specifies which volumes 
%                 to load for a 4D dataset. The default (-1) means 
%                 to read all, [] (empty) will just return the header.
%
% Call this function with no arguments to get an empty structure.
%
% NOTE: this file contains a slow maltab implementation of a compiled
% mex function. If you get a warning that the mex function is not being
% called, then compiling readFileNifti.c will dramatically improve
% performance.
%
% Example:
%   ni = readFileNifti;   % Nifti-1 structure
%
% (c) Stanford Vista 2012

disp('Using the matlab version of the niftiReader....');
if(nargin==0)
    if(nargout==0)
        help(mfilename);
    else
        ni = getVistaNiftiStructure;
        return;
    end
end

if(~exist('volumesToLoad','var') || volumesToLoad==-1)
    volumesToLoad = [];
end

% Get a structure for the nifti file compatible with VISTASFOT
ni = getVistaNiftiStructure;

% Build a filename and save it into the structure.
ni.fname = fileName;
[~,f,e]  = fileparts(fileName);

% Load the nifti file.
% Using: http://www.mathworks.com/matlabcentral/fileexchange/authors/20638
if(strcmpi(e,'.gz'))
   tmpDir = tempname;
   mkdir(tmpDir);
   copyfile(fileName,fullfile(tmpDir,strcat(f,e)));
   gunzip(fullfile(tmpDir,strcat(f,e)));
   tmpFileName = fullfile(tmpDir, f);
   tmpFile = true;
   nii = load_untouch_nii(tmpFileName, volumesToLoad);
else
   tmpFile = false;
   nii = load_untouch_nii(fileName, volumesToLoad);
end

% We then transform the nifti structure to our version.
ni.data               = nii.img; nii.img = [];
ni.ndim               = ndims(ni.data);
ni.dim                = size(ni.data);

% Dime field
ni.pixdim             = nii.hdr.dime.pixdim(2:ni.ndim+1);
ni.scl_slope          = nii.hdr.dime.scl_slope;
ni.scl_inter          = nii.hdr.dime.scl_inter;
ni.cal_min            = nii.hdr.dime.cal_min;
ni.cal_max            = nii.hdr.dime.cal_max;
ni.slice_code         = nii.hdr.dime.slice_code;
ni.slice_start        = nii.hdr.dime.slice_start;
ni.slice_end          = nii.hdr.dime.slice_end;
ni.slice_duration     = nii.hdr.dime.slice_duration;
ni.toffset            = nii.hdr.dime.toffset;
ni.xyz_units          = nii.hdr.dime.xyzt_units;
ni.time_units         = nii.hdr.dime.xyzt_units;
ni.intent_code        = nii.hdr.dime.intent_code;
ni.intent_p1          = nii.hdr.dime.intent_p1;
ni.intent_p2          = nii.hdr.dime.intent_p2;
ni.intent_p3          = nii.hdr.dime.intent_p3;
ni.intent_name        = nii.hdr.hist.intent_name;
ni.nifti_type         = nii.hdr.dime.datatype;
ni.qfac               = nii.hdr.dime.pixdim(1);

% The fields freq_dim, phase_dim, slice_dim are all squished into the single
% byte field dim_info (2 bits each, since the values for each field are
% limited to the range 0..3):
ni.freq_dim  = bitand(uint8(3),          uint8(nii.hdr.hk.dim_info)    );
ni.phase_dim = bitand(uint8(3), bitshift(uint8(nii.hdr.hk.dim_info),-2));
ni.slice_dim = bitand(uint8(3), bitshift(uint8(nii.hdr.hk.dim_info),-4));

% hist field
ni.qform_code = nii.hdr.hist.qform_code;
ni.sform_code = nii.hdr.hist.sform_code;
ni.quatern_b  = nii.hdr.hist.quatern_b;
ni.quatern_c  = nii.hdr.hist.quatern_c;
ni.quatern_d  = nii.hdr.hist.quatern_d;
ni.qoffset_x  = nii.hdr.hist.qoffset_x;
ni.qoffset_y  = nii.hdr.hist.qoffset_y;
ni.qoffset_z  = nii.hdr.hist.qoffset_z;
ni.descrip    = nii.hdr.hist.descrip;
ni.aux_file   = nii.hdr.hist.aux_file;

% Create a 4x4 matrix version of the quaternion, by taking care fo the
% difference in indexing the pixel dimensions between c-code (0-based
% indexing) and matlab (1-based indexing).
%
% We need to apply the 0-to-1 correction to qto and sto matrices.

% q* fields
ni.qto_xyz = quatToMat(ni.quatern_b, ni.quatern_c, ni.quatern_d, ni.qoffset_x, ni.qoffset_y, ni.qoffset_z, ni.qfac, ni.pixdim);
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
ni.sto_xyz = [nii.hdr.hist.srow_x; nii.hdr.hist.srow_y; nii.hdr.hist.srow_z; [0 0 0 1]];
if(~all(ni.sto_xyz(1:9)==0))
    ni.sto_ijk = inv(ni.sto_xyz);
    ni.sto_ijk(1:3,4) = ni.sto_ijk(1:3,4) + 1;
    ni.sto_xyz = inv(ni.sto_ijk);
else
    ni.sto_ijk = zeros(4);
end

% Delete the temporary file created
if ( tmpFile )
    delete(tmpFileName);
end

end


%--------------------------------%
function ni = getVistaNiftiStructure()
ni.data = [];
ni.fname = '';
ni.ndim = [];
ni.dim = [];
ni.pixdim = [];
ni.scl_slope = [];
ni.scl_inter = [];
ni.cal_min = [];
ni.cal_max = [];
ni.qform_code = [];
ni.sform_code = [];
ni.freq_dim = [];
ni.phase_dim = [];
ni.slice_dim = [];
ni.slice_code = [];
ni.slice_start = [];
ni.slice_end = [];
ni.slice_duration = [];
ni.quatern_b = [];
ni.quatern_c = [];
ni.quatern_d = [];
ni.qoffset_x = [];
ni.qoffset_y = [];
ni.qoffset_z = [];
ni.qfac = [];
ni.qto_xyz = [];
ni.qto_ijk = [];
ni.sto_xyz = [];
ni.sto_ijk = [];
ni.toffset = [];
ni.xyz_units = 'unknown,meter,mm,micron,sec,msec,usec,hz,ppm,rads,unknown';
ni.time_units = 'unknown,meter,mm,micron,sec,msec,usec,hz,ppm,rads,unknown';
ni.nifti_type = [];
ni.intent_code = [];
ni.intent_p1 = [];
ni.intent_p2 = [];
ni.intent_p3 = [];
ni.intent_name = [];
ni.descrip = [];
ni.aux_file = [];

end
