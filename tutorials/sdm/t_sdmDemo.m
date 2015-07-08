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
sdmFile = [tempname,'.nii.gz'];
urlwrite(link,sdmFile);

% Read the temporary file
data = niftiRead(sdmFile);


%% Prove that you ahve the data
showMontage(data.data,[64:67])

%% Do something with the data.  In this case BET

% Set up the command
fslDir = '/usr/lib/fsl/5.0';
betName = 'bet2.nii.gz';
cmd = sprintf('%s/bet2 %s %s\n',fslDir,sdmFile, betName);

% Execute
system(cmd);

%% View the extracted brain
bData = niftiRead('bet2.nii.gz');
showMontage(bData.data,[64:67]);


%% Put the brain extraction data back into the database

% The curl command worked fine from the terminal.
% It failed because of some Matlab interference with the error message
%   /usr/bin/curl: /share/software/MATLAB-R2014a/bin/glnxa64/libcurl.so.4: no version information available (required by /usr/bin/curl)
%   curl: (48) An unknown option was passed in to libcurl

% Here is how we build up the curl PUT command
% <file_name_on_disk>
% betName

% <md5_check_sum>
cmd = sprintf('md5sum %s',betName);
[status,result] = system(cmd);
checkSum = result(1:32);

% <URL_and_file_name>
url = fileparts(pLink);
urlAndName = fullfile(url,betName);

% <user_name>
% uName

cmd = sprintf('/usr/bin/curl -X PUT --data-binary @%s -H "Content-MD5:%s" -H "Content-Type:application/octet-stream" "%s?user=%s&flavor=attachment"',betName,checkSum,urlAndName,uName);
cmd = ['xterm -e ',cmd]; 
[status, result] = system(cmd);
status

% curl -X PUT --data-binary @<file_name_on_disk> -H "Content-MD5:<md5_check_sum>" -H "Content-Type:application/octet-stream" "<URL_and_file_name>?user=<user_name>&flavor=attachment"

s
%% Clean up
delete(sdmFile);

%% END

