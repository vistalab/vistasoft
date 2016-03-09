%%  Publish vistasoft functional data on remote data server
%  (Archiva)
%
% These functional data are used as part of the mrvTest protocol. They
% accompany the validation data that are also stored on the remote site.
%
% BW did an svn update on the vistadata directory.  Then ran through this
% script.
%
% BW/ Copyright Vistasoft Team 2016

%% Open the remote data object

% Create remote data toolbox object
rd = RdtClient('vistasoft');

% To write to the archive, you must have a password
rd.credentialsDialog;

% Theses are the paths on the remote data server
p = rd.listRemotePaths;

%% First, copy the elements in the mrBOLD_01 directory
baseDir = fullfile(vistaRootPath,'..','vistadata','functional');
cd(baseDir);

% Note the the remote path and the local path match.
rd.crp('/functional/mrBOLD_01');
fullDirectory = fullfile(baseDir,'mrBOLD_01');

% Publish the files in the mrBOLD_01 directory.
rd.publishArtifacts(fullDirectory);


%% Now make the base mrBOLD_01 directory and publish the various subdirs

% Sometimes we have to go two deep.
baseDir = fullfile(vistaRootPath,'..','vistadata','functional','mrBOLD_01');
cd(baseDir)


%% Gray
rd.crp('/functional/mrBOLD_01/Gray');
fullDirectory = fullfile(baseDir,'Gray');
dir(fullDirectory)

rd.publishArtifacts(fullDirectory);
a = rd.listArtifacts;
a(:).artifactId

%% Inplane
rd.crp('/functional/mrBOLD_01/Inplane');
fullDirectory = fullfile(baseDir,'Inplane');
rd.publishArtifacts(fullDirectory);
a = rd.listArtifacts;
a(:).artifactId

%% Inplane/Original
rd.crp('/functional/mrBOLD_01/Inplane/Original');
fullDirectory = fullfile(baseDir,'Inplane','Original');
dir(fullDirectory)

rd.publishArtifacts(fullDirectory);
a = rd.listArtifacts;
a(:).artifactId

%% Inplane/ROIs
rd.crp('/functional/mrBOLD_01/Inplane/ROIs');
fullDirectory = fullfile(baseDir,'Inplane','ROIs');
dir(fullDirectory)

rd.publishArtifacts(fullDirectory);
a = rd.listArtifacts;
a(:).artifactId

%% Raw
rd.crp('/functional/mrBOLD_01/Raw');
fullDirectory = fullfile(baseDir,'Raw');
dir(fullDirectory)

rd.publishArtifacts(fullDirectory);
a = rd.listArtifacts;
a(:).artifactId

%% 3DAnatomy
rd.crp('/functional/mrBOLD_01/3DAnatomy');
fullDirectory = fullfile(baseDir,'3DAnatomy');
dir(fullDirectory)

rd.publishArtifacts(fullDirectory);
a = rd.listArtifacts;
a(:).artifactId

%% Volume
rd.crp('/functional/mrBOLD_01/Volume');
fullDirectory = fullfile(baseDir,'Volume');
dir(fullDirectory)

rd.publishArtifacts(fullDirectory);
a = rd.listArtifacts;
a(:).artifactId

%%