function cmd = fs_annotationToLabelFiles(fs_subject,annotationFileName,hemisphere,labelsDir)
%
% Creates .label files from a FreeSurfer annotation file, which is created
% during the reconall segementation and percellation process.
%
%  cmd = fs_annotationToLabelFiles(fs_subject,[annotationFileName],[hemisphere],[regMgzFile])
%
% 
% INPUTS:
%      fs_subject    - The FreeSurfer folder for the subject. It is
%                      a folder under $SUBJECTS_DIR
%      annotationFileName - The fullpath to a .annotation FreeSurfer file.
%      hemisphere    - Optional. Either 'lh' or 'rh'. This is necessary to load the
%                      FreeSurfer surface and fill in the ROi into the
%                      gray matter. If this inptu is omitted we assume that
%                      the labelFileName lives under: 
%                      $SUBJECTS_DIR/<this_subject>/label/
%                      and that the file name starts with either 'lh' or
%                      'rh' which is the standard for labels created
%                      automatically with the FreeSurfer autsegmentation.
% 
%      regMgzFile    - Optional. The fullpath to a file to be used for registering
%                      the nifti ROI. Generally we register everything to
%                      ACPC, which means to the T1 volume. 
%                      If the regMgzFile is NOT passed in and the file 
%                      $SUBJECTS_DIR/<this_subject>/mri/rawavg.mgz exists,
%                      we align automatically to such file. Which is our
%                      standard for ACPC.
%
% OUTPUTS:
%        cmd - is a cell array with the FreeSurfer commands launched in the shell.
%              Note: .label files will be written directly on disk. A list of
%              the files will be shown in the matlab prompt.
% 
% EXAMPLE USAGE: 
%   fsDir          = getenv('SUBJECTS_DIR');
%   subject        = 'subject';
%   hemisphere     = 'lh'; 
%   annotation     = 'aparc'; 
%   annotationFile = fullfile(fsDir,subject,'label',annotation);
%   cmd            = fs_annotationToLabelFiles(subject,annotationFile)
%
% Written by Franco Pestilli (c) Stanford University, Vistasoft 2013
fsSubDir   = getenv('SUBJECTS_DIR');

% Get the .label file. 
if notDefined('annotationFileName')
   error('[%s] Annotation file name necessary...',mfilename)
end

if notDefined('hemisphere')
    error('\n[%s] No hemisphere passed in.\n Running command for both hemispheres.\n',mfilename)
    hemisphere = {'rh','lh'}; 
end

if notDefined('regMgzFile')
    fprintf('[%s] No registration file passed in, attempting to register to:\n%s/%s/mri/rawavg.mgz.\n', ...
            mfilename,fsSubDir,fs_subject) 
    regMgzFile = fullfile(fsSubDir,fs_subject,'mri/rawavg.mgz');
end

if notDefined('labelsDir')
    labelsDir = fullfile(fsSubDir,fs_subject,'label');
   fprintf('\n[%s] No output direcory for the labels passed in.\n Saving labels in default location:\n%s\n',mfilename, labelsDir)
end

if ~iscell(hemisphere) && ischar(hemisphere)
    hemisphere = {hemisphere};
end

% Now create all labels in the parcellation
for icmd = 1:length(hemisphere)
    cmd{icmd} = sprintf('!mri_annotation2label --subject %s  --hemi %s --annotation %s --outdir %s ', ...
        fs_subject,hemisphere{icmd},annotationFileName,labelsDir);
    eval(cmd{icmd});
end

end