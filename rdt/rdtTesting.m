%%  RDT testing for VISTASOFT
%
% Some examples and testing of the download of vistadata from the
% RemoteDataToolbox (RDT) site.

%% Create an RDT client object

rd = RdtClient('vistasoft');

% Here is a look at the general repository
rd.openBrowser('fancy',true)

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

%% Recursive listing

rd.crp('/vistadata/anatomy');

a = rd.listArtifacts('print',true,'recursive',true);

%% To upload vista data files requires a credential.

% See the files rdtPublishFunctional and rdtPublishAFQ for the methods used
% to move AFQ data and vistadata up to the RemoteDataToolbox site.

% cd(vistadata)
rd = RdtClient('vistasoft');
rd.credentialsDialog;

%%            