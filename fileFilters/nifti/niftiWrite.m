function niftiWrite(ni,fName)
%  Writes a nifti structure to disk. 
%
%   niftiWrite(ni,[fName])
%
% Wrapper to writeFileNifti mex file, which writes a VISTASOFT nifti
% structure to a NIFTI-1 file.
% 
% INPUTS
%   ni - a nifti structure 
%   fName - output file name  (defaults to ni.fname if empty). 
% 
% FILE FORMATS:
%   fName extension should be either '.nii' or 'nii.gz'
% 
% EXAMPLE:
%   dFolder = mrtInstallSampleData('functional','mrBOLD_01');
%   pth =  fullfile(dFolder, 'Raw', 'T1_Inplane.nii.gz');
%   ni  = niftiRead(pth);
%   fName = fullfile(tempdir, 'myFile.nii.gz');
%   niftiWrite(ni,fName);
%
% See also:  niftiRead
% 
% (C) Stanford VISTA, 2012-2015
% 

if exist('fName', 'var') && ~isempty(fName)
    ni.fname = fName;    
elseif ~isfield(ni,'fname') || isempty(ni.fname)
    error('A filename is required to save a NIFTI-1 structure to file.');
end

% EDIT GLU 2020-01-28
% We want to be able to write Nifti-2 files. If the the field version is not in
% the ni struct, or it is = 1, write a Nifti-1 file using the old mex code, to
% maximize backwards compatibility. If the version field is 2, write a Nifti-2
% using the nii_tool (https://github.com/xiangruili/dicm2nii)
if isfield(ni, 'version')
    if ni.version == 2
        % It will take file name from struct, and it will use the NIfti-2
        % from the struct as well.
        %
        % Modify it to format as nii_tool wants it
        ni2                = struct();
        ni2.img            = ni.data;
        ni                 = rmfield(ni, 'data');
        ni2.hdr            = ni;
        ni2.hdr.file_name  = ni2.hdr.fname;
        ni2.hdr            = rmfield(ni2.hdr, 'fname');
        % Use a function to setup the xyzt_units field
        ni2.hdr.xyzt_units = setSpaceTimeUnits(ni2.hdr.xyz_units, ni2.hdr.time_units);
        ni2.hdr            = rmfield(ni2.hdr, 'xyz_units');
        ni2.hdr            = rmfield(ni2.hdr, 'time_units');
        
        % Adapt back the rest of the fields using writeFileNifti code:
        ni2.hdr.pixdim              = zeros(1,1+numel(ni.pixdim));
        ni2.hdr.pixdim(2:1+numel(ni.pixdim)) = ni.pixdim; 
        ni2.hdr.datatype            = ni.nifti_type;
        ni2.hdr                     = rmfield(ni2.hdr, 'nifti_type');
        ni2.hdr.pixdim(1)           = ni.qfac;
        ni2.hdr                     = rmfield(ni2.hdr, 'qfac');
        
        % When reading files we need to add 1 voxel to the header information to
        % complaint with matlab 1-based indexing.
        %
        % Here we undo such operation, we subtract one before writing the file to disk.
        if (~all(ni.qto_xyz(1:9)==0))
            ni.qto_ijk(1:3,4) = ni.qto_ijk(1:3,4) - 1;
            q_xyz = inv(ni.qto_ijk);
            q = matToQuat(q_xyz);
            ni2.hdr.qoffset_x = q.quatern_x;
            ni2.hdr.qoffset_y = q.quatern_y;
            ni2.hdr.qoffset_z = q.quatern_z;
        else
            ni2.hdr.qoffset_x = 0;
            ni2.hdr.qoffset_y = 0;
            ni2.hdr.qoffset_z = 0;
        end
        
        if (~all(ni.sto_xyz(1:9)==0))
            sto_ijk = ni.sto_ijk;
            sto_ijk(1:3,4) = ni.sto_ijk(1:3,4) - 1;
            sto_xyz = inv(sto_ijk);
            ni2.hdr.srow_x = sto_xyz(1,:);
            ni2.hdr.srow_y = sto_xyz(2,:);
            ni2.hdr.srow_z = sto_xyz(3,:);
        else
            ni2.hdr.srow_x = 0;
            ni2.hdr.srow_y = 0;
            ni2.hdr.srow_z = 0;
        end
        
        % --- nk fields
        % The fields freq_dim, phase_dim, slice_dim are all squished into the single
        % byte field dim_info (2 bits each, since the values for each field are
        % limited to the range 0..3):
        % ni.freq_dim =  bitand(uint8(3),          uint8(nii.hdr.hk.dim_info)    );
        % ni.phase_dim = bitand(uint8(3), bitshift(uint8(nii.hdr.hk.dim_info),-2));
        % ni.slice_dim = bitand(uint8(3), bitshift(uint8(nii.hdr.hk.dim_info),-4));
        % Here we undo the previous operations perfrmed during the file load.
        
        ni2.hdr.dim_info = ni2.hdr.freq_dim + 4*ni2.hdr.phase_dim + 16*ni2.hdr.slice_dim;
        
        % Save it.
        nii_tool('save', ni2);
    else
        writeFileNifti(ni);
    end
else
    writeFileNifti(ni);
end

return
end

% GLU 2020-01-28 added this function from Matlab's nifti implementation to
% convert back the spaceTime units to the nifti field required by 
    function xyztCode = setSpaceTimeUnits(spaceUnitText, timeUnitText)
        %setSpaceTimeUnits: convert simplified space time units to standard
        %form.
        %    This is a helper function to convert simplified space and time
        %    units to the raw format as specified in the NIfTI header.
        
        spaceKey   = {0, 1, 2, 3};
        spaceValue = {'unknown', 'meter', 'mm', 'micron'};
        
        spaceMap = containers.Map(spaceValue, spaceKey);
        
        if isempty(find(strcmp(spaceValue, spaceUnitText), 1))
            error(message('images:nifti:spaceUnitNotSupported'));
        end
        
        spaceUnits = spaceMap(spaceUnitText);
        
        timeValue = {'unknown', 'sec', 'msec', 'usec', 'hz', 'ppm', 'rads'};
        timeKey = {0, 8, 16, 24, 32, 40, 48};
        
        timeMap = containers.Map(timeValue, timeKey);
        
        if isempty(find(strcmp(timeValue, timeUnitText), 1))
            error(message('images:nifti:timeUnitNotSupported'));
        end
        
        timeUnits = timeMap(timeUnitText);
        
        spaceUnitCode = bitand(uint8(spaceUnits),uint8(7));
        timeUnitCode  = bitand(uint8(timeUnits),uint8(56)); % 0x38
        
        xyztCode = bitor(spaceUnitCode, timeUnitCode);
        
    end







%% Old code
% The old code was not a wrapper to writeFileNifti, but instead converted
% the VISTASOFT nifti struct to a nifti-1 struct using the function
% niftiVista2ni, and then write the nifti-1 struct to file using the Shen
% function save_nii.
%
% We prefer the mex file writeFileNifti, which is fast which does the
% inverse conversion of the mex function readFileNifti (wrapped in the m
% file niftiRead).

% %% Set defaults
% compress = true;
% fname_supplied = false;
% 
% 
% %% Check inputs
% if nargin==0
%     help(mfilename)
%     return
% end
% 
% 
% 
% if notDefined('fName')
%     fName = '';
% else
%     fname_supplied = true;
% end
% 
% 
% %% Check file extension
% 
% % If no name was supplied check the nifti structure for the name
% if isempty(fName)
%     if isfield(ni,'fname') && ~isempty(ni.fname)
%         fName = ni.fname;
%     else
%         error('A filename is required to save a NIFTI-1 structure to file.');
%     end
% end
%     
% % Handle the file extension (must be '.nii' for save_nii)
% [p, f, e] = fileparts(fName);
% switch e
%     case '.gz'
%         fName = fullfile(p,f);
%     case '.nii'
%         % If a filename was passed in and it was something'.nii' then we
%         % assume the user does not want the file compressed.
%         if fname_supplied; compress = false; end
%     otherwise
%         fName = fullfile(p,[f '.nii']);
% end
% 
% 
% %% Deal with old VISTASOFT nifti structures.
% if isfield(ni,'data')
%   % This is likely to be a old VISTASOFT nifti-1 structure, see
%   % niftiVista2ni.m
%   ni = niftiVista2ni(ni);
% end
% 
% 
% %% Save the file to disk using Shen's code.
% save_nii(ni,fName);
% 
% 
% %% GZip the file
% if compress
%     gzip(fName);
%      
%     % Delete the unzipped file created by save_nii.m:
%     delete(fName);
% end
% 
% return
