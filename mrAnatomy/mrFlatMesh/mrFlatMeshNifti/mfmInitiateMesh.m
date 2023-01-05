function [msh,classData] = mfmInitiateMesh(classFileName,mmPerPix)
%
%
%
%
%


% Create the mesh of the whole segmentation.  The classification data
% (classData) are returned so we can create the gray matter later in this
% program.
[msh, classData] = meshBuildFromClass(classFileName, mmPerPix);
% meshVisualize(msh);

% Find the curvature map.  We smooth the mesh a bit
% to make the curvature more solid
msh = meshSet(msh,'smooth_iterations',10);
smoothMesh = meshSmooth(msh);
% smoothMesh = meshVisualize(smoothMesh);

% Then we compute the curvature
smoothMesh = meshColor(smoothMesh);
% smoothMesh = meshVisualize(smoothMesh);

% We assign the smoothed curvature values to the mesh we unfold
msh = meshSet(msh,'colors',meshGet(smoothMesh,'colors'));
% meshVisualize(msh);


return;
