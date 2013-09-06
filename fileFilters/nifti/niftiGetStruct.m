function ni = niftiGetStruct(imArray, matrixTransform, sclSlope, description,...
    intentName, intentCode, freqPhaseSliceDim, sliceCodeStartEndDuration, TR)
%
% OBSOLETE: We moved this into niftiCreate.m 
%
% Build a nifti struct ready for saving with writeFileNifti.
%
%  ni = niftiGetStruct(imArray, matrixTransform, sclSlope,
%  description, intentName, intentCode, freqPhaseSliceDim,
%  sliceCodeStartEndDuration, TR)
%
% Builds a NIFTI-1 structure suitable for passing to
% writeFileNifti. Leave out any parameter and a reasonable default
% will be used. Of course, if imArray is empty, you'll probably
% want to load that up with something before saving the struct to a
% NIFTI file. 
%
% NOTE: be sure to set ni.fname before calling writeFileNifti!
%
% imArray: the matlab array containing the image
%
% matrixTransform: a 4x4 matrix transforming from image space to AC-PC
% space.
%
% sclSlope: 'true' voxel intensity is storedVoxelVale*sclSlope.
%
% description: Any text string you like.
% 
% intentName: short text describing the data. (e.g., 'DTI')
%
% intentCode: NIFTI-1 intent code (integer). If intentName begins
% with DTI and intentCode is empty, then intentCode will be set to
% 1005 (the code for NIFTI_INTENT_SYMMATRIX). TO DO: add more handy
% defaults!
%
% freqPhaseSliceDim: 3-vector describing the frequency, phase and
% slice dims of the data. E.g., [1 2 3] for a typical axial EPI. 
%
% sliceCodeStartEndDuration: 
%        [slice_code slice_start slice_end slice_duration]
%        (see note from NIFTI header below)
% 
% TR: the repetition time. If ndim >4 then it will be set as the
% pixdim for the 4th dim, as per the NIFTI convention for time
% series data. Note that the default time units are seconds.
%
% From the NIFTI-1 header file:
%
%   A few fields are provided to store some extra information
%   that is sometimes important when storing the image data
%   from an FMRI time series experiment.  (After processing such
%   data into statistical images, these fields are not likely
%   to be useful.)
%  
%  { freq_dim  } = These fields encode which spatial dimension (1,2, or 3)
%  { phase_dim } = corresponds to which acquisition dimension for MRI data.
%  { slice_dim } =
%    Examples:
%      Rectangular scan multi-slice EPI:
%        freq_dim = 1  phase_dim = 2  slice_dim = 3  (or some permutation)
%      Spiral scan multi-slice EPI:
%        freq_dim = phase_dim = 0  slice_dim = 3
%        since the concepts of frequency- and phase-encoding directions
%        don't apply to spiral scan
%  
%    slice_duration = If this is positive, AND if slice_dim is nonzero,
%                     indicates the amount of time used to acquire 1 slice.
%                     slice_duration*dim[slice_dim] can be less than pixdim[4]
%                     with a clustered acquisition method, for example.
%  
%    slice_code = If this is nonzero, AND if slice_dim is nonzero, AND
%                 if slice_duration is positive, indicates the timing
%                 pattern of the slice acquisition.  The following codes
%                 are defined:
%                   NIFTI_SLICE_UNKNOWN  (0)
%                   NIFTI_SLICE_SEQ_INC  (1) == sequential increasing
%                   NIFTI_SLICE_SEQ_DEC  (2) == sequential decreasing
%                   NIFTI_SLICE_ALT_INC  (3) == alternating increasing
%                   NIFTI_SLICE_ALT_DEC  (4) == alternating decreasing
%                   NIFTI_SLICE_ALT_INC2 (5) == alternating increasing #2
%                   NIFTI_SLICE_ALT_DEC2 (6) == alternating decreasing #2
%  { slice_start } = Indicates the start and end of the slice acquisition
%  { slice_end   } = pattern, when slice_code is nonzero.  These values
%                    are present to allow for the possible addition of
%                    "padded" slices at either end of the volume, which
%                    don't fit into the slice timing pattern.  If there
%                    are no padding slices, then slice_start=0 and
%                    slice_end=dim[slice_dim]-1 are the correct values.
%                    For these values to be meaningful, slice_start must
%                    be non-negative and slice_end must be greater than
%                    slice_start.  Otherwise, they should be ignored.
%
%   The following table indicates the slice timing pattern, relative to
%   time=0 for the first slice acquired, for some sample cases.  Here,
%   dim[slice_dim]=7 (there are 7 slices, labeled 0..6), slice_duration=0.1,
%   and slice_start=1, slice_end=5 (1 padded slice on each end).
% 
%   slice
%   index  SEQ_INC SEQ_DEC ALT_INC ALT_DEC ALT_INC2 ALT_DEC2
%     6  :   n/a     n/a     n/a     n/a    n/a      n/a    n/a = not applicable
%     5  :   0.4     0.0     0.2     0.0    0.4      0.2    (slice time offset
%     4  :   0.3     0.1     0.4     0.3    0.1      0.0     doesn't apply to
%     3  :   0.2     0.2     0.1     0.1    0.3      0.3     slices outside
%     2  :   0.1     0.3     0.3     0.4    0.0      0.1     the range
%     1  :   0.0     0.4     0.0     0.2    0.2      0.4     slice_start ..
%     0  :   n/a     n/a     n/a     n/a    n/a      n/a     slice_end)
% 
%   The SEQ slice_codes are sequential ordering (uncommon but not unknown),
%   either increasing in slice number or decreasing (INC or DEC), as
%   illustrated above.
% 
%   The ALT slice codes are alternating ordering.  The 'standard' way for
%   these to operate (without the '2' on the end) is for the slice timing
%   to start at the edge of the slice_start .. slice_end group (at slice_start
%   for INC and at slice_end for DEC).  For the 'ALT_*2' slice_codes, the
%   slice timing instead starts at the first slice in from the edge (at
%   slice_start+1 for INC2 and at slice_end-1 for DEC2).  This latter
%   acquisition scheme is found on some Siemens scanners.
%
% See http://nifti.nimh.nih.gov/pub/dist/src/niftilib/nifti1.h for
% more details.
%
% To write an rgb nifti from uint8 data stored in 'd' and colormap in 
% 'cmap' (e.g., cmap=autumn(256)):
% ni = niftiGetStruct(d,xform);
% ni.fname = 'overlay.nii.gz';
% rgb = reshape(uint8(cmap(int16(d)+1,:).*255),[size(d) 3]);
% % Change to 'rgbrgbrgb...' byte order:
% rgb = reshape(permute(rgb,[1 4 2 3]), ni.dim(1)*3, ni.dim(2), ni.dim(3));
% ni.data = rgb;
% writeFileNifti(ni);
%
%
%
% HISTORY:
% 2007.10.03 RFD: wrote it (based on Akers' dtiWriteNiftiWrapper).

warning('OBSOLETE, the function %s was moved into niftiCreate.m',mfilename)

ni = niftiRead;

if ~exist('imArray','var')
    imArray = [];
end
if ~exist('matrixTransform','var') || isempty(matrixTransform)
    matrixTransform = eye(4);
end
if ~exist('sclSlope','var') || isempty(sclSlope)
    sclSlope = 1.0;
end
if ~exist('description','var') || isempty(description)
    description = 'VISTASOFT';
end

if ~exist('freqPhaseSliceDim','var') || isempty(freqPhaseSliceDim)
    freqPhaseSliceDim = [0 0 0];
end
if ~exist('sliceCodeStartEndDuration','var') || isempty(sliceCodeStartEndDuration)
    sliceCodeStartEndDuration = [0 0 0 0];
end
if ~exist('TR','var')
    TR = [];
end
if ~exist('intentName','var') || isempty(intentName)
    intentName = '';
end
if ~exist('intentCode','var') || isempty(intentCode)
    if(~isempty(intentName))
        sp = strfind(intentName,' ');
        if(~isempty(sp))
            in = intentName(1:sp(1)-1);
        else
            in = intentName;
        end
        switch in
            % We only look at the first few chars because the user might want
            % to use extra bytes in this 16-char field to store other info, like
            % the ADC units for DTI data.
            case 'DTI',
                intentCode = 1005; % NIFTI_INTENT_SYMMATRIX
                disp('Setting intentCode to NIFTI_INTENT_SYMMATRIX.');
            otherwise,
                intentCode = 0;
        end
    else
        intentCode = 0;
    end
end

% call matToQuat to get quaternion parameters:
quat_params = matToQuat (matrixTransform);
    
% Fill structure with important info
ni.data = imArray;
ni.fname = '';
ni.dim = size(imArray);
ni.ndim = length(ni.dim);
%ni.pixdim = mmPerVox;
ni.pixdim = ones(1,ni.ndim);
ni.pixdim(1:3) = [quat_params.dx quat_params.dy quat_params.dz];
if(ni.ndim>=4)
  if(~isempty(TR))
	ni.pixdim(4) = TR;
  elseif(ni.dim(4)>1)
    % Don't bother issuing a warning if the 4th dim has only one
    % volume. This would be the case, e.g., for DTI data, where the
    % matrix elements are in the 5th dim and 4th dim is size 1.
    disp('Data appear to be a timeseries, but the TR was not specified. Setting it to 1.');
  end
end
ni.cal_min = min(min(min(min(imArray))));
ni.cal_max = max(max(max(max(imArray))));
ni.sform_code = 2;
ni.qform_code = 2;
ni.xyz_units = 'mm';
ni.time_units = 'sec';
ni.nifti_type = 1;
ni.descrip = description;

ni.qto_xyz = matrixTransform;
ni.qto_ijk = inv(matrixTransform);
ni.sto_xyz = matrixTransform;
ni.sto_ijk = inv(matrixTransform);
%ni.qto_xyz = diag(mmPerVox);
%ni.qto_ijk = diag(1./mmPerVox);
%ni.sto_xyz = ni.qto_xyz + [zeros(4,3) [origin;0]];
%ni.sto_ijk = ni.qto_ijk + [zeros(4,3) [origin./mmPerVox(1:3)';0]];
ni.scl_slope = sclSlope;
ni.scl_inter = 0;
ni.freq_dim = freqPhaseSliceDim(1);
ni.phase_dim = freqPhaseSliceDim(2);
ni.slice_dim = freqPhaseSliceDim(3);
ni.slice_code = sliceCodeStartEndDuration(1);
ni.slice_start = sliceCodeStartEndDuration(2);
ni.slice_end = sliceCodeStartEndDuration(3);
ni.slice_duration = sliceCodeStartEndDuration(4);
ni.quatern_b = quat_params.quatern_b;
ni.quatern_c = quat_params.quatern_c;
ni.quatern_d = quat_params.quatern_d;
ni.qoffset_x = quat_params.quatern_x;
ni.qoffset_y = quat_params.quatern_y;
ni.qoffset_z = quat_params.quatern_z;
% ni.quatern_b = 0;
% ni.quatern_c = 0;
% ni.quatern_d = 0;
% ni.qoffset_x = 0;
% ni.qoffset_y = 0;
% ni.qoffset_z = 0;
ni.qfac = quat_params.qfac;
%ni.qfac = 0;
ni.toffset = 0;
ni.intent_code = intentCode;
ni.intent_p1 = 0;
ni.intent_p2 = 0;
ni.intent_p3 = 0;
ni.intent_name = intentName;
ni.aux_file = '';
ni.num_ext = 0;


return;
