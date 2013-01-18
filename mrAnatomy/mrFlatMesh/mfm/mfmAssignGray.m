function [mesh, meshCurvature, layerCurvature, gLocs2d, gLocs3d, numNodes] ...
    = mfmAssignGray(mesh, params, insideNodes)
% Assign gray matter locations to the unfolded positions in a flattened
% map.
%
% [mesh, meshCurvature, layerCurvature, gLocs2d, gLocs3d, numNodes] ...
%    = mfmAssignGray(mesh, params, insideNodes)
%
% Author:  Winawer
%
%   Purpose: Assign gray matter locations to the unfolded positions in a flattened
%   map. 
%     
%   Sub-routine derived from Alex's unfoldMeshFromGUI code.
%
% See Also:  unfoldMeshFromGUI
% Get all the variables we may need
meshFileName     = params.meshFileName;
grayFileName     = params.grayFileName;
flatFileName     = params.flatFileName;
startCoords      = params.startCoords;
scaleFactor      = params.scaleFactor;
perimDist        = params.perimDist;
statusHandle     = params.statusHandle;
busyHandle       = params.busyHandle;
spacingMethod    = params.spacingMethod;
adjustSpacing    = params.adjustSpacing;
gridSpacing      = params.gridSpacing;
showFigures      = params.showFigures;
saveExtra        = params.saveExtra;
truePerimDist    = params.truePerimDist;
hemi             = params.hemi;
nperims          = params.NPERIMS;
saveIntermeidate = params.SAVE_INTERMEDIATE;
numberOfSteps    = params.NUMBEROFSTEPS;

% Update status
statusStringAdd(statusHandle,'Reading gray graph...');
[gNodes, gEdges] = readGrayGraph(grayFileName, hemi);

% Do all the gray node stages in a loop so that we can have arbitrary
% numbers of layers.
numGrayLayers=max(gNodes(6,:));

% Get the indices for all the gnodes (all layers)
for t=1:numGrayLayers
    grayNodeIndices{t}=find(gNodes(6,:)==t);
end

% Extract the layer 1 nodes. These are special because they are used to map
% down to the unfolded boundary mesh.
l1gNodes=gNodes(:,grayNodeIndices{1});
l1mesh.vertices=l1gNodes(1:3,:);
l1mesh.indices=grayNodeIndices{1};

% How many gNodes are there?
nGnodes=length(gNodes);
% How many gEdges are there?
nGedges=length(gEdges);

% We want to make a grey node connection matrix - which grey nodes are connected to which other gnodes?
statusStringAdd(statusHandle,'Finding grey connection matrix (slow)');

grayConMat=makeGrayConMat(gNodes,gEdges,busyHandle);

% We can assign layer 1 grey nodes to the white matter mesh using
% assignToNearest.dll (see assignToNearest.c) Can't do this for higher
% levels of grey matter because they might be mis-assigned. (Also, potential
% problem near  very crinkly edges. - Could we accidentally assign a l1
% grey matter node to the wrong WM point?) (I think the answer is 'yes,
% rarely'. If a single layer or gray is sandwiched between two sides of a
% sulcus (say) : It's grown from one side but mrFlatMesh has no way of
% telling which one.  Going deeper into mrGray's source code to determine
% the parentage of l1 gray nodes might be possible...)


% So for higher grey matter points, we have to restrict the possible sub
% node search space by assigning them >only< to  points they are connected
% to. Note that a single layer2 grey node may be connected to several l1
% nodes


% The gray may be defined over the entire mesh but we only want to deal with gray points over the 
% unfolded part. The strategy should be....
% 1) do assignToNearest for each mesh point to find the nearest connected l1 node
% 2) Use the set of l1 nodes found in 1) to build up a list of other connected gray nodes
% 3) Repeat stage 2 for l3,l4

statusStringAdd(statusHandle,'Mapping L1 to mesh.');

% Find 3D coords of all the l1 gnodes
l1GNodeCoords=l1gNodes(1:3,:)';

% Find 3D coords of all the mesh points (not just the unfolded ones) 
meshCoords=mesh.uniqueVertices;

% Mesh coords are in voxels, gnode coords are in voxels. Bring them into alignment
l1GNodeCoordsN=l1GNodeCoords-1; % Use this -1 to bring them into perfect alignment. This was the source of an error in V1.0

% Now restrict the mesh coords to just those points in the unfold
meshCoordsN=meshCoords(mesh.insideNodes,:);

% And now restrict the set of l1 gray nodes so that only those that are relatively near the 
% mesh are included in the search - this is done first as a simple bounds check
boundedL1NodeIndices=boundsCheck3D(min(meshCoordsN)-3,max(meshCoordsN)+3,l1GNodeCoordsN);
boundedL1GNodes=l1GNodeCoordsN(boundedL1NodeIndices,:);
boundedL1NodeIndices=grayNodeIndices{1}(boundedL1NodeIndices); % This is now a list of indices into the full gNode array

statusStringAdd(statusHandle,'Finding nearest Ll gray points to mesh (very slow)');

% Find mesh points near the l1 gNodes
[boundedL1toMeshIndices,sqrDist]=nearpoints(boundedL1GNodes',(meshCoordsN)');
% This returns a list of indices into the meshCoordsN array that links a single 3D mesh point to each l1Gnode)
% and then eliminate any l1gNodes that are more than a set distance away from the mesh - here sqrt(0.25)

% *************************
closeEnough=find(sqrDist<=0.2501);
% *************************

boundedL1toMeshNodes  = boundedL1GNodes(closeEnough,:); % remember, assignToNearest returns the squared distance
boundedL1toMeshIndices= boundedL1toMeshIndices(closeEnough);

% For each member of the bounded l1Gnodes, this tells us the index of the full mesh point that it maps to.
fullBoundedL1toMeshIndices=insideNodes(boundedL1toMeshIndices);

restNodeIndices{1}=boundedL1NodeIndices(closeEnough);

statusStringAdd(statusHandle,'Setting L1 glocs');
% We can start setting gLocs
% Note the +1 here! Because we subtracted 1 from the original node coords
% to align them with the mesh. 
layerGlocs3d{1}=boundedL1toMeshNodes+1; 
layerGlocs2d{1}=mesh.X(fullBoundedL1toMeshIndices,:);

numNodes(1)=length(layerGlocs3d{1});

layerCurvature{1}=mesh.uniqueCols(fullBoundedL1toMeshIndices,1);

if (showFigures)
    h = unfoldPlotL1Mesh(grayConMat(restNodeIndices{1},restNodeIndices{1}), layerGlocs2d{1}); 
    statusStringAdd(statusHandle,'Displaying L1 gray mesh.');
	
	[p f ext] = fileparts(flatFileName);
	savePath = fullfile(p, [f ' Gray Mesh.png']);
	saveas(h, savePath);
	fprintf('[%s]: Saved %s.\n', mfilename, savePath);	
end

% Now we have to find l2tol1Indices, l3tol2Indices and l4tol3Indices. This
% is faster since for each point, we restrict its  potential nearest
% neighbours to points that it is connected to in the previous layer.  We
% also restrict the l2 nodes to just those that are connected to the
% restricted l1 nodes and the l3 nodes to those connected to the l2 nodes.
% Use the full connection matrix to find which l2 Gnodes are connected to the restricted l1Gnodes
statusStringAdd(statusHandle,'Mapping other gray layers (2,3,4..)');

% Set up the 3 critical arrays curvature, gLocs2d, gLocs3d. These are what
% eventually get written to the flat.
meshCurvature=layerCurvature{1};
gLocs2d=layerGlocs2d{1};
gLocs3d=layerGlocs3d{1};

for t=2:numGrayLayers
    
    layerInterconnect=grayConMat(:, restNodeIndices{t-1}); % Finds all the things connected to the t-1th layer...
    [restNodeIndices{t},dummy]=find(layerInterconnect);
    restNodeIndices{t}=unique(restNodeIndices{t});
    restNodeIndices{t}=intersect(restNodeIndices{t},grayNodeIndices{t}); % Only take potential l2 node indices
    finalConnectIndices{t-1}=findNearestConnected(gNodes', restNodeIndices{t},restNodeIndices{t-1},grayConMat);
    
    % Set glocs3d, glocs2d, meshCurvature
    layerGlocs3d{t}=gNodes(1:3,restNodeIndices{t})';
    numNodes(t)=length(layerGlocs3d{t});
    layerGlocs2d{t}=layerGlocs2d{t-1}(finalConnectIndices{t-1},:);
    layerCurvature{t}=zeros(length(finalConnectIndices{t-1}),1);
    gLocs2d=[gLocs2d;layerGlocs2d{t}];
    gLocs3d=[gLocs3d;layerGlocs3d{t}];
    meshCurvature=[meshCurvature;layerCurvature{t}];
    
end

if (showFigures), 
	unfoldPlotgLocs2d(numGrayLayers,layerGlocs2d); 
	[p f ext] = fileparts(flatFileName);
	savePath = fullfile(p, [f ' Grid Locations.png']);
	saveas(gcf, savePath);
	fprintf('[%s]: Saved %s.\n', mfilename, savePath);
end

statusStringAdd(statusHandle,'Creating flat.mat structure');

% We want to transform  the curvature to run between 1 to 64 for display
% purposes.  We want the mean, however, to be preserved so that we can
% calculate the average curvature and also we want to keep the values
% accurate in terms of real curvature (which is 1/radius in pixels but
% should be mm; though mrGray may do some unwanted scaling).
% So, instead of this:  
%     meshCurvature=normalize((meshCurvature))*63+1;%
% we now do this to (a) map to 1 to 64, 
%
% Note that the curvature values here are pulled from the rgba field of the
% mesh sturct. This is created by meGray and is the actual RGB (& alpha)
% value used to color each triangle when the mesh is rendered. If the mesh
% has no color overlays, then this will be an 8-bit grayscale value (R=G=B)
% and thus range from 0-255, with curvature=0 at 127. (RFD/BW).
meshCurvature = (layerCurvature{1}/255)*63 ;

return

%----------------------------------
% ---- SUBROUTINES
%----------------------------------
%----------------------------------
function h = unfoldPlotL1Mesh(x,layer1Glocs2d)
h = figure;
gplot(x,layer1Glocs2d);
title('L1 gray mesh'); zoom on;

return;

%----------------------------------
function unfoldPlotgLocs2d(numGrayLayers,layerGlocs2d)
%
nFigsAcross=ceil(sqrt(numGrayLayers));
nFigsDown=ceil(sqrt(numGrayLayers));
for t=1:numGrayLayers
    if (t<=numGrayLayers)
        subplot(nFigsDown,nFigsAcross,t);
        
        plot(layerGlocs2d{t}(:,1),layerGlocs2d{t}(:,2),'.');
        axis equal;
    end % end check on current layer index
end % Next image
return;

