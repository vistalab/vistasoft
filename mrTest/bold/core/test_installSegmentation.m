function test_installSegmentation
%Validate that installSegmentation is doing the right thing
%
%  test_mrInit()
%
% Tests: mrInitDefaultParams, mrInit
%
% INPUTS
%  No inputs
%
% RETURNS
%  No returns
%
% Example: test_mrInit()
%
% See also MRVTEST
%
% Copyright Stanford team, mrVista, 2011


global HOMEDIR;
%% Set up the data: 
mrvCleanWorkspace;




% Use a sample data set for testing
erniePRFOrig = mrtInstallSampleData('functional', 'erniePRF', [], 1);

% Retain original directory, change to data directory
currDir = pwd;
cd(erniePRFOrig)

% Load the gray coords
oldCoords = load(fullfile(HOMEDIR, 'gray', 'coords'));

% Re-install segmentation, and record time before and afterwards
timeBeforeDelete = datetime('now');
installSegmentation(0, 0, '3DAnatomy/t1_class.nii.gz', 3)
timeAfterDelete  = datetime('now');

% Check that old Gray segmentation was deleted and backed up in a folder
d = dir('deletedGray*');
[~, idx] = max([d.datenum]);
assert(d(idx).isdir)

% Ch
d = dir('Gr*y');
[~, idx] = max([d.datenum]);
timeGray = datetime(d(idx).date);

assert(timeBeforeDelete < timeGray);
assert(timeAfterDelete > timeGray);

newCoords = load(fullfile(HOMEDIR, 'gray', 'coords'));
%%


assertEqual(viewGet(vw,'View Type'),'Inplane');
assertEqual(viewGet(vw,'Name'),'hidden');

mrvCleanWorkspace;
