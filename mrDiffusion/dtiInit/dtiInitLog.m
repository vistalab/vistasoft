function initLog = dtiInitLog(dwParams,dwDir)
% 
%  initLog = dtiInitLog(dwParams,dwDir)
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
%       initLog:    Structure that contains the two input structures as
%                   well as: the date and time and svn information. 
%
% Web Resources
%       mrvBrowseSVN('dtiInitLog');
% 
% Example:
%   initLog = dtiInitLog(dwParams,dwDir);
%
% 
% (C) Stanford Vista, 8/2011 [lmp]
% 

%% Initialize the structure and populate it with dwParams and dwDir ...
% 
initLog         = struct;
initLog.params  = dwParams;
initLog.dir     = dwDir;
initLog.date    = getDateAndTime;
initLog.system.os  = [getenv('OS') ' ' computer];


%% Try to figure out the subversion revision number 
%
try
    rootPath = mrvDirup(mrvRootPath);
    cmd = ['svn info ' rootPath ]; 
    [tmp, svn] = system(cmd); %#ok<ASGLU>
    initLog.svn = svn;
catch, disp('Can"t determine svn version.'); %#ok<CTCH>
end


%% Get specific linux system information
% 
if isunix
    cmd = 'cat /proc/version'; 
    [tmp, ver] = system(cmd); %#ok<ASGLU>
    initLog.system.version = ver;
end


%% Save the initLog structure as a logFile (.mat) in the data directory.
% 
logName =  'dtiInitLog.mat';

    % In some cases a log file might already exist. We will append the name
    % of the file in that case to include the date, provided the user does
    % not want to overwrite the previous files.
if exist(fullfile(dwDir.dataDir,logName),'file') && dwParams.clobber ~= 1
    logName = ['dtiInitLog_' getDateAndTime '.mat'];
end

save(fullfile(dwDir.dataDir,logName),'initLog');


return
