function dtiDt6Migrate(rawDir)
% Fix the file dependencies stored in a dt6 structure 
%
% The dt6.files.aligned* are absolute paths, not relative.  This causes
% problems when we move to a new system.  We should be able to move the
% folder and have the code run.
%
% This function will update all the paths in the dt6 structure after a dt6
% file is moved to a new folder.
%
% Example:
%    Change to the dt6 file's folder and type
%    
%          dtiDt6Migrate
%
%   This creates a new file called dt6.mat is created in the current
%   directory. A copy of the dt6 file before any change was made is copied
%   over to a file dt6_old.mat
%
% See also:
%    dtiLoadDt6
%
% Written by Franco Pestilli (c) Vistasoft, Stanford University

% We assume that there is adt6 file in the current directory that we have
% just moved from a different directory. We will update the information in
% the dt6 file that we find in the current directory.
dt6NewDir = pwd;
subDir    = fileparts(dt6NewDir);

% (1) Load the dt6 file:
load('dt6.mat')

% (2) Find the raw directory in the path to the raw file
expression = params.subDir;

% (3) We change three fields in files
string       = files.alignedDwRaw;
[~,matchend] = regexp(string,expression);
params.subDir     = subDir;

if notDefined('rawDir')
rawDir            = params.rawDataDir(matchend+1:end);
end
params.rawDataDir = fullfile(subDir,rawDir);

[~, rawFile,ext]   = fileparts(files.alignedDwRaw);
files.alignedDwRaw = fullfile(params.rawDataDir,[rawFile,ext]);

[~, bvecsFile,ext]   = fileparts(files.alignedDwBvecs);
files.alignedDwBvecs = fullfile(params.rawDataDir,[bvecsFile,ext]);

[~, bvalsFile,ext]   = fileparts(files.alignedDwBvals);
files.alignedDwBvals = fullfile(params.rawDataDir,[bvalsFile,ext]);

% (4) We change two fields in params:

% (5) Move the current dt6 into a backup
movefile('dt6.mat', 'dt6_old.mat')

% (6) Update the dt6 information
save('dt6.mat','params','files','adcUnits')

end