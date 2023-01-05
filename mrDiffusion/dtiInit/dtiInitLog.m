function dtiInitLog = dtiInitLog(dwParams,dwDir)
% 
%  dtiInitLog = dtiInitLog(dwParams,dwDir)
% 
% Return a structure that contains the the options and file names that were
% used to process a DWI dataSet. 
% 
% INPUTS
%       dwParams:   Structure passed in from dtiInit that contains all the
%                   parameter values used while preprocessing dwi data.
%       dwDir:      Structure passed in from dtiInit that contains all the
%                   files and directories used while preprocessing dwi
%                   data.
% RETURNS
%       dtiInitLog: Structure that contains the two input structures as
%                   well as: the date and time and svn/git information. 
%
% 
% Example:
%   dtiInitLog = dtiInitLog(dwParams,dwDir);
%
% 
% (C) Stanford Vista, 8/2011 [lmp]
% 

%% Initialize the structure and populate it with dwParams and dwDir ...
% 
dtiInitLog               = struct;
dtiInitLog.params        = dwParams;
dtiInitLog.dir           = dwDir;
dtiInitLog.date          = getDateAndTime;
dtiInitLog.system.os     = [getenv('OS') ' ' computer];
dtiInitLog.system.matlab = version;


%% Get specific system information
% 
if isunix && exist('/proc/version','file')
    cmd = 'cat /proc/version';
    [~, ver] = system(cmd);
    ver = regexprep(ver,'\r\n|\n|\r','');
    dtiInitLog.system.version = ver;
    
end

if strfind(dtiInitLog.system.os,'MAC')
    [~, out] = system('sw_vers -productVersion');
    out = regexprep(out,'\r\n|\n|\r','');
    dtiInitLog.system.os = [computer, ' - OSX ', out];
end


%% Try to figure out the subversion or git revision number 

rootPath = mrvDirup(mrvRootPath);
 
% Get the SVN info for the repo
if exist(fullfile(mrvDirup(mrvRootPath),'.svn'),'dir')
    try
        cmd = ['svn info ' rootPath ];
        [~, svn] = system(cmd); 
        dtiInitLog.svn = svn;
    catch ME
        disp(ME.message);
    end
end

% Get the GIT info for the repo
if exist(fullfile(mrvDirup(mrvRootPath),'.git'),'dir')
    try
        cmd = [ 'git --git-dir ' [rootPath '/.git'] ' config --get remote.origin.url'];
        [~, origin] = system(cmd);
        origin = regexprep(origin,'\r\n|\n|\r','');
        dtiInitLog.git.origin = origin;
        
        cmd = [ 'git --git-dir ' [rootPath '/.git'] ' rev-parse HEAD'];
        [~, git] = system(cmd);
        git = regexprep(git,'\r\n|\n|\r','');
        dtiInitLog.git.checksum = git;
    catch ME
        disp(ME.message);
    end
end


%% Save the dtiInitLog structure as a logFile (.mat) in the data directory.
% 
logName =  'dtiInitLog.mat';

    % In some cases a log file might already exist. We will append the name
    % of the file in that case to include the date, provided the user does
    % not want to overwrite the previous files.
if exist(fullfile(dwDir.subjectDir,logName),'file') && dwParams.clobber ~= 1
    logName = ['dtiInitLog_' getDateAndTime '.mat'];
end

save(fullfile(dwDir.subjectDir,logName),'dtiInitLog');


return
