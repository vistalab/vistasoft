function saveSession(queryFlag)
%Save the mrSESSION file in HOMEDIR.
%
%  saveSession([queryFlag=0])
%
% 3/26/2001, djh, updated to version 3.0 to also save dataTYPES structure.
% 06/06, ras -- doesn't save any over other info (like vANATOMYPATH) 
% that may already be present in the file.
% 10/06, ras -- auto saves a backup file, to help prevent saving over data.

global mrSESSION
global HOMEDIR
global dataTYPES
global vANATOMYPATH

if ~exist('queryFlag','var')
    queryFlag=0;
end

if isempty(HOMEDIR)
    warning(['Writing mrSESSION to: ',pwd]);
    pathStr = fullfile(pwd,'mrSESSION.mat');
else
    pathStr = fullfile(HOMEDIR,'mrSESSION.mat');
end

% save a backup if there's an existing file
if exist(pathStr, 'file')
    tmp = load(pathStr);
    save('mrSESSION_backup.mat', '-struct', 'tmp');
end

% The query flag says ask if the mrSESSION file already exists.
if exist(pathStr, 'file') && queryFlag
    but = questdlg('Over-write existing mrSESSION file?');
    switch but
    case 'Yes',
        save(pathStr,'mrSESSION','dataTYPES', 'vANATOMYPATH');
    otherwise
    end
else
    if exist(pathStr,'file')
        save(pathStr,'mrSESSION','dataTYPES', 'vANATOMYPATH', '-append');
    else
        save(pathStr,'mrSESSION','dataTYPES', 'vANATOMYPATH');
    end        
end

return;
