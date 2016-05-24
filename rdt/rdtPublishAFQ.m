%% Upload templates and subject data from AFQ to Archiva
%

rd = RdtClient('vistasoft');
rd.credentialsDialog;

%% Templates
cd(vistaRootPath);
cd(fullfile('..','AFQ'))
baseDir = pwd;
fullDir = fullfile(baseDir,'templates');

rd.crp('/AFQ/templates');

a = rd.publishArtifacts(fullDir);

%% List the artifacts it thinks it sent up
for ii=1:length(a)
    disp(a(ii).artifactId)
end

%% List, but this time ask the repository for the list
rd.crp('/AFQ/templates/');
a = rd.listArtifacts;

%% Now the AFQ data sets

% These are in AFQ/data
% So the base directory starts at AFQ
% We will then move into AFQ/data and the subdirectories
cd(vistaRootPath);
cd(fullfile('..','AFQ'))
baseDir = pwd;

% First the afq.mat file
rd.crp('/AFQ/data');
fullDir = fullfile(baseDir,'data');
rd.publishArtifacts(fullDir);

% rd.openBrowser('fancy',true)

%%  Find the directory tree under AFQ/data
cd(vistaRootPath);
cd(fullfile('..','AFQ','data'))
baseDir = pwd;

pNames = dirwalk(baseDir);

nDirs = length(pNames);
for ii=1:nDirs
    fullDir = pNames{ii};
    remotePath = strrep(pNames{ii},'/Users/wandell/Github','');
    rd.crp(remotePath);
    rd.publishArtifacts(fullDir);
end

%%




