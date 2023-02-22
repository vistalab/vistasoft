function test_betweenScansMotionComp
%Test test_betweenScansMotionComp as well as the creation of a new data type
%
%   test_betweenScansMotionComp()
%
%
% Tests: intiHiddenInplane, test_betweenScansMotionComp, dtGet
%
% INPUTS
%  No inputs
%
% RETURNS
%  No returns
%
% Example: test_betweenScansMotionComp()
%
% See also MRVTEST 
%
% Copyright Stanford team, mrVista, 2013
%
%

% Relative tolerance of assertAlmostEqual
relTol = 1e-10;

% Initialize the key variables and data path

% Data directory (where the mrSession file is located)
dataDir = mrtInstallSampleData('functional','prfInplane');

% This is the validation file
stored = mrtGetValididationData('betweenScansMotionComp');

% 
% dtNum = 2;
% stored.name = dtGet(dataTYPES(dtNum),'Name');
% stored.annotation = dtGet(dataTYPES(dtNum),'Annotation', 1);
% stored.nFrames = dtGet(dataTYPES(dtNum),'nFrames', 1);
% stored.framePeriod = dtGet(dataTYPES(dtNum),'Frame Period', 1);
% stored.numSlices = length(dtGet(dataTYPES(dtNum),'slices', 1));
% stored.numScans = dtGet(dataTYPES(dtNum),'N Scans');
% stored.MotionEstimates = M;
% save(vFile, '-struct',  'stored')


% Retain original directory, change to data directory
curDir = pwd;
cd(dataDir);

% Get data structure:
vw = initHiddenInplane;
mrGlobals;

typeName = 'BetweenScansMotionComp';
baseScan = 1;
scansToCorrect = [1 2];

% compute the between scans motion, and return the view structure and the
% motion parameters (M)
[vw, M] = betweenScanMotComp(vw, typeName, baseScan, scansToCorrect);


%Now that we have created the necessary data, we can do the actual tests.
dtNum  = length(dataTYPES);
vw     = viewSet(vw, 'current dt', dtNum);
nScans = viewGet(vw, 'num scans');

% M should be (4 x 4 x numscans)
assertEqual(size(M), [4 4 length(scansToCorrect)]);

% We expect no motion for first scan as it is the reference (sanity check)
assertEqual(M(:,:,1), zeros(4))

% We expect non-zero motion for subsequent scans (sanity check)
assert(~isequal(M(:,:,2), zeros(4)));

% Now check that the motion estimates agree with stored estimates
assertVectorsAlmostEqual(stored.MotionEstimates, M, 'relative', relTol);

% Check that the new dataTYPE got the proper name
assertEqual(typeName, dtGet(dataTYPES(dtNum),'Name'));

% Check that the new dataTYPE got the proper annoation
assertEqual(stored.annotation, dtGet(dataTYPES(dtNum),'Annotation', nScans));

% Check that the new dataTYPE got the proper numbr of frames
assertEqual(stored.nFrames, dtGet(dataTYPES(dtNum),'nFrames', nScans));

% Check that the new dataTYPE got the proper TR
assertEqual(stored.framePeriod, dtGet(dataTYPES(dtNum),'Frame Period', nScans));

% Check that the new dataTYPE got the proper number of slices
assertEqual(stored.numSlices, length(dtGet(dataTYPES(dtNum),'slices', nScans)));

% Check that the new dataTYPE got the proper number of scans
assertEqual(stored.numScans, dtGet(dataTYPES(dtNum),'N Scans'));

mrvCleanWorkspace;

cd(curDir);
