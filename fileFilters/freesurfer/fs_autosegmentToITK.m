function fs_autosegmentToITK(subjID, t1, skipRecon, resample_type)
% Autosegment a t1 weighted anatomical scan using freesurfer
% autosegmentation, and then generate a nifti segmentation file in the
% space and at the resolution of the t1. This function requires that you
% have freesurfer in your shell path.
%
% fs_autosegmentToITK(subjID, t1, [skipRecon], [resample_type])
%
% INPUTS:
%   subjID: directory name in which freesurfer stores outputs
%   t1:     file name (with complete path) of t1 used for segmentation.
%
%   skipRecon: boolean. If true, then we regenerate a t1 class file (nifti)
%       `       from the already complete freesurfer segementation, without
%               re-doing the freesurfer segmentation. [default = false]
%   resample_type: resample type used by freesurfer for resmapling 1x1x1 mm
%               aseg file to the resolution of the t1. Options are
%               'nearest' and 'weighted'. Other options exist (like
%               'trilinear' but do not make sense as the resampling must
%               preserver integer values. [default = 'nearest']
%
% Example:
%   subjID  = 'jw';
%   t1      = fullfile('biac2/wandell2/data/anatomy/winawer/Anatomy20110308', 't1.nii.gz');
%   fs_autosegmentToITK(subjID, t1)
%
% 3/11/2009 Written by JW and HH.
% 6/30/2011 JW: added  'skipRecon' and 'resample_type' as optional input
%               arguments. Change the resample procedure to read the
%               deseried voxel size from the t1 file.
%
%
% see also fs_ribbon2itk.m


%% Check Inputs & Paths

% subjID is the name of the directory that will be created by freesurfer to
% store segmentation and associated files.
if ~exist('subjID', 'var')
    warning('Subject ID is required input'); %#ok<WNTAG>
    eval('help fs_autosegmentToITK');
    return
end

% Get the path to the t1 file if it is not inputed. This can be any
% resolution. Freesurfer will resample to 1x1x1 for autosegmentation. We
% will extract a segmentation at the resolution of the original t1 at the
% end of this function.
if notDefined('t1') || ~exist(t1, 'file'),
    [fname pth] = uigetfile({'t1*.nii.gz', 'T1 files'; '*.nii', '.nii files'; '*.gz', '.gz files'}, 'Cannot locate T1 file. Please find it yourself.', pwd);
    t1 = fullfile(pth, fname);
end
if ~exist(t1, 'file'), error('Cannot locate t1 file'); end

if ~exist('skipRecon', 'var') || isempty(skipRecon)
    skipRecon = false;
end
if ~exist('resample_type', 'var') || isempty(resample_type)
    resample_type = 'nearest'; 
end

% This is the directory where freesurfer puts subject data. If it is
% defined in the linux shell (e.g., bashrc) then matlab can find it. If it
% is not defined, look for the 'freesurfer_home/subjects', which is the
% default location in freesurfer. 
subdir   = getenv('SUBJECTS_DIR');

if isempty(subdir),
    fshome = getenv('FREESURFER_HOME');
    subdir = fullfile(fshome, 'subjects');
end


%% recon all (freesurfer will resample to 1 mm isotropic)
%
if ~skipRecon,
    msg = sprintf('!recon-all -i %s -subjid ''%s'' -all', t1, subjID);
    eval(msg)
end

%
%% Resample aseg into nifti res (if nifit is not [1 1 1] mm)
% -rl flag reslices like the anatomical volume (t1)
% -rt uses nearest neighbour interpolation
%

% check whether t1 is [1 1 1] (freesurfer standard resolution). if not we
% need to resample the segmentation.

ni  = niftiRead(t1);
res = ni.pixdim;
if any(abs(res(1:3) - [1 1 1]) > .000001), 
    resampleSeg = true;
else 
    resampleSeg = false;
end

if resampleSeg
    msg = sprintf('cd(fullfile(''%s'', ''%s'', ''mri''))', subdir, subjID);
    eval(msg);
    
    % now make aseg file at resolution of the t1
    % back up 1-mm aseg.mgz and all ribbon files
    if ~exist('1mm', 'dir')
        mkdir('1mm');
        !mv *ribbon* aseg.mgz 1mm/
    end
    
    msg = sprintf('!mri_convert 1mm/aseg.mgz -o aseg.mgz -rt %s -voxsize %f %f %f', resample_type, res(1), res(2), res(3));
    eval(msg);
    
    %Recreate ribbon files at t1 resolution
    msg = sprintf('!mris_volmask --label_left_white 2 --label_left_ribbon 3 --label_right_white 41 --label_right_ribbon 42 --save_ribbon --save_distance ''%s'' ', subjID);
    eval(msg);

    % back up new segmentation files
    if ~exist('resampledSeg', 'dir'), mkdir('resampledSeg'); end
    !cp *ribbon* aseg.mgz resampledSeg/
end



%% Convert segmentation from mgz to nifti at resolution of nifti
outfile     = fullfile(fileparts(t1),...
    sprintf('t1_class_fs_%s.nii.gz',  datestr(now, 'yyyy-mm-dd-HH-MM-SS')));
fillWithCSF = true;
alignTo     = t1;
fs_ribbon2itk(subjID, outfile, fillWithCSF, alignTo);



%%
return
