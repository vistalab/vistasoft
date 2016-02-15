%% t_rdtExample
%
% Illustrates how to download a validation file from the
% <https://github.com/isetbio/RemoteDataToolbox remote data client> created
% by Ben Heasly and the ISETBIO team.  We are using the RDT for VISTASOFT
% data, as well.
%
% Make sure the Remote Data Toolbox is on your path. It can be cloned from
% ISETBIO on github as
%
%    git clone https://github.com/isetbio/RemoteDataToolbox.git
%
% This script 
%
%    * Creates a remote data object
%    * Opens a browser so you can click around
%    * Lists the artifacts in the remote data server
%    * Downloads a Matlab artifact as a struct
%    * Downloads a .nii.gz file to a specific destination folder
%
% None of these download operations require credentials.  To move data up
% to the archive, however, you must have a login and be authorized.
%
% TODO:
%   I think we should have some functions to help us search for files
%   (artfiacts) the command line.
% 
% BW/VISTASOFT Team

%% To download vistasoft validation data using the remote data toolbox

% This creates the object, using the configuration data in the file
% rdt/rdt-config-vistasoft.json
rd = RdtClient('vistasoft');

% You can see the structure just by typing rd
disp(rd)

% You can open a web-browser to view the repository this way
rd.openBrowser('fancy',true);
% If you don't use the 'fancy' option, then you will get a useful
% functional browser, too.


%% To see the list of artifacts in the validate directory

% Change into the validate working directory.  This way you will only see
% the validation artifacts
rd.crp('/validate');

% Which can be listed here.  In addition to list, you can
% rd.searchArtifacts
a = rd.listArtifacts;
fprintf('%d artifacts found\n',length(a));
for ii=1:5
    fprintf('The first five artifacts are ID: %s, \ttype: %s\n',a(ii).artifactId,a(ii).type);
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

% The data should be the Matlab struct:
%
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

disp(fname{1});

%% We think that adding destination folder will restore the file name

[fname, aReturned] = rd.readArtifacts(a(5),'destinationFolder',pwd);

ni = niftiRead(fname{1});

disp(ni)

% Should be something like:
%
%              data: [4-D int16]
%              fname: '/Users/wandell/Github/vistasoft/rdt/epi01.nii.gz'
%               ndim: 4
%                dim: [64 64 22 136]
%             pixdim: [2.5000 2.5000 2.5000 1.5000]
%          scl_slope: 0
%          scl_inter: 0
%            cal_min: 0
%            

%% Finally, read a specific file from a specific remote path
%  Place the file in a specific destination folder.

rd.crp('/validate/fmri');
fname =rd.readArtifact('inplane.nii','type','gz','destinationFolder',pwd);
ni = niftiRead(fname);
disp(ni)

%%



