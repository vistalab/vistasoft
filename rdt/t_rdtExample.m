%% t_rdtExample
%
% Illustrates how to download a validation file from the remote data client
% set up by BSH and the ISETBIO team.  We are using this for VISTASOFT
% data, as well.
%
% 1. Make sure the Remote Data Toolbox is on your path. It can be cloned
% from ISETBIO on github as 
%
%   git clone https://github.com/isetbio/RemoteDataToolbox.git
%  
% 2. For now, we are testing in the rdt branch.
%
% The first section creates a remote data object
% Then we illustrate how to list the artifacts in the remote data server
%
% The section below shows how BW uploaded the validation data in the first
% place.
% 
% BW/VISTASOFT Team

%% To download vistasoft validation data using the remote data toolbox

% This creates the object, using the configuration data in the file
% rdt/rdt-config-vistasoft.json
rd = RdtClient('vistasoft');

% You can open a web-browser to view the repository this way
rd.openBrowser;

% You can see the structure just by typing rd

%% To see the full list of artifacts 

% Change into the validate working directory.  This way you will only see
% the validation artifacts
rd.crp('/validate');

% Which can be listed here.  In addition to list, you can
% rd.searchArtifacts
a = rd.listArtifacts;

%%  How to retrieve a data set from a remote path

% The validation data are in this directory
rd.crp('/validate');

% If you are not sure which one you want, you can list
a = rd.listArtifacts;

% Read the first one
data = rd.readArtifact(a(1).artifactId, 'type', 'mat');

disp(data);

%% This is how wepublished the validate files
% Just for record keeping and in case we need to do it again
% BW did an svn update on the vistadata directory.  Then ...

% Create object
rd = RdtClient('vistasoft');

% Set up the object and to write you must have login credentials
rd.credentialsDialog;

% I changed to the local svn repository with the validation files
localD = '/home/wandell/github/vistadata/validate';
cd(localD);

rd.crp('/validate');

% First upload the files
localFiles = dir('*.mat');

% each artifact must have a version, the default is version '1'
version = '1';

% Note that the file name must be the full path
for ii=1:length(localFiles);
    artifact = rd.publishArtifact(fullfile(pwd,localFiles(ii).name), ...
        'version', version, ...
        'description', 'VISTASOFT validation data.', ...
        'name', localFiles(ii).name);
end

a = rd.listArtifacts;

% Here is a dump of the artifactId, which we use to retrieve them later
a(:).artifactId

% The repository is a little complicated to navigate.  But it doesn't hurt
rd.openBrowser;


%%  Bulk upload example for files within the two sub-directories

% These are fmri 
rd.crp('/validate/fmri');
source = fullfile(pwd,'fmri');
artifacts = rd.publishArtifacts(source);
nArtifacts = numel(artifacts);
fprintf('We published %d files from the fmri folder.\n', nArtifacts);

%% Now the dwi folder
rd.crp('/validate/dwi');
source = fullfile(pwd,'dwi');
artifacts = rd.publishArtifacts(source);
nArtifacts = numel(artifacts);
fprintf('We published %d files from the dwi folder.\n', nArtifacts);


%%



