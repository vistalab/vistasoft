function test_mrvBuildMesh
%Validate that mrVista mesh build works
%
%  test_mrvBuildMesh()
%
% Tests: meshBuildFromClass, meshSmooth, meshColor
%
% INPUTS
%  No inputs
%
% RETURNS
%  No returns
%
% Example: test_mrvBuildMesh()
%
% See also MRVTEST
%
% Copyright NYU team, mrVista, 2017


% Get the class file
classFile = mrtInstallSampleData('anatomy/T1andMesh','t1_class.nii', [], [], 'filetype', 'gz');

% Check the resolution
nii = niftiRead(classFile);
mmPerVox = niftiGet(nii, 'pixdim');

% Run the build code
msh = meshBuildFromClass(classFile, mmPerVox, 'left'); % 'right' also works

% Smooth and color it
msh = meshSmooth(msh);
mshComputed = meshColor(msh);

% Load the stored mesh
mshPth  = mrtInstallSampleData('anatomy/T1andMesh', 'Left_Mesh_Unsmoothed', [], [], 'filetype', 'mat');
tmp = load(mshPth);
mshStored = tmp.msh;

% Compare the stored and computed mesh
assertEqual(mshComputed.vertices, mshStored.vertices);
assertEqual(mshComputed.triangles, mshStored.triangles);
assertEqual(mshComputed.origin, mshStored.origin);

return