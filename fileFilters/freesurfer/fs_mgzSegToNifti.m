function outName = fs_mgzSegToNifti(mgzIn, refImg, outName, orient)

% function fs_mgzSegToNifti([mgzIn=mrvSelectFile],[refImg=mrvSelectFile],...
%                           [outFileName],[orient])
% 
% This function will take a mgz segmentation file and convert it to nifti
% using mri_convert.
% 
% You can set the out_orientation (orient) and the reference image which
% you would like the code to use during reslicing (refImg). Oreient
% defaults to RAS.
% 
% By default the code will write out the same file name (with a different
% extention) within the same directory, but you can change this if you use
% outFileName to set a different file name/path.
% 
% NOTE: You must have freesurfer tools in your path for this function to
%       work. For help with this see
%       http://white.stanford.edu/newlm/index.php/FreeSurfer
% 
% EXAMPLE: 
%       mgzIn = '/home/lmperry/software/freesurfer/subjects/JB5/mri/aseg.mgz'
%       refImg = '/biac3/wandell5/data/Epilepsy/5-jb/DTI/t1.nii.gz'
%       outName = '/home/lmperry/software/freesurfer/subjects/JB5/mri/aseg.nii.gz'
%       orient = 'RAS'
%       fs_mgzSegToNifti(mgzIn, refImg, outName, orient);
%       
% 
% HISTORY: 
%       2011.03.22 - LMP Wrote the thing.

%%
if notDefined('mgzIn') || ~exist(mgzIn,'file')
    mgzIn = mrvSelectFile('r','*.mgz','Select MGZ file for conversion to nifti.',pwd);
end

if notDefined('refImg') || ~exist(refImg,'file')
    refImg = mrvSelectFile('r','*.nii.gz', ... 
        'Please select a reference image file for alignment of the segemntation.',pwd);
end

if notDefined('outName') 
    [p, n] = fileparts(mgzIn);
    outName = fullfile(p,[n '.nii.gz']);
end

if notDefined('orient')
    orient = 'RAS';
end

cmd = ['!mri_convert --out_orientation ' orient ' -rt nearest --reslice_like ' refImg ' ' mgzIn ' ' outName];
eval(cmd);

fprintf('%s has been saved.\n',outName);

return