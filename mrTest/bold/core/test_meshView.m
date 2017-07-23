function test_meshView
%Validate that mrVista mesh viewer works
%
%  test_meshView()
%
% Tests: meshLoad, meshSet, meshVisualize, mrmInitMesh, nearpoints
%
% INPUTS
%  No inputs
%
% RETURNS
%  No returns
%
% Example: test_meshView()
%
% See also MRVTEST
%
% Copyright NYU team, mrVista, 2017


%% Initialize the key variables and data path
% Data directory (where the mrSession file is located)
dataDir = mrtInstallSampleData('functional','erniePRF');

% Store current location to return at end of script
curDir = pwd;
cd(dataDir);

% Open a hidden gray view
vw = initHiddenGray();

% Open the right white mesh
mshFileName = fullfile(viewGet(vw, 'meshdir', 'right'), 'Right_white') ;
displayFlag = true;
vw = meshLoad(vw, mshFileName, displayFlag);

% Compare the loaded mesh to the stored mesh
loadedMesh = viewGet(vw, 'mesh');

tmp = load(mshFileName, 'msh');
storedMesh = tmp.msh; clear tmp;

assertEqual(loadedMesh.initVertices, storedMesh.initVertices);
assertEqual(loadedMesh.vertices, storedMesh.vertices);
assertEqual(loadedMesh.triangles, storedMesh.triangles);

% Close mesh and clean up
vw = meshDelete(vw, viewGet(vw, 'CurMeshNum') ); 
mrvCleanWorkspace();
cd(curDir);

return
