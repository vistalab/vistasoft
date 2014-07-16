function nfgCreateBMTestDir(phantomDir)
%Create BlueMatter test directory for a phantom data set
%
%   nfgCreateBMTestDir(phantomDir)
%
% This creates the following directories: phantomDir/bluematter, 
%   phantomDir/bluematter/raw, phantomDir/bluematter/dti**
%
% Inside the raw directory the ideal phantom data from the phantomDir/clean
%   is stored as well as the noisy data as a single NIFTI_GZ file.
%
% AUTHORS:
%   2009.08.05 : AJS wrote it
%
% NOTES: 
%   * For some reason I need to multiply the raw mri values by some offset
%     to get the numbers to be more similar to the ones expected by
%     dtiRawFitTensorMex -- See b0Factor in the code.
%   * I must also manually have the AcPc coordinates be the middle of the
%     image otherwise problems occur when using dtiFiberUI.
%   * Must clear the auto-generated brain mask that dtiRawFitTensorMex
%     produces for dtiFiberUI to work.

if ~isdir(phantomDir)
    error('Must provide a valid path to an NFG simulation phantom!');
end

% Directories
rawDir = nfgGetName('rawDir',phantomDir);
% Input Files
cleanImgFilter = nfgGetName('cleanImgFilter',phantomDir);
noisyImgFilter = nfgGetName('noisyImgFilter',phantomDir);
% Output Files
cleanImg = nfgGetName('cleanImg',phantomDir);
noisyImg = nfgGetName('noisyImg',phantomDir);

% Create new directories
disp(['Creating BlueMatter test directory for ' phantomDir ' ...']);
[s,mess,messid] = mkdir(phantomDir,'bluematter');
% Only continue if this is a fresh start
if strcmp(messid,'MATLAB:MKDIR:DirectoryExists')
    error('Error: Will not overwrite previous bluematter directory!!');
end
mkdir(rawDir);

disp(' '); disp('Compressing and copying images from NFG simulator ...');
% Merge clean images into one NIFTI_GZ file
cmd = ['fslmerge -a ' cleanImg ' ' cleanImgFilter];
disp(cmd);
system(cmd,'-echo');
% Merge noisy images into one NIFTI_GZ file
cmd = ['fslmerge -a ' noisyImg ' ' noisyImgFilter];
disp(cmd);
system(cmd,'-echo');

% Load dti-noisy and dti-clean in order to prepare them for dtiFitTensorMex
b0Factor = 1000;
disp(' '); disp(['Apply b0 offset factor of ' num2str(b0Factor) ' and AcPc offset to image center ...']);
ni = niftiRead(noisyImg);
ni.data = ni.data*b0Factor;
m = abs(ni.qto_xyz);
% Must add half voxel offset always for center of image
m(1:3,4) = - ni.pixdim(1:3) .* (ni.dim(1:3)/2+0.5);
im = inv(m);
im(1:3,4) = im(1:3,4) + 0.5; 
ni = niftiSetQto(ni,m);
writeFileNifti(ni);
ni = niftiRead(cleanImg);
ni.data = ni.data*b0Factor;
m = abs(ni.qto_xyz);
m(1:3,4) = - ni.pixdim(1:3) .* ni.dim(1:3)/2;
ni = niftiSetQto(ni,m);
writeFileNifti(ni);

disp(' '); disp('Setting up mrDiffusion files ...');
nfgSetupMRDiffusion(phantomDir);

disp(' '); disp('Done.');
return;
