function test_xformInplaneToVolume
%Validate transforming data from INPLANE view to VOLUME (gray) view
%
%  test_xformInplaneToVolume()
% 
% Tests: initHiddenGray, loadMeanMap, loadCorAnal, ip2volParMap, 
% ip2volCorAnal, ip2volTSeries
%
% INPUTS
%  No inputs
%
% RETURNS
%  No returns
%
% Example: test_getCurDataROI()
%
% See also MRVTEST
%
% Copyright Stanford team, mrVista, 2011

%% Initialize the key variables and data path
% Data directory (where the mrSession file is located)
dataDir = mrtInstallSampleData('functional','mrBOLD_01');

% This is the validation file
val = mrtGetValididationData('ipToVolumeData');


% These are the items we stored in the validation file
%
% val.codim      = size(co);
% val.comed      = nanmedian(co);
% val.cosample   = co(1000);
% val.mapdim     = size(map);
% val.mapmed     = nanmedian(map);
% val.mapsample  = map(1000);
% val.tSdim     = size(tSeries);
% val.tSsample  = tSeries(1000);
%
% save(vFile, '-struct', 'val')

%% Retain original directory, change to data directory
curDir = pwd;
cd(dataDir);

% There can be several data types - name the one you want to probe
dataType = 'Original';

% Which scan number from that data type?
scan = 1;

%% Get data structure:
ip  = initHiddenInplane(); % Foregoes interface - loads data silently
vol = initHiddenGray(); 

%% Set dataTYPE:
ip  = viewSet(ip, 'Current DataType', dataType); % Data type
vol = viewSet(vol, 'Current DataType', dataType); % Data type

%% Load coranal and mean map into INPLANE view
ip = loadCorAnal(ip);
ip = loadMeanMap(ip);

%% Transform data to VOLUME view
vol = ip2volParMap( ip, vol, scan, [], 'linear', 1);
vol = ip2volCorAnal(ip, vol, scan, -1);
vol = ip2volTSeries(ip, vol, scan);

co  = viewGet(vol, 'scan coherence', scan);
map = viewGet(vol, 'scan map', scan);
tSeries = loadtSeries(vol, scan, 1); %We can hardcode slice since gray view only has 1 slice

%% Go home
cd(curDir);

%% Validate..

% check the dimensions of coherence map and mean map
assertEqual(val.codim, size(co));
assertEqual(val.mapdim, size(map));
assertEqual(val.tSdim, size(tSeries));

% check the median value of the coherence map and mean map
assertElementsAlmostEqual(val.comed,nanmedian(co));
assertElementsAlmostEqual(val.mapmed,nanmedian(map));


% check the values of the mean map and coherence map for an arbitrary voxel
% (to make sure the sequence is correct)
assertElementsAlmostEqual(val.cosample, co(1000));
assertElementsAlmostEqual(val.mapsample, map(1000));

% check the values of the time series for the max and an arbitrary voxel
assertElementsAlmostEqual(val.tSsample, tSeries(1000));
assertElementsAlmostEqual(val.tSmax,nanmax(tSeries(:)));


%% Cleanup
% clean up vistadata repository because this test script wrote new data
% test_CleanUpSVN

mrvCleanWorkspace;

