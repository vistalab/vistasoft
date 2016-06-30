%% Illustrates how to download a validation file from the
% <https://github.com/isetbio/RemoteDataToolbox remote data client> created
% by Ben Heasly and the ISETBIO team.  
%
% We are using the RDT for VISTASOFT data, as well.
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
rd.crp('/vistadata/validate');

% Which can be listed here.  In addition to list, you can
% rd.searchArtifacts
a = rd.listArtifacts('print',true);

% To see how we uploaded these data, read rdtPublishFunctional.m

%%  Retrieve a data set from the validate directory

% If you are not sure which one you want, you can list
a = rd.listArtifacts('print',true);

% The first example is a matlab file (betweenScansMotionComp.mat)
% In this case, we know how to read the data and the values are returned as
% data.
data = rd.readArtifact(a(1));

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

rd.crp('/vistadata/anatomy/anatomyNIFTI');

a = rd.listArtifacts('type','gz','print',true);

% In this case, the file type is 
fname = rd.readArtifact(a(1));


%% We think that adding destination folder will restore the file name

dFolder = fullfile(vistaRootPath,'local');
fname = rd.readArtifact(a(1),'destinationFolder',dFolder);
exist(fname,'file')
ni = niftiRead(fname);
disp(ni)
     

%% Finally, read a specific file from a specific remote path
%  Place the file in a specific destination folder.
s = rd.searchArtifacts('vistadata anatomy','artifactId','t1.nii')

rd.crp('/vistadata/functional');
fname =rd.readArtifact('inplane.nii','type','gz','destinationFolder',pwd);
ni = niftiRead(fname);
disp(ni)

%% Download examples

% First some examples from the AFQ remote path.
rd.crp('/AFQ/templates');

% This is a list of the artifacts and we print it
a = rd.listArtifacts('print',true);

% Notice they have a variety of types.  We automatically handle matlab file
% types by loading them.  Other types may need special handling.

%% For Matlab files, the handling is simpler

% Here are just the matlab types
a = rd.listArtifacts('print',true,'type','mat');

% In this case, the returned variable (data) is a struct with each of the
% variables in the Remote Matlab file
data = rd.readArtifact(a(1))


%% Downloading a text file

% Here is a text file, the outcome is putting the text file in a default
% location with a lousy, default name.
a = rd.listArtifacts('print',true,'type','txt');

fname = rd.readArtifact(a(1),'type','txt');

% This is the file that was downloaded by default.  It is ugly and includes
% terms thare are used by the database.  Readable, but ugly.  The advantage
% of doing it this way is the server will know that you downloaded it and
% if you request it again, it will just use the cached, local copy.
disp(fname)

% An alternative is that you can control the file destination. Used in this way,
% the file name is better and you control the destination folder precisely.
dFolder = fullfile(vistaRootPath,'local');
fname = rd.readArtifact(a(1),'destinationFolder',dFolder);
dir(dFolder)

% Notice that the file name is correct here, without all the annoying
% database formatting.  It is yours.  The server doesn't know about it.
disp(fname)


%% nii.gz files are stored as type 'gz'.  Sorry about that

% Here they are.  Vistasoft has a lot of nii.gz files in general
a = rd.listArtifacts('print',true,'type','gz');

% Here is the download with the destination specified
fname = rd.readArtifact(a(1),'destinationFolder',dFolder);

% But the file that is written out is good
disp(fname)

% And niftiRead works on the downloaded fname.
ni = niftiRead(fname)



