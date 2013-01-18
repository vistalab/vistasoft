function dirS = GetDirectory(dirName,ask)
% Select or build a new recon directory
%
%   dirS = GetDirectory(dirName,ask);
%
% Starting with the input directory name, select or build a new
% recon directory. 
% dirS is a structure with fields:
%   output:   Absolute directory spec. for the writable home directory
%   raw:      Absolute dir. spec. for raw anatomy and Pfiles
%
% If the directories don't exist, then this routine will create them.  You
% can suppress asking for verification with by setting the ask flag to 0
%
% DBR, 3/99

if notDefined('ask'), ask = 1; end

dirS.home = dirName;
dirS.raw = fullfile(dirName,'Raw');
while ~ValidDirectory(dirS.home,dirS.raw)
    if ask, dirS = GetDirEdit(dirS); end 
    if ~CreateDirectories(dirS.home)
        Alert(['Problems creating session directory ', dirName]);
    end
end

% Make a link from /usr/local/mri to the new recon.
if isunix
    [path, name] = fileparts(dirS.home);
    [path, expName] = fileparts(path);
    linkDir = ['/usr/local/mri/', expName];
    if exist(linkDir, 'dir')
        link = [linkDir, filesep, name];
        if ~exist(link, 'file')
            unix(['ln -s ', dirName, ' ', link]);
        end
    end
end

return;
