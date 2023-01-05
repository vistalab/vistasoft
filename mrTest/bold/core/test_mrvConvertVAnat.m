function test_mrvConvertVAnat
%Validate that mrVista conversopm of vAanatomy.data to nifti works
%
%  test_mrvConvertVAnat()
%
% Tests: mrAnatConvertVAnatToT1Nifti
%
% INPUTS
%  No inputs
%
% RETURNS
%  No returns
%
% Example: test_mrvConvertVAnat()
%
% See also MRVTEST
%
% Copyright NYU team, mrVista, 2017



%% Convert vAnatomy.dat to nifti

% Get the vAnatomy.dat sample data file
vAnatFileName = mrtInstallSampleData('anatomy/anatomyV','vAnatomy',  [], [], 'filetype', 'dat');

% Convert it to nifti
newNiftiFileName = fullfile(tempdir,'vAnatomy.nii.gz');    
mrAnatConvertVAnatToT1Nifti(vAnatFileName,newNiftiFileName);

% Get a stored nifti file that corresponds to the vAnatomy
oldNifitFileName = mrtInstallSampleData('anatomy/anatomyV','t1.nii', [], [], 'filetype', 'gz');

%% Compare the nifti to some stored values
n0  = niftiRead(oldNifitFileName);
n1 = niftiRead(newNiftiFileName);

n0  = niftiApplyCannonicalXform(n0);
n1 = niftiApplyCannonicalXform(n1);

assertEqual(niftiGet(n0, 'qto_xyz'), niftiGet(n1, 'qto_xyz'));
assertEqual(niftiGet(n0, 'data'), niftiGet(n1, 'data'));
assertEqual(niftiGet(n0, 'dim'), niftiGet(n1, 'dim'));

