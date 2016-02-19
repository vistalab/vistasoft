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

%% List the artifacts
for ii=1:length(a)
    disp(a(ii).artifactId)
end

%%
rd.crp('/AFQ/templates/');
a = rd.listArtifacts;

%% Now the data sets
rd.crp('/AFQ/data');
rd.publishArtifacts('data');

