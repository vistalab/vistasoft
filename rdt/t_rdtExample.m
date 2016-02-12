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

%% To see the list of artifacts in the validate directory

% Change into the validate working directory.  This way you will only see
% the validation artifacts
rd.crp('/validate');

% Which can be listed here.  In addition to list, you can
% rd.searchArtifacts
a = rd.listArtifacts;
fprintf('%d artifacts found\n',length(a));
for ii=1:5
    fprintf('The first five artifacts are ID: %s, type: %s\n',a(ii).artifactId,a(ii).type);
end

%% To see how we uploaded these data, read rdtPublishFunctional.m

%%  Retrieve a data set from the validate directory

% The validation data are in this directory
rd.crp('/validate');

% If you are not sure which one you want, you can list
a = rd.listArtifacts;

% The first example is a matlab file (betweenScansMotionComp.mat)
% In this case, we know how to read the data and the values are returned as
% data.
data = rd.readArtifact(a(1).artifactId, 'type', 'mat');

disp(data);
% This should be
%                name: 'BetweenScansMotionComp'
%          annotation: '8 bars with blanks, 3 degrees'
%             nFrames: 128
%         framePeriod: 1.5000
%           numSlices: 20
%            numScans: 2
%     MotionEstimates: [4x4x2 double]


%% Retrieve a nii.gz file

% In this case, the file type is 
[fname, aReturned] = rd.readArtifacts(a(5));

% In this case fname is also equal to the local path in the updated
% artifact
isequal(fname{1}, aReturned.localPath)

% Notice that the file name is not the same as the original file.
% You might copy the file to a proper name that you can read and process

disp(data);

%%



