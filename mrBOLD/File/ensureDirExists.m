function [status, errmsg] = ensureDirExists(pth)
% Make sure a directory exists, creating parent directories if needed
%
%  [status, errmsg] = ensureDirExists(pth);
%
% Status = 1 if the path exists or is successfully created, 0 otherwise. 
%
% ras 06/06.

if ~ischar(pth), help(mfilename); error('Need a path string'); end

status = 0;
errmsg = '';

if exist(fullpath(pth),'dir') & ~isequal(pth(2),'\')
    % Person sent in a full path that exists.  We are done.
    status = 1;
    return
end

% The person sent in a path that doesn't fully exist.  So we are going to
% live dangerously and create the path for them.  Part of the path might
% exist, and we follow that down, until we start creating the new elements
% of the path.
%

% find all the directory strings
clear subdirs
if isequal(pth(2),'\')
    % Trap the case when we have a mount: \\white.stanford.edu, for example
    tmpPath = pth(3:end);
    tmpPath = ['C:\',tmpPath];  % Cheap hack to make explode work
    tmpSubDirs = explode(filesep,tmpPath);
    subdirs = cell(1,length(tmpSubDirs) - 1);
    for ii=2:length(tmpSubDirs)
        subdirs{ii-1} = tmpSubDirs{ii};
    end
    % Append the \\ in front of the computer name
    tmp = subdirs{1}; tmp = ['\\',tmp]; subdirs{1} = tmp;
else
    subdirs = explode(filesep, fullpath(pth));
end



% step through each subdir, progressively checking
% child directories within parent dirs
if isunix,  par = [filesep subdirs{1}];
else        par = subdirs{1};
end

for ii = 2:length(subdirs)
    if ~exist(fullfile(par,subdirs{ii}),'dir')
        try
            [status, errmsg] = mkdir(par,subdirs{ii});
        catch
            fprintf('ensureDir Exists: Creation of intermediate dir failed: ')
            fprintf('%s\n',errmsg)
            return
        end
        fprintf('Created directory %s%s%s\n',par,filesep,subdirs{ii});
    end
    
    par = fullfile(par,subdirs{ii});
end

status = 1;

return


