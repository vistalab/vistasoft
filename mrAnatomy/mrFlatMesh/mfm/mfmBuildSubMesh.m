function [unfoldMesh, nFaces] = mfmBuildSubMesh(mesh, params, perimeterEdges, insideNodes, ...
    orderedUniquePerimeterPoints)
%
% [unfoldMesh, nFaces] = mfmBuildSubMesh(mesh, params, perimeterEdges, insideNodes, ...
%    orderedUniquePerimeterPoints)
%
% Author: Winawer
% Purpose:
%   This routine begins with the original large mesh and extracts a
%   topologically correct sub-mesh based on the perimeter edges and inside nodes.
%  
%   Sub-routine derived from Alex's unfoldMeshFromGUI code.
%
% See Also:  unfoldMeshFromGUI
%

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


% internal points are the ones we want
unfoldMesh.connectionMatrix=mesh.connectionMatrix(insideNodes,insideNodes);
unfoldMesh.normal=mesh.normal(insideNodes,:);

unfoldMesh.uniqueVertices=mesh.uniqueVertices(insideNodes,:);
unfoldMesh.uniqueCols=mesh.uniqueCols(insideNodes,:);
unfoldMesh.dist=mesh.dist(insideNodes);

% We need to get uniqueFaceIndexList for the unfoldMesh
indicesOfFacesInSubGroup=findFacesInGroup(mesh,insideNodes);
subGroupFaces=mesh.uniqueFaceIndexList(indicesOfFacesInSubGroup,:);
nFaces=size(subGroupFaces,1);

statusStringAdd(statusHandle,'Computing sub-mesh lookup table');

% Get a lookup table for converting indices into the full node array into indices to the unfold mesh nodes. 
lookupTable=zeros(length(mesh.uniqueVertices),1);
lookupTable(insideNodes)=1:length(insideNodes);

% Use the lookup table to convert our list of face indices so that they index into unfoldMesh.uniqueVertices.
sgf=lookupTable(subGroupFaces(:));
unfoldMesh.uniqueFaceIndexList=reshape(sgf,nFaces,3);

% Convert the edges to feed into orderMeshPerimeterPoints
fullEdgePointList=perimeterEdges(:);

% How many edges do we have?
[numEdges,x]=size(perimeterEdges);

newEdges=zeros((numEdges*2),1);
statusStringAdd(statusHandle,'Finding sub-mesh edges.');

for t=1:(numEdges*2)  
    if (~mod(t,100) & ~isempty(busyHandle))
        updateBusybar(busyHandle,t);
    end
    newEdges(t)=find(insideNodes==fullEdgePointList(t));
end

newEdges=reshape(newEdges,numEdges,2);
statusStringAdd(statusHandle,'Finding sub-mesh perim.');

% Find the perimeter points in the sub mesh.
unfoldMesh.orderedUniquePerimeterPoints=zeros(length(orderedUniquePerimeterPoints),1);

for t=1:length(orderedUniquePerimeterPoints)
    f1=find(insideNodes==orderedUniquePerimeterPoints(t));
    
    %orderMeshPerimeterPoints(newEdges);
    unfoldMesh.orderedUniquePerimeterPoints(t)=f1;
end

return;
