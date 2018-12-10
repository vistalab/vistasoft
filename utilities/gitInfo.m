function gitinfo = gitInfo(rootpath)
% 
%  gitinfo = gitInfo(rootpath)
% 
% Return the origin (on github) and checkusm of a git repository. Works on
% linux or osx.
% 
% INPUT:
%       rootpath:   Location of the .git directory
% 
% OUTPUT:
%       gitinfo:    struct containing the origin and checksum of the git
%                   repo.
% 
% EXAMPLE USAGE:
% 
%       gitInfo(vistaRootPath)
% 
%           ans = 
% 
%                 origin: 'https://github.com/vistalab/vistasoft'
%               checksum: '96cb7d59ab7e9ab1f3323cbe8d228e48a73193c4'
%
% 
% (C) Stanford University, VISTA LAB, 2015
% 

%% Initialize i/o

% Output
gitinfo.origin   = '';
gitinfo.checksum = '';

% Input
if ~exist('rootpath','var');
    warning('No rootpath was passed in. Returning empty struct.');
    return
end


%% Get the GIT info for the repo

if ~isunix
    warning('Non-Unix OS detected. Returning empty struct.'); 
    return
end

if exist(fullfile(rootpath,'.git'),'dir')
    try
        % Get the origin URL
        cmd = [ 'git --git-dir ' [rootpath '/.git'] ' config --get remote.origin.url'];
        [~, origin] = system(cmd);
        origin = regexprep(origin,'\r\n|\n|\r','');
        gitinfo.origin = origin;
        
        % Get the checksum for this version.
        cmd = [ 'git --git-dir ' [rootpath '/.git'] ' rev-parse HEAD'];
        [~, git] = system(cmd);
        git = regexprep(git,'\r\n|\n|\r','');
        gitinfo.checksum = git;
    catch 
    end
end

return