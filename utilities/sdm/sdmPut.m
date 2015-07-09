function sdmPut(pLink,uName,fname)
% Attach a file to the permalink location
%
%      sdmPut(pLink,uName,fname)
%
%  pLink:   Permalink from an SDM instance
%  fname:   Name of the file to attach
%  uName:   Login of the user with permission to upload to the pLink
%
% Example
%
% LMP/BW Vistasoft Team, 2015

% Build the url from the permalink by removing the endpart
url = fileparts(pLink);

if ismac
    % True on Mac, but not on Linux/Ubuntu
    cmd = sprintf('md5 %s',fname);
    [status,result] = system(cmd);
    if status, warning('System checksum command may have failed'); end
    checkSum = result(end-32:end-1);
    
    % <URL_and_file_name>
    [~,n,e] = fileparts(fname);
    urlAndName = fullfile(url,[n,e]);
    
    % curl -X PUT --data-binary @<file_name_on_disk> -H "Content-MD5:<md5_check_sum>" -H "Content-Type:application/octet-stream" "<URL_and_file_name>?user=<user_name>&flavor=attachment"
    cmd = sprintf('/usr/bin/curl -v -X PUT --data-binary @%s -H "Content-MD5:%s" -H "Content-Type:application/octet-stream" "%s?user=%s&flavor=attachment"',fname,checkSum,urlAndName,uName);
    
    % Execute the command
    % On Mac we not have to set up the right library path
    % curENV = getenv('LD_LIBRARY_PATH');
    % setenv('LD_LIBRARY_PATH','/usr/lib:/usr/local/lib');
    [status, result] = system(cmd,'-echo');
    if status
        warning('System curl command failed'); 
        disp(result)
    end
    % setenv('LD_LIBRARY_PATH','');

elseif (isunix && ~ismac)
    % Returns true on mac, so it must second
    cmd = sprintf('md5sum %s',fname);
    [status,result] = system(cmd);
    if status, warning('System checksum command may have failed'); end
    checkSum = result(1:32);
    
    % <URL_and_file_name>
    [~,n,e] = fileparts(fname);
    urlAndName = fullfile(url,[n,e]);
    
    % curl -X PUT --data-binary @<file_name_on_disk> -H "Content-MD5:<md5_check_sum>" -H "Content-Type:application/octet-stream" "<URL_and_file_name>?user=<user_name>&flavor=attachment"
    cmd = sprintf('/usr/bin/curl -X PUT --data-binary @%s -H "Content-MD5:%s" -H "Content-Type:application/octet-stream" "%s?user=%s&flavor=attachment"\n',fname,checkSum,urlAndName,uName);
    
    % On Linux we have to set up the right library path
    curENV = getenv('LD_LIBRARY_PATH');
    setenv('LD_LIBRARY_PATH','/usr/lib:/usr/local/lib');
    
    % Execute the command
    [status,result] = system(cmd,'-echo');
    if status
        warning('System curl command failed'); 
        disp(result)
    end
    setenv('LD_LIBRARY_PATH',curENV);
    
  
elseif ispc
    error('Not tested from PC yet');
else
    error('Unknown computer type.\n');
end



end