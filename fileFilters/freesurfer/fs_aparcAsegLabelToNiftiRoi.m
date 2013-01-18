function fs_aparcAsegLabelToNiftiRoi(fsIn,labelVal,outName)

% function fs_aparcAsegLabelToNiftiRoi(fsIn,labelVal,[outName])
% 
% This function will take a freesurfer segmentation file (fsIn =
% aparc+aseg.nii) and convert specific lables within it to a nifti roi.
% 
% By default the code will write out the same file name (with a different
% extention) within the same directory, but you can change this if you use
% outFileName to set a different file name/path.
% 
% NOTE: You must have FSL tools in your path for this function to
%       work. For help with this see
%       http://white.stanford.edu/newlm/index.php/FSL
% 
% SEE:  http://surfer.nmr.mgh.harvard.edu/fswiki/FsTutorial/AnatomicalROI/FreeSurferColorLUT
%       for help with naming the labels.
% 
% SEE:  fs_mgzSegToNifti to convert the aparc+aseg.mgz file to nii.
% 
% EXAMPLE: 
%       fsIn = '/home/lmperry/software/freesurfer/subjects/JB5/mri/aparc+aseg.nii'
%       labelVal = '1026';
%       outName = '/home/lmperry/software/freesurfer/subjects/JB5/mri/rostralanteriorcingulate.nii'
%       fs_aparcAsegLabelToNiftiRoi(fsIn,labelVal,outName)
%       
% 
% HISTORY: 
%       2011.03.22 - LMP Wrote the thing.


if notDefined('fsIn') || ~exist(fsIn,'file')
    help fs_aparcAsegLabelToNiftiRoi;
    error('You must provide the path to the aparc+aseg nifti file!');
end

if notDefined('labelVal')
    error('You must provide a label value.')
end

if notDefined('outName') 
    [p n] = fileparts(fsIn);
    outName = [p '/' n labelVal '.nii'];
end

!export FSLOUTPUTTYPE=NIFTI

cmd = ['!fslmaths ' fsIn ' -thr ' labelVal ' -uthr ' labelVal ' -bin ' outName];
echoCmd = ['!echo ' cmd];
eval(echoCmd);
eval(cmd);

fprintf('%s has been saved.\n',outName);

return