%% t_sdmDemo
%
% Illustrate some SDM interactions.  Must be run on a system that has the
% FSL brain extraction tool
%
%  * use a permalink from the SNI-SDM to download a file
%  * read the file and display the contents
%  * run the brain extraction tool from FSL
%  * place the result (which is a NIFTI) as an attachment in the SDM
%
%
% LMP,BW Vistasoft Team, Copyright 2015

%% Copy a permalink from tamagawa data set
%
% For this example it is the NIFTI file in sni-sdm for VISTALab
% tamagawa > 2015-01-25 10:37 - amd-ctl-11-yms > 2
%

% Paste the permalink here
pLink = 'https://sni-sdm.stanford.edu/api/acquisitions/558da2cf3113bb9e05daaf98/file/1.3.12.2.1107.5.2.32.35381.201501251039339033400814.0.0.0_nifti.nii.gz?user=';
uName = 'wandell@stanford.edu';
link = [pLink,uName];

%% Use urlwrwite to retrieve the data and store it
oName = [tempname,'.nii.gz'];
urlwrite(link,oName);

% Read the temporary file
data = niftiRead(oName);

% Clean up after yourself
delete(oName);

%% Prove that you ahve the data
showMontage(data.data)

%% Do something with the data.  In this case BET




%% END

