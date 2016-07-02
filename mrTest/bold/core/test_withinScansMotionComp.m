function test_withinScansMotionComp
%Test test_withinScansMotionComp as well as the creation of a new data type
%
%   test_withinScansMotionComp()
%
%
% Tests: intiHiddenInplane, test_withinScansMotionComp, dtGet, motionCompSelScan
%
% INPUTS
%  No inputs
%
% RETURNS
%  No returns
%
% Example: test_withinScansMotionComp()
%
% See also MRVTEST 
%
% Copyright Stanford team, mrVista, 2014
%
%

% Initialize the key variables and data path
% Data directory (where the mrSession file is located)
dataDir = mrtInstallSampleData('functional','prfInplane');

% This is the validation file
stored = mrtGetValididationData('withinScansMotionComp');


% 
% dtNum = 2;
% stored.name = dtGet(dataTYPES(dtNum),'Name');
% stored.annotation = dtGet(dataTYPES(dtNum),'Annotation', 1);
% stored.nFrames = dtGet(dataTYPES(dtNum),'nFrames', 1);
% stored.framePeriod = dtGet(dataTYPES(dtNum),'Frame Period', 1);
% stored.numSlices = length(dtGet(dataTYPES(dtNum),'slices', 1));
% stored.numScans = dtGet(dataTYPES(dtNum),'N Scans');
% stored.motionEstimates = motionEstimates;
% save(vFile, '-struct',  'stored')

% Relative tolerance of assertAlmostEqual
relTol = 1e-10;

% Retain original directory, change to data directory
curDir = pwd;
cd(dataDir);

% Get data structure:
vw = initHiddenInplane;
mrGlobals;

typeName        = 'WitinScansMotionComp';
baseScan        = 1;
baseFrame       = 1;
scansToCorrect  = 1;
nSmooth         = 1;

% compute the within scan motion, and return the view structure 
vw = motionCompSelScan(vw, typeName, scansToCorrect, baseFrame, nSmooth, baseScan);

% close the graph window created by motionCompSelScan
close(gcf)

%Now that we have created the necessary data, we can do the actual tests.
dtNum  = length(dataTYPES);
vw     = viewSet(vw, 'current dt', dtNum);
nScans = viewGet(vw, 'num scans');

% get the within scan motion
motionEstimates = dtGet(dataTYPES(dtNum), 'within scan motion', scansToCorrect);



% Now check that the motion estimates agree with stored estimates
assertVectorsAlmostEqual(motionEstimates, stored.motionEstimates, 'relative', relTol);

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

% clean up vistadata repository because this test script wrote new data
% test_CleanUpSVN
mrvCleanWorkspace;

cd(curDir);
