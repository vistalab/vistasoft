function [meshCurvature, gLocs2d, gLocs3d] = unfoldMeshFromGUI(meshFileName, grayFileName, flatFileName, ...
    startCoords, scaleFactor, perimDist, statusHandle, busyHandle, ...
    spacingMethod, gridSpacing, showFigures, saveExtra, truePerimDist, hemi, save)
% 
%  unfoldMeshFromGUI(meshFileName, grayFileName, flatFileName, ...
%           startCoords, scaleFactor, perimDist, statusHandle, busyHandle,...
%           spacingMethod, gridSpacing, showFigures, saveExtra, truePerimDist, hemi);
%
% Author: Wade
% Purpose:
%    Unfolds a properly triangulated mesh using Floater/Tutte's sparse
%    linear matrix method. Then maps layer one grey nodes to the flattened
%    mesh and squeezes remaining grey layers to L1 to generate a flat.mat
%    file for use with mrLoadRet/mrVista
%
%    1. Read in the white matter boundary mesh created by mrGray.  The data
%    in the white matter mesh are organized into the mesh data structure.
%    2. The second section pulls out the portion of this entire mesh that will
%    be unfolded, creating the unfoldMesh structure.  This is the portion of 
%    the full mesh that is within the criterion distance from the startCoords.  
%    3. The data in the unfoldMesh are flattened.
%    4. The flat positions are adjusted to make the spacing more nearly
%    like the true distances.
%    5. Gray matter data to the flat map positions, building gLocs2d and
%    gLocs3d that are used by mrVista/mrLoadRet.
%
% See Also:  mrFlatMesh (the GUI that calls this).
%
% Stanford University
% ARW wade@ski.org : Changed  int pointers to size_t pointers (search for
% size_t in file) to ensure compatibility with 64-bit windows compilation
% using mex -largeArrayDims dijkstra.cpp
% 010808

%-------------------------------------------------
% CONSTANTS, Variable check
%-------------------------------------------------
nperims            = 1;
saveIntermeidate   = 1;
numberOfSteps      = 20; % Blur the curvature map a little in a connection-dependent manner

if (length(startCoords)~=3), error ('Error: you must enter 3 start coords'); end
if notDefined('save'),          save            = true;      end
if notDefined('spacingMethod'), spacingMethod   = 'None';    end
if notDefined('gridSpacing'),   gridSpacing     = 0.4;       end
if notDefined('showFigures'),   showFigures     = true;      end
if notDefined('saveExtra'),     saveExtra       = true;      end
if notDefined('truePerimDist'), truePerimDist   = perimDist; end
if notDefined('hemi'),          hemi            = viewGet(view, 'hemiFromCoords', startCoords);end

[adjustSpacing, spacingMethod] = xlateSpacing(spacingMethod);

startTime=now;

% **Make a structure for ease of passing arguments to subroutines**
params.adjustSpacing     = adjustSpacing;
params.busyHandle        = busyHandle;
params.flatFileName      = flatFileName;
params.grayFileName      = grayFileName;
params.gridSpacing       = gridSpacing;
params.hemi              = hemi;
params.meshFileName      = meshFileName;
params.NPERIMS           = nperims;
params.NUMBEROFSTEPS     = numberOfSteps;
params.perimDist         = perimDist;
params.SAVE_INTERMEDIATE = saveIntermeidate;
params.saveExtra         = saveExtra;
params.scaleFactor       = scaleFactor;
params.showFigures       = showFigures;
params.spacingMethod     = spacingMethod;
params.startCoords       = startCoords;
params.statusHandle      = statusHandle;
params.truePerimDist     = truePerimDist;

str = sprintf('\n****** mrFlatMesh %s *****\n',datestr(now));
statusStringAdd(statusHandle,str);

%-------------------------------------------------
% Get the mesh
%-------------------------------------------------
[mesh params] = mfmReadMesh(params);

%-------------------------------------------------
% Step 1.  We build the mesh from the mrGray output mesh.  This contains
% all of the segmentation information.  This should be a separate routine.
% (Now it is.)
%-------------------------------------------------
[mesh, perimeterEdges, insideNodes, orderedUniquePerimeterPoints] = ...
    mfmBuildMesh(mesh, params);

%-------------------------------------------------
% Step 2.  We extract the part of the mesh that we will unfold.  This part
% is defined by the distance and start node selected by the user.
% We now have a fully-connected mesh, and we have identified perimeter and
% inside nodes.  We are ready to build the portion of the mesh that we will
% unfold.
%-------------------------------------------------
[unfoldMesh, nFaces] = mfmBuildSubMesh(mesh, params, perimeterEdges, insideNodes, ...
    orderedUniquePerimeterPoints);

%-------------------------------------------------
% Step 3.  Unfold the unfoldMesh.  This is the key mathematical step in the
% process.
%-------------------------------------------------
[unfoldMesh, maps, unfolded2D] = mfmUnfoldTheMesh(unfoldMesh, params, nFaces);

%--------------------------------------------
%Step 4.  The unfoldMesh is complete. Now we adjust the spacing of the
%points so they don't bunch up too much.  The method is to find a cartesian
%grid within the data, find a Delaunay triangulation of this grid, and then
%use a series of affine transformations to transform each of the triangles
%to an equal area representation with the proper grid topology.  This is
%explained in more detail in flatAdjustSpacing
%--------------------------------------------
mesh = mfmAdjustSpacing(mesh, unfoldMesh, params, unfolded2D, insideNodes);

%------------------------------------------------
% Step 5.  We have the unfolded mesh.  We assign gray matter locations to the
% unfolded positions 
%------------------------------------------------
[mesh, meshCurvature, layerCurvature, gLocs2d, gLocs3d,numNodes] ...
    = mfmAssignGray(mesh, params, insideNodes);

endTime=now;

% Hacked in a save flag as well as some return args (in case we don't want
% to save anything out, and we just want vars to work with)
if (~save), return; end

%----------------------------------
% Step 6.
% Save stuff
%----------------------------------
mfmSaveStuff(unfoldMesh, params, meshCurvature, gLocs2d, gLocs3d,unfolded2D, numNodes,...
    layerCurvature, startTime, endTime, maps);



return;

%----------------------------------
% ---- SUBROUTINES
%----------------------------------

function [adjustSpacing, spacingMethod] = xlateSpacing(spacingMethod)
switch(spacingMethod)
    case 'None'
        adjustSpacing = 0;
    case 'Cartesian (equal)'
        adjustSpacing = 1;
        spacingMethod = 'cartesian';
    case 'Polar (equal)'
        warndlg('Polar not yet implemented.  Using Cartesian equal.');
        adjustSpacing = 1;
        spacingMethod = 'polar';
end
return;
