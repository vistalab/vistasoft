function [status, result] = sdmPut(pLink,uName,fName)
% Attach a file to the permalink location
%
%      sdmPut(pLink,uName,fname)
%
% Inputs: 
%  pLink:   Permalink from an SDM instance, session or acquisition file
%  fname:   Name of the file on disk to attach 
%  uName:   Login ID of the user with permission to upload to the pLink
% 
% Outputs:
%  status:  Boolean indicating success (0) or failure (~=0)
%  result:  The output of the verbose curl command
%
% 
% Example:
%   pLink ='https://vista.scitran.stanford.edu/api/acquisitions/559e9c86c81ba9de1e95ad61/file/1.2.840.113619.2.283.4120.7575399.26065.1300464087.922_1_dicom.tgz?user='
%   uName = 'someuser@stanford.edu';
%   fName = '/Path/to/some/file/on/disk'
%   
%   [status, result] = sdmPut(pLink,uName,fName);
%
% LMP/BW Vistasoft Team, 2015


%% Parse inputs

% Build the url from the permalink by removing the endpart
url = fileparts(pLink);

% Get the URL with the file name appended to it
[~,n,e] = fileparts(fName);
urlAndName = fullfile(url,[n,e]);


%% Gemerate MD5 checksum 

% MAC
if ismac
    md5_cmd = sprintf('md5 %s',fName);
    [md5_status, md5_result] = system(md5_cmd);
    checkSum = md5_result(end-32:end-1);
      
% Linux
elseif (isunix && ~ismac)
    md5_cmd = sprintf('md5sum %s',fName);
    [md5_status, md5_result] = system(md5_cmd);
    checkSum = md5_result(1:32);
      
% Other/Unknown    
else
    error('Unsupported system.\n');
end

% Check that it worked
if md5_status 
    error('System checksum command failed'); 
end


%% Configure library paths for curl command to work properly

% MAC
if ismac
    curENV = getenv('DYLD_LIBRARY_PATH');
    setenv('DYLD_LIBRARY_PATH','');
  
% Linux
elseif (isunix && ~ismac)
    curENV = getenv('LD_LIBRARY_PATH');
    setenv('LD_LIBRARY_PATH','/usr/lib:/usr/local/lib');

% Other/Unknown   
else
    error('Unsupported system.\n');
end


%% Build and execute the command

% Build - Example: curl -X PUT --data-binary @<file_name_on_disk> -H "Content-MD5:<md5_check_sum>" -H "Content-Type:application/octet-stream" "<URL_and_file_name>?user=<user_name>&flavor=attachment"
curl_cmd = sprintf('/usr/bin/curl -v -X PUT --data-binary @%s -H "Content-MD5:%s" -H "Content-Type:application/octet-stream" "%s?user=%s&flavor=attachment"\n',fName,checkSum,urlAndName,uName);

% Execute the command
fprintf('Sending... ');
[status,result] = system(curl_cmd);

% Let the user know if it worked
if status
    warning('Upload failed');
    disp(result)
else
    fprintf('File sucessfully uploaded.\n');
end


%% Reset library paths

if ismac
    setenv('DYLD_LIBRARY_PATH',curENV);
elseif (isunix && ~ismac)
    setenv('LD_LIBRARY_PATH',curENV);
else
    error('Unsupported system.\n');
end


return
