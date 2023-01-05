function test_installSegmentation
%Validate that installSegmentation is doing the right thing
%
%  test_installSegmentation()
%
% Tests: installSegmentation, cleanGray, cleanFlat
%
% INPUTS
%  No inputs
%
% RETURNS
%  No returns
%
% Example: test_installSegmentation()
%
% See also MRVTEST
%
% Copyright Stanford team, mrVista, 2011


%% Set up the data: 
mrvCleanWorkspace;

% Use a sample data set for testing
erniePRF = mrtInstallSampleData('functional', 'erniePRF', [], 1);

% Retain original directory, change to data directory
curDir = pwd;
cd(erniePRF)

mrGlobals();

% Load the gray coords
oldCoords = load(fullfile(erniePRF, 'Gray', 'coords'));

% Re-install segmentation, and record time before and afterwards
timeBeforeDelete = datetime('now');

% we need to do keep all gray nodes to produce same results as repository,
% because that is how the initial session was created
keepAllNodes = true; 
installSegmentation(0, keepAllNodes, fullfile(erniePRF, '3DAnatomy', 't1_class.nii.gz'), 3);

timeAfterDelete  = datetime('now');

% Check that old Gray segmentation was deleted and backed up in a folder
d = dir('deletedGray*');
[~, idx] = max([d.datenum]);
assert(d(idx).isdir)

% Check that new Gray folder was installed
d = dir('Gr*y');
[~, idx] = max([d.datenum]);
timeGray = datetime(d(idx).date);

assert(timeBeforeDelete < timeGray);
assert(timeAfterDelete > timeGray);

% Check that new coords match old coords
newCoords = load(fullfile(erniePRF, 'Gray', 'coords'));

assertEqual(newCoords.coords, oldCoords.coords);
assertEqual(newCoords.nodes, oldCoords.nodes);
assertEqual(newCoords.edges, oldCoords.edges);

% Clean up
mrvCleanWorkspace;
cd(curDir);

return
