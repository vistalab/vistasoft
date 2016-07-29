function acpc_aligned_nifti = mrAnatAutoAlignAcpcNifti(anatomical_in, anatomical_out)
%
%  acpc_aligned_nifti = mrAnatAutoAlignAcpcNifti(anatomical_in, [anatomical_out])
% 
% Generate a ac-pc aligned nifti image using Talairach coordinates
% converted to MNI space. 
%
% INPUTS:
%   anatomical_in:	Full path to raw (unaligned) anatomical image
%   anatomical_out:	(optional) Full path for output file. Defaults to
%                   <anatomical_in> + '_acpc.nii.gz'
% 
% OUTPUTS:
%   anatomical_out: Full path to the aligned nifti file. 
% 
% (C) Stanford Vista Lab, 2016
% 


%% Handle I/O

if ~exist('anatomical_in','var') || isempty(anatomical_in) || ~exist(anatomical_in, 'file')
    error('No input file was defined.');
end

% If no output file was defined, set to input + '_acpc.nii.gz'
if ~exist('anatomical_out','var') || isempty(anatomical_out) 
    base = strsplit(anatomical_in, '.nii');
    [p, f] = fileparts(base{1}); 
    anatomical_out = fullfile(p, [f, '_acpc.nii.gz']);
end


%% Perform acpc alignment

% The ACPC coordinates in Talairach
ACPC_COORDS = [0,0,0; 0,-16,0; 0,-8,40];

% Read in the file
ni = niftiRead(anatomical_in);

% Apply the cannonical transform
ni = niftiApplyCannonicalXform(ni);

% Use the MNI_T1 template
template =  fullfile(mrDiffusionDir, 'templates', 'MNI_T1.nii.gz');

% Compute the spatial normalization
sn = mrAnatComputeSpmSpatialNorm(ni.data, ni.qto_xyz, template);

% Get the iamge coordinates for the mid-line, ac, and pc
coords = mrAnatGetImageCoordsFromSn(sn, tal2mni(ACPC_COORDS)', true)';

% Use the coords to generate acpc-aligned image
mrAnatAverageAcpcNifti(ni, anatomical_out, coords, [], [], [], false);


%% Check for anatomical_out file

if ~exist(anatomical_out,'file')
    warning('Auto AC-PC Alignment failed.');
else
    acpc_aligned_nifti = anatomical_out;
end
