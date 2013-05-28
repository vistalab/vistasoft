function [niftiRoiName, niftiRoi] = fs_labelFileToNiftiRoi(fs_subject,labelFileName,niftiRoiName,hemisphere,regMgzFile,smoothingKernel)
%
% Creates a nifti-1 ROI from a FreeSurfer .label file.
%
%  [niftiRoiName, niftiRoi] = fs_labelFileToNiftiRoi(fs_subject,labelFileName,niftiRoiName,[hemisphere],[regMgzFile],[smoothingKernel])
%
% This function loads a FreeSurfer label file and generates an volume nifti
% with the numerical values of the label at the x,y,z location of the label.
% 
% INPUTS:
%      fs_subject    - The FreeSurfer folder for the subject. It is
%                      a folder under $SUBJECTS_DIR
%      labelFileName - The fullpath to a .label FreeSurfer file.
%      niftiRoiName  - The fullpath to the .nii.gz file that will
%                      be saved out. With NO .nii.gz extension.
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
%     smoothingKernel- Size in mm of the smoothing kernel applied to the ROI.  
%
% OUTPUTS:
%        niftiRoiName - The fullpath to where the nifti file was written.
%        niftiRoi     - The nifti-1 structure just created.
% 
% EXAMPLE USAGE: 
%       labelFileName = '/biac2/wandell2/data/anatomy/pestilli_test/label/lh.V1.label'
%       niftiRoiName  = '/biac2/wandell2/data/anatomy/pestilli_test/label/lh_V1.nii.gz';
%       regMgzFile    = '/biac2/wandell2/data/anatomy/pestilli_test/mri/rawavg.mgz';
%       fs_labelFileToNiftiRoi(labelFileName,niftiRoiName,regMgzFile);
% 
% Written by Franco Pestilli (c) Stanford University, Vistasoft 2013
    
fsSubDir = getenv('SUBJECTS_DIR');
    
% Get the .label file. 
if notDefined('labelFileName')
    [fileName, path] = uigetfile({'*'},'Select the Freesurfer .label file',fsSubDir);    
    if isnumeric(fileName); disp('Canceled by user.'); return; end
    labelFileName = fullfile(path,fileName);
else
    p = fileparts(labelFileName);
    if isempty(p)
        labelFileName = fullfile(fsSubDir,fs_subject,'label',labelFileName);       
        fprintf('\n[%s] Label name passed without fullpath.\n Assuming that the label in default location:\n%s\n', ...
            mfilename,labelFileName)

    end
end

if notDefined('hemisphere')
    fprintf('\n[%s] No hemisphere passed in.\n assuming that the label isstored under the FreeSurfer subject folder.\n',mfilename)
    [~,f] = fileparts(labelFileName);
    hemisphere = f(1:2); 
end

if notDefined('regMgzFile')
    fprintf('[%s] No registration file passed in, attempting to register to  %s/%s/mri/rawavg.mgz.\n', ...
            mfilename,fsSubDir,fs_subject) 
    regMgzFile = fullfile(fsSubDir,fs_subject,'mri/rawavg.mgz');
end

if notDefined('niftiRoiName')
   error('[%s] the name for the output file (niftiRoiName) is necessary...',mfilename)
else
    p = fileparts(niftiRoiName);
    niftiRoiName(niftiRoiName == '.') = '_';
    if isempty(p)
        niftiRoiName = fullfile(fsSubDir,fs_subject,'label',niftiRoiName);       
        fprintf('\n[%s] niftiRoiName name passed without fullpath.\n Saving the ROI in FS default location:\n%s\n', ...
            mfilename,niftiRoiName)
    end
end

if notDefined('smoothingKernel')
    smoothingKernel = 3;   
end
niftiRoi = [];

% Now we need to create a temporary registration file.
% 
% That will inform mri_lable2vol how to align the label 
% to the space we want.
tmpRegFile = tempname(tempdir);
cmd = sprintf('!tkregister2 --mov %s --subject %s --noedit --regheader --reg %s.dat',...
      regMgzFile,fs_subject,tmpRegFile);
eval(cmd);

% Create the nifti file for the label.
%
% --proj frac 0 1 .1 % fill in all the cortical gray matter
% --fillthresh .3    % require that a  voxel be filled at least 30% by the label
cmd = sprintf('!mri_label2vol --subject %s --label %s --o %s.nii.gz --hemi %s --reg %s.dat --temp %s --proj frac 0 1 .1 --fillthresh .01', ...
      fs_subject,labelFileName,niftiRoiName,hemisphere, tmpRegFile,  regMgzFile);
eval(cmd);

% Smooth the FreeSurfer ROI they tend to be a bit sparse.
if smoothingKernel > 0
    fprintf('[%s] Smoothing the ROI before saving the nifti file.\n',mfilename)
    niftiRoi       = niftiRead(niftiRoiName);
    niftiRoi.data  = single(dtiCleanImageMask(niftiRoi.data,smoothingKernel));
    niftiRoi.fname = sprintf('%s_smooth%imm', niftiRoiName, smoothingKernel);
    niftiWrite(niftiRoi);
end

% We return the nifti strutcture as second output
if nargout == 2
    if isempty(niftiRoi)
        niftiRoi = niftiRead(niftiRoiName);
    end
end

end