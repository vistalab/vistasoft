function ni = niftiReadMatlabInternal(fileName, volumesToLoad)
% Matlab wrapper to call the mex readFileNifti
%
% *******************************************************
% NOTE:  As of 2017 Matlab has a "niftiread" function in its
%        distribution. 
% 
% NOTE: JAN 2020 GLU & JW: substituting the old readFileNifti mex with 
%       Matlab's niftiread, so that we can work with Nifti-2 
%       1./ It needs 2017a or newer
%       2./ If you are using 2017a or older but newer than 2019a, then only
%           works for nifti-1
%       3./ From 2019a, it can read/write Nifti-2
% *******************************************************
%
%   niftiImage = niftiRead(fileName,volumesToLoad)
%
% Reads a NIFTI image and populates a structure that should be the
% NIFTI 1 standard.  We expect that the filename has an extension of
% either .nii or .nii.gz
%
% If volumesToLoad is not included in the arguments, all the data
% are returned. If volumesToLoad is empty ([]) returns only the header
%
% Web Resources
%  web('http://nifti.nimh.nih.gov/nifti-1/','-browser')
%
% See also:  niftiCreate, niftiGetStruct
%
% Example:
%  niFile = fullfile(mrvDataRootPath,'mrQ','T1_lsqnabs_SEIR_cfm.nii.gz');
%  ni = niftiRead(niFile);
%
% Copyright, Vista Team Stanford, 2011

% This normally calls the mex file for your system
if ~exist('fileName','var') || isempty(fileName)
    % Return the default structure.  Equivalent to niftiCreate
    % ni = niftiRead;
    ni = readFileNifti;
elseif ischar(fileName) && exist(fileName,'file')
    % fileName is a string and the file exists.
    % For some reason, the volumeToLoad is not yet implemented.
    % We should just implement it here, by reading the whole
    % thing and only returning the relevant volumes.  I think
    % that is represented by the 4th dimension, but I should ask
    % someone who knows.
    if exist('volumesToLoad','var')
        % ni = niftiRead('foo.nii.gz',1:20);
        % We let readFileNifti complain about not implemented for
        % now.
        ni = readFileNifti(fileName,volumesToLoad);
    else
        % ni = niftiRead('foo.nii.gz');
        ni = readFileNifti(fileName);
    end
else
    % Make sure the the file includes the .nii.gz extensions
    % Really, someone should 
    [p,n,e] = fileparts(fileName);
    if isempty(e), fileNameExtended = [p,filesep,n,'.nii.gz']; 
    else
        % The can be file.nii or file.nii.gz
        if strcmp(e,'.gz') || strcmp(e,'.nii')
            fileNameExtended = fileName;
        else
            warning('Unexpected file name extension %s\n',e);
        end
    end
    if exist(fileNameExtended,'file')
        % HERE WE MODIFY THE OLD VERSION
        % This is the old mex call
        % ni = readFileNifti(fileNameExtended);
        
        % New implementation using Matlab's internal nifti functions
        % 1./ Read empty structure
        ni       = readFileNifti();
        % 2./ Read the data volume
        ni.data  = niftiread(fileNameExtended);
        ni.fname = fileNameExtended;
        % 3./ Read the Nifti1/Nifti2 header
        tmphdr  = niftiinfo(fileNameExtended);
        % 4./ Assign the temporal header elements to the old struct to maintain
        %     compatibility        
            % Dimension
            ni.ndim               = ndims(ni.data);
            ni.dim                = size(ni.data);
            % Check dims
            if ~isequal(ni.dim,tmphdr.ImageSize); error('Dimensions do not match');end

            % Dime field         
            ni.pixdim             = tmphdr.PixelDimensions;
            ni.scl_slope          = tmphdr.raw.scl_slope;
            ni.scl_inter          = tmphdr.raw.scl_inter;
            ni.cal_min            = tmphdr.raw.cal_min;
            ni.cal_max            = tmphdr.raw.cal_max;
            ni.slice_code         = tmphdr.raw.slice_code;
            ni.slice_start        = tmphdr.raw.slice_start;
            ni.slice_end          = tmphdr.raw.slice_end;
            ni.slice_duration     = tmphdr.raw.slice_duration;
            ni.toffset            = tmphdr.raw.toffset;
            switch tmphdr.SpaceUnits
                case 'Meter'
                    ni.xyz_units = 'meter';
                case 'Millimeter'
                    ni.xyz_units = 'mm';
                case 'Micron'
                    ni.xyz_units = 'micron';
                otherwise
                    ni.xyz_units = 'unknown';
                    warning('Could not match ni.xyz_units:%s, made it unknown', tmphdr.SpaceUnits)
            end
            switch tmphdr.TimeUnits
                case 'Second'
                    ni.time_units = 'sec';
                case 'Millisecond'
                    ni.time_units = 'msec';
                case 'Microsecond'
                    ni.time_units = 'usec';
                case 'Hertz'  
                    ni.time_units = 'hz';
                case 'PartPerMillion'
                    ni.time_units = 'ppm';
                case 'RadiansPerSecond'
                    ni.time_units = 'rads';
                otherwise
                    ni.time_units = 'unknown';
                    warning('Could not match ni.time_units:%s, made it unknown', tmphdr.TimeUnits)
            end
            ni.intent_code        = tmphdr.raw.intent_code;
            ni.intent_p1          = tmphdr.raw.intent_p1;
            ni.intent_p2          = tmphdr.raw.intent_p2;
            ni.intent_p3          = tmphdr.raw.intent_p3;
            ni.intent_name        = tmphdr.raw.intent_name;
            ni.nifti_type         = tmphdr.raw.datatype;
            ni.qfac               = tmphdr.raw.pixdim(1);

            % The fields freq_dim, phase_dim, slice_dim are all squished into the single
            % byte field dim_info (2 bits each, since the values for each field are
            % limited to the range 0..3):
            ni.freq_dim  = bitand(uint8(3),          uint8(tmphdr.raw.dim_info)    );
            ni.phase_dim = bitand(uint8(3), bitshift(uint8(tmphdr.raw.dim_info),-2));
            ni.slice_dim = bitand(uint8(3), bitshift(uint8(tmphdr.raw.dim_info),-4));

            % hist field
            ni.qform_code = tmphdr.raw.qform_code;
            ni.sform_code = tmphdr.raw.sform_code;
            ni.quatern_b  = tmphdr.raw.quatern_b;
            ni.quatern_c  = tmphdr.raw.quatern_c;
            ni.quatern_d  = tmphdr.raw.quatern_d;
            ni.qoffset_x  = tmphdr.raw.qoffset_x;
            ni.qoffset_y  = tmphdr.raw.qoffset_y;
            ni.qoffset_z  = tmphdr.raw.qoffset_z;
            ni.descrip    = tmphdr.Description;
            ni.aux_file   = tmphdr.raw.aux_file;

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
        ni.sto_xyz = [tmphdr.raw.srow_x; tmphdr.raw.srow_y; tmphdr.raw.srow_z; [0 0 0 1]];
        if(~all(ni.sto_xyz(1:9)==0))
            ni.sto_ijk = inv(ni.sto_xyz);
            ni.sto_ijk(1:3,4) = ni.sto_ijk(1:3,4) + 1;
            ni.sto_xyz = inv(ni.sto_ijk);
        else
            ni.sto_ijk = zeros(4);
        end

    else
        error('Cannot find the file %s\n',fileNameExtended);
    end
end


end
