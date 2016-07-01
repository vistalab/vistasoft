%% Testing methods for RemoteDataToolbox interaction with validation
%
% 

%% Open rd object
rd = RdtClient('vistasoft');
rd.credentialsDialog;

%% Change remote path to the functional area

% Local file
folder = '/Users/wandell/Github/vistasoft/local/functional/';
rd.crp('/vistadata/functional');
rd.publishArtifacts(folder,'type','zip');

%% Get it down to the local folder like this

rd.crp('/vistadata/functional')
dFolder = fullfile(vistaRootPath,'local');
rd.readArtifact('mrBOLD_01','type','zip','destinationFolder',dFolder);
chdir(dFolder);
unzip('mrBOLD_01.zip');

%%