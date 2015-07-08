%% t_sdmDemo
%
% Illustrate some SDM interactions.  Must be run on a system that has the
% FSL brain extraction tool.
%
% This example runs for an SDM instance at Stanford (SNI-SDM).  To run it
% for your example, you need to have the permalink (pLink) from your
% instance and the user name for that permalink.  
%
%  * use a permalink from the SNI-SDM to download a file
%  * read the file and display the contents
%  * run the brain extraction tool from FSL
%  * place the result (which is a NIFTI) as an attachment in the SDM
%
% tic; t_sdmDemo; toc;
%
% LMP,BW Vistasoft Team, Copyright 2015

%% Copy a permalink from tamagawa data set
%
% For this example it is the NIFTI file in sni-sdm for VISTALab
% tamagawa > 2015-01-25 10:37 - amd-ctl-11-yms > 2

% Paste the permalink here.  This is an example from SNI-SDM
% It is the first T1 nifti in the Tamagawa data set for subject
% amd-ctl-11-yms
pLink = 'https://sni-sdm.stanford.edu/api/acquisitions/558da2cf3113bb9e05daaf98/file/1.3.12.2.1107.5.2.32.35381.201501251039339033400814.0.0.0_nifti.nii.gz?user=';
uName = 'wandell@stanford.edu';

% Get the file from the SDM.  In this form is it saved in /tmp
sdmFile = sdmGet(pLink,uName);

%% Prove that you have the data

% Read the temporary file
data = niftiRead(sdmFile);
showMontage(data.data,[64:67])

%% Brain extraction tool on the data

% Set up the command
fslDir = '/usr/lib/fsl/5.0';
betName = 'bet2.nii.gz';
cmd = sprintf('%s/bet2 %s %s\n',fslDir,sdmFile, betName);

% Execute
system(cmd);
disp('Done')

%% View the extracted brain
bData = niftiRead('bet2.nii.gz');
showMontage(bData.data,[64:67]);

%% Put the brain extraction data back into the database

sdmPut(pLink,uName,betName);

%% If you have the publish/pdf document you can run this to document
%
%  pdfFile = publish('t_sdmDemo','pdf');
%  sdmPut(pLink,uName,pdfFile)
%


