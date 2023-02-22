function fs_ribbon2itk(subjID, outfile, fillWithCSF, alignTo, resample_type, in_orientation)
% Read in a freesurfer ribbon.mgz file and convert to a nifti class file
% with our itkGray conventional labels.
%
% fs_ribbon2itk(subjID, [outfile], [fillWithCSF], [alignTo], [resample_type])
%
% Inputs:
%   subjID:         name of directory in freesurfer subject directory (string). 
%                    Or it can be a full path to the ribbon.mgz file.
%   outfile:        name of output nifti segmentation file (including path)
%                    [default = 't1_class.nii.gz']
%   fillWithCSF:    if true, convert unlabeled voxels to CSF (0s => 1s)
%                    [default = false]        
%   alignTo:        optional nifti file which determines bounding box and
%                    alignment of output segmnentation
%   resample_type:  resampling method for converting the ribbon file to a
%                    nifti. Options: interpolate, weighted, nearest, 
%                    sinc, and cubic. (Sinc and cubic do not produce integer
%                    values and do not work in itkGray)
%                    [default = 'nearest'] 
%   in_orientation: sometimes freesurfer mis-reads header information and
%                    the segmentation file is output with the dimensions
%                    transposed or flipped.  If this is the case you can
%                    specify the correct input orientation. For example:
%                    in_orientation='LIA' The options are L versus R / I
%                    versus S / and A versus P.  These options can be in
%                    any position. Cannonical is RAS if the image is
%                    flipped left right then you would do LAS.  The letters
%                    get reordered if the dimensions are transposed.
%
% The freesurfer automatic segmentation process produces many output files.
% From our preliminary experience, the gray-white segmentation is quite
% accurate, and creates white matter segmentations with minimal topological
% errors (handles, cavities). 
%
% The file called ribbon.mgz is similar to the class files we create when
% we segment in itkGray. It is aligned to the freesurfer file 't1.mgz', and
% it contains integer values: 
%
%    2: left white matter
%    3: left gray matter
%   41: right white matter
%   42: right gray matter
%    0: unlabeled
%
% If we want to use this freesurfer segmentation, then we need to (a)
% convert the mgz file to nifti, and (b) change the label values to 
%    3: left white matter
%    5: left gray matter
%    4: right white matter
%    6: right gray matter 
%
%    1: csf (if input argument fillWithCSF = true), or  
%    0: unlabeled
%
%
% For description of freesurfer automatic segmentation, see
%   http://surfer.nmr.mgh.harvard.edu/fswiki/ReconAllDevTable
% And for the ribbon file specifcally see:
%   http://surfer.nmr.mgh.harvard.edu/fswiki/cortribbon
%
% Example 1:
%   fs_ribbon2itk('bert')
%
% Example 2:
%   subjID      = 'andreas';
%   outfile     = 't1_freesurfer_class.nii.gz'
%   fillWithCSF = true; 
%   alignTo     = '/biac2/wandell2/data/anatomy/rauschecker/Anatomy081031/t1.nii.gz';
%   resample_type= 'nearest';
%   fs_ribbon2itk(subjID, outfile, fillWithCSF, alignTo, resample_type);
%
%  AL + LMP, 5/11: Changed default interpolation method from 'nearest' to 'weighted'.

%% Check Inputs
if ~exist('subjID', 'var')
    warning('Subject ID is required input'); %#ok<WNTAG>
    help 'fs_ribbon2itk';
    return
end

if notDefined('fillWithCSF'),   fillWithCSF = false;        end
if notDefined('resample_type'), resample_type= 'nearest';  end


%% Find paths
% If the subjID is not a full path then assume it is a subject directory
% within the defined freesurfer subject directory.
if exist(subjID, 'file') && ~exist(subjID, 'dir')
    ribbon = subjID;
else
    subdir   = getenv('SUBJECTS_DIR');
    if isempty(subdir)
        fshome = getenv('FREESURFER_HOME');
        subdir = fullfile(fshome, 'subjects');
    end
    ribbon = fullfile(subdir, subjID, 'mri', 'ribbon.mgz');
end

if ~exist(ribbon, 'file')
    [fname, pth] = uigetfile(...
        {'ribbon*.mgz', 'Ribbon files'; '*.mgz', '.mgz files'},...
        'Cannot locate ribbon file. Please find it yourself.', pwd);
    ribbon = fullfile(pth, fname);
end    

if ~exist(ribbon, 'file'), error('Cannot locate ribbon.mgz file'); end

if notDefined('outfile')
    pth     = fileparts(ribbon);
    outfile = fullfile(pth, 't1_class.nii.gz'); 
end

%% Convert MGZ to NIFTI
if exist('alignTo', 'var')
    [~, ~, ext] = fileparts(alignTo);
    if strcmpi(ext, '.mgz')       
        if ~exist(alignTo, 'file') && exist(fullfile(subdir, subjID, 'mri', alignTo), 'file')
            alignTo = fullfile(subdir, subjID, 'mri', alignTo);            
        end
        newT1  = fullfile(fileparts(outfile), 't1.nii.gz');        
        str = sprintf('!mri_convert -rt %s %s %s', resample_type, alignTo, newT1);
        alignTo = newT1;
        eval(str)
    end
end

if exist('alignTo', 'var') && exist('in_orientation','var')
    str = sprintf('mri_convert  --in_orientation %s --reslice_like %s -rt %s %s %s', in_orientation, alignTo, resample_type, ribbon, outfile);
elseif exist('alignTo', 'var')
    str = sprintf('mri_convert  --reslice_like %s -rt %s %s %s', alignTo, resample_type, ribbon, outfile);
else
    str = sprintf('mri_convert  -rt %s %s %s', resample_type, ribbon, outfile);
end
if system(str) == 127
    error(...
        ['The mri_convert binary was not found on the system PATH;' ...
           ' this could be caused by several things:\n' ...
           ' (1) FreeSurfer is not installed (see' ...
           ' https://surfer.nmr.mgh.harvard.edu/fswiki/Installation)\n' ...
           ' (2) The FreeSurferEnv.sh (or .csh) startup script is not' ...
           ' sourced in your profile (e.g., ~/.bash_profile)\n' ...
           ' (3) Matlab does not know to read your startup profile when' ...
           ' starting a shell; to fix this, for a bash shell, you must' ...
           ' set the BASH_ENV environment variable: ' ...
           ' setenv(''BASH_ENV'', ''~/.bash_profile'')']);
end

%% Convert freesurfer label values to itkGray label values
% We want to convert
%   Left white:   2 => 3
%   Left gray:    3 => 5
%   Right white: 41 => 4
%   Right gray:  42 => 6
%   unlabeled:    0 => 0 (if fillWithCSF == 0) or 1 (if fillWithCSF == 1)          

% read in the nifti
ni = niftiRead(outfile);

% check that we have the expected values in the ribbon file
vals = sort(unique(ni.data(:)));
if ~isequal(vals, [0 2 3 41 42]')
    warning('The values in the ribbon file - %s - do no match the expected values [2 3 41 42]. Proceeding anyway...') %#ok<WNTAG>
end

% map the replacement values
invals  = [3 2 41 42];
outvals = [5 3  4  6];
labels  = {'L Gray', 'L White', 'R White', 'R Gray'};

fprintf('\n\n****************\nConverting voxels....\n\n');
for ii = 1:4
    inds = ni.data == invals(ii);
    ni.data(inds) = outvals(ii);
    fprintf('Number of %s voxels \t= %d\n', labels{ii}, sum(inds(:)));
end

if fillWithCSF
    ni.data(ni.data == 0) = 1;
end

% write out the nifti
writeFileNifti(ni)

% done.
return
