function test_averagetSeries
%Test averagetSeries as well as the creation of a new data type
%
%   test_averagetSeries()
%
%
% Tests: intiHiddenInplane, averageTSeries, dtGet
%
% INPUTS
%  No inputs
%
% RETURNS
%  No returns
%
% Example: test_averagetSeries()
%
% See also MRVTEST TEST_VIEWCREATEDATATYPE
%
% Copyright Stanford team, mrVista, 2013
%
%
%   To make life simple, we would like a number (or numbers) returned from
%   every call. Hence for calls that return text or cell arrays, we
%   calculate some simple statistic like the length of the array.
%

% Initialize the key variables and data path

% Data directory (where the mrSession file is located)
dataDir = mrtInstallSampleData('functional','mrBOLD_01');

% This is the validation file
% TODO: change the name of the file
stored = mrtGetValididationData('viewCreateDataType');

% dtNum = viewGet(vw,'Current Data Type');
% dtNum = 2;
% stored.name = dtGet(dataTYPES(dtNum),'Name');
% stored.annotation = dtGet(dataTYPES(dtNum),'Annotation', 1);
% stored.nFrames = dtGet(dataTYPES(dtNum),'nFrames', 1);
% stored.framePeriod = dtGet(dataTYPES(dtNum),'Frame Period', 1);
% stored.numSlices = length(dtGet(dataTYPES(dtNum),'slices', 1));
% stored.numScans = dtGet(dataTYPES(dtNum),'N Scans');
% stored.PfileName = dtGet(dataTYPES(dtNum),'Pfile Name', 1);
% stored.cropSize = dtGet(dataTYPES(dtNum),'Crop Size',1);
% stored.blockedAnalysisParams = dtGet(dataTYPES(dtNum),'Blocked Analysis Params');
% stored.eventAnalysisParams = dtGet(dataTYPES(dtNum),'Event Analysis Params');
%
% save(vFile, '-struct',  'stored')


% Retain original directory, change to data directory
curDir = pwd;
cd(dataDir);

% Get data structure:
vw = initHiddenInplane;
mrGlobals;

typeName = 'AverageDataType';

%Save dataTYPES to be able to pull it back after we over-write it.
save('dataTYPE_backup','dataTYPES');

vw = averageTSeries(vw, [1 2], typeName,'New Data Type');

dtNum = length(dataTYPES);
nScans = dtGet(dataTYPES(dtNum),'N Scans');

%Now that we have created all of the necessary data, we can do the actual
%tests:

assertEqual(stored.name, dtGet(dataTYPES(dtNum),'Name'));

assertEqual(stored.annotation, dtGet(dataTYPES(dtNum),'Annotation', nScans));

assertEqual(stored.nFrames, dtGet(dataTYPES(dtNum),'nFrames', nScans));

assertEqual(stored.framePeriod, dtGet(dataTYPES(dtNum),'Frame Period', nScans));

assertEqual(stored.numSlices, length(dtGet(dataTYPES(dtNum),'slices', nScans)));

assertEqual(stored.numScans, dtGet(dataTYPES(dtNum),'N Scans'));

% assertEqual(stored.PfileName, dtGet(dataTYPES(dtNum),'Pfile Name', nScans));

assertEqual(stored.cropSize, dtGet(dataTYPES(dtNum),'Crop Size', nScans));

assertEqual(stored.blockedAnalysisParams, dtGet(dataTYPES(dtNum),'Blocked Analysis Params'));

assertEqual(stored.eventAnalysisParams, dtGet(dataTYPES(dtNum),'Event Analysis Params'));

% clean up vistadata repository because this test script wrote new data
% test_CleanUpSVN
mrvCleanWorkspace;

cd(curDir);
