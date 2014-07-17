function dtiDt6Migrate(rawDir)
%
% Migrate a dt6 structure from a previosu cfolder to the current folder. 
%
%      >> dtiDt6Migrate
%
% This function will update all the paths in the dt6 structure after a dt6
% file is moved to a new folder.
%
% USAGE:
%    (1) move a dt6 directory structure from its original location to a new
%        location.
%    (2) cd into the new location of the dt6.mat file
%    (3) type: dtiDt6Migrate, to update all the path information inside the
%        dt6.mat strucutre.
%    (4) A new file called dt6.mat is created in the current directory.
%        A copy of the dt6 file before any change was made is copied over
%        to a file dt6_old.mat
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