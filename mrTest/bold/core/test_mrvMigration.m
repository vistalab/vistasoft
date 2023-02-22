function test_mrvMigration
%Validate that mrVista migration tools are doing the right thing
%
%  test_mrvMigration()
%
% Tests: mrInit_sessionMigration, mrInit_updateInplaneSession, 
%           mrInit_updateSessiontSeries
%
% INPUTS
%  No inputs
%
% RETURNS
%  No returns
%
% Example: test_mrvMigration()
%
% See also MRVTEST
%
% Copyright Stanford team, mrVista, 2014



%% Initialize the key variables and data path
% Data directory (where the mrSession file is located)
dataDir = mrtInstallSampleData('functional','mrMigration_test');

%% Retain original directory, change to data directory
curDir = pwd;
cd(dataDir);

%% Load original inplane anatomy and functional data (pre-migrated).
%   We will compare these to the anatomy and mean map after migration
tmp = load(fullfile(dataDir, 'Inplane', 'Original', 'meanMap'));
orig.meanMap = tmp.map(1);

tmp = load(fullfile(dataDir, 'Inplane', 'anat.mat'));
orig.anat     = tmp.anat;

%% Session should not open because it needs migrations. Try anyway
try mrVista; catch ME; end

% If we did NOT get an error above (we should have), then we WILL get one
% here. That is to say, if the vista session opened, then something is
% wrong because the seesion should require migration
fprintf('[%s]: %s\n', mfilename, ME.message);

%% Do the migration (this may take a few minutes)
mrInit_sessionMigration;

%% Check the new session
vw = initHiddenInplane;

% get the anatomy data matrix. we will want to make sure it has the right
% orientation
migrated.anat = viewGet(vw, 'anat');


% check functional data. we do this by computing a mean map and comparing
% it to a stored mean map.

% There can be several data types - name the one you want to probe
dataType = 'Original';

% Which scan number from that data type?
scan = 1;

vw = viewSet(vw, 'current data type', dataType);

vw = computeMeanMap(vw,scan, -1); 

migrated.meanMap = viewGet(vw, 'map');


%% Compare the pre-migrated and the post-migrated data sets 
assertVectorsAlmostEqual(orig.meanMap{1}, migrated.meanMap{1}, 'relative', .001);
assertVectorsAlmostEqual(single(orig.anat), single(migrated.anat),'relative');


% clean up vistadata repository because this test script wrote new data
% test_CleanUpSVN
mrvCleanWorkspace;

cd(curDir)
