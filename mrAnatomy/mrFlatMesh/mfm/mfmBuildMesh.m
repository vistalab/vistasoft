function [mesh, perimeterEdges, insideNodes, orderedUniquePerimeterPoints] = ...
    mfmBuildMesh(mesh, params)
% Build the mesh from the mrGray output mesh, or the mrVista mesh made from
% the Class file
%
% [mesh, perimeterEdges, insideNodes, orderedUniquePerimeterPoints] = ...
%     mfmBuildMesh(mesh, params)
%
%Author:  Winawer
%
%   Purpose: Build the mesh from the mrGray output mesh, or the mrVista
%   mesh made from the Class file.  This contains all of the segmentation
%   information. 
%     
%   Sub-routine derived from Alex's unfoldMeshFromGUI code.
%
% See Also:  unfoldMeshFromGUI

% Get all the variables we may need
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

% Turn the strip format into individual faces and nodes
statusStringAdd(statusHandle,'Finding faces');
if(~isfield(mesh,'triangles'))
    mesh.faceIndexList=findFaces(mesh,busyHandle);
end

% The entries in mesh.vertices aren't unique. That is, the same
% vertex can be represented by two different entries.  This happens
% because strips always contain shared vertices.
%
% This next series of functions finds the unique vertices and
% and builds hash tables for vert->uniqueVerts and uniqueVerts->vert.
% Using these tables, we can adjust the list of colors and faces
% to represent each vertex by a unique index.

% Get rid of identical points
[mesh.uniqueVertices,mesh.vertsToUnique,mesh.UniqueToVerts]= unique(mesh.vertices,'rows'); 
mesh.uniqueNormal=mesh.normal(mesh.vertsToUnique);

% try to assign the colors that came in from mrGray
mesh.uniqueCols=mesh.rgba(mesh.vertsToUnique,:); 

% this gets rid of faces with multiple duplicate vertices and different permutations of the same face
mesh.uniqueFaceIndexList=findUniqueFaceIndexList(mesh); 

% Now we find the connection matrix: 
% a sparse matrix of nxn points where M(i,j) is 1 if i and j are connected
statusStringAdd(statusHandle,'Finding connection matrix.');
[mesh.connectionMatrix]=findConnectionMatrix(mesh);
sumCon=sum(mesh.connectionMatrix);
mesh.uniqueCols=mesh.uniqueCols(:,1);

if(numberOfSteps>0)
    statusStringAdd(statusHandle,'Blurring colormap.');
    for t=1:numberOfSteps
        mesh.uniqueCols=(mesh.connectionMatrix*mesh.uniqueCols(:))./sumCon(:);
    end
end

str=sprintf('%d connections found',length(mesh.connectionMatrix));
statusStringAdd(statusHandle,str);

% At this point, we can use the connection matrix to perform some fast
% smoothing on the curvature map. Also possibly a relaxation / smoothing on
% the actual mesh?
for t=1:10
    mesh.uniqueCols = connectionBasedSmooth(mesh.connectionMatrix, mesh.uniqueCols(:,1));
end

statusStringAdd(statusHandle,'Checking group perimeter.');

% Check to make sure that this is a clean surface: no edge points yet.
edgeList=findGroupPerimeter(mesh,1:length(mesh.uniqueVertices));
if (~isempty(edgeList))
    error('Error - initial mesh is not closed!');
else
    str = sprintf('Initial mesh is closed.\n'); statusStringAdd(statusHandle,str);
end
 
statusStringAdd(statusHandle,'Finding closest mesh point.');

% Find the nearest mesh point to the startCoords (Euclidian distance).
disp(size(mesh.uniqueVertices))
disp(size(startCoords))
disp(startCoords)
disp(sum(isnan(mesh.uniqueVertices(:))));
 
[startNode, snDist] = nearpoints(double(startCoords'),double(mesh.uniqueVertices')); 

disp('Done finding nearest mesh');
% Print the distance from the gray matter and warn if you're more than 15
% voxels away
str=sprintf('Start node %d selected at %d voxel units from input coords.',startNode,sqrt(snDist));
statusStringAdd(statusHandle,str);
if (sqrt(snDist)>5)
    beep;
    str=sprintf('** Warning: mesh node far from start coord. Expect trouble.');
    statusStringAdd(statusHandle,str)
end

% Find the distance of all nodes from the start node so that we can unfold
% just a sub-region of the whole mesh 
statusStringAdd(statusHandle,'Finding distances from start node');

% To this point, we are in a voxel framework: 
% Everything has been scaled in the mrReadMrM function. 
%
% D is the connection matrix using the true (non-squared) distance.
%% RAS: this seems to be the memory/time bottleneck: makes large sparse
%% matrices, whose size is independent of the unfold size
D = sqrt( find3DNeighbourDists(mesh,scaleFactor) ); 

str=sprintf('Mean inter-node distance: %.03f\n',full(sum(sum(D)))/nnz(D));
statusStringAdd(statusHandle,str);
 
% Find distances from the startNode to all the nodes
% Have replaced mrManDist with 'dijkstra' mex file to get around potential rounding errors.
 mesh.dist=dijkstra(D,startNode);
 
% We now have the basic mesh information.  We are starting to identify the
% perimeter and inside nodes for flattening. We generate a perimeter, based
% on the user's choice of perimeter distasnce  by thresholding these
% distances
mesh.perimDist=perimDist;
messageString=sprintf('Perimeter minimum distance=%d',perimDist);

statusStringAdd(statusHandle,messageString);
statusStringAdd(statusHandle,'Using threshold to find perimeter(s).');
statusStringAdd(statusHandle,'Defining perimeters.');

[perimeterEdges,eulerCondition]=findLegalPerimeters(mesh,perimDist);

% The routine above can generate islands - fix it by zeroing the connection matrix for the largest perimeter
% and then doing a flood fill with no limits to generate the inside group

% FIND ALL THE PERIMETERS AND TAKE THE BIGGEST ONE
messageString=sprintf('Euler number for this set=%d',eulerCondition);
statusStringAdd(statusHandle,messageString);

uniquePerimPoints=unique(perimeterEdges(:));
messageString=sprintf('%d unique perimeter points found.',length(uniquePerimPoints));
statusStringAdd(statusHandle,messageString);

[orderedUniquePerimeterPoints,biggest]=orderMeshPerimeterPointsAll(mesh,perimeterEdges);
nPerims=size(orderedUniquePerimeterPoints);
orderedUniquePerimeterPoints=orderedUniquePerimeterPoints{biggest}.points;

% DO THE FLOOD FILL TO FILL UP THE INNER HOLES
tempConMat=mesh.connectionMatrix; % save it for later
mesh.connectionMatrix(orderedUniquePerimeterPoints,:)=0;
mesh.connectionMatrix(:,orderedUniquePerimeterPoints)=0;
statusStringAdd(statusHandle,'Doing flood fill.');

[insideNodes,insideNodeStruct]=floodFillFindPerim(mesh,Inf,startNode,busyHandle);
insideNodes=[insideNodes(:);orderedUniquePerimeterPoints(:)];
mesh.connectionMatrix=tempConMat;
[perimeterEdges,eulerCondition]=findGroupPerimeter(mesh,insideNodes);
str = sprintf('Euler condition=%d\n',eulerCondition);
statusStringAdd(statusHandle,str);

% We now have a fully-connected mesh, and we have identified perimeter and
% inside nodes.  We are ready to build the portion of the mesh that we will
% unfold.
%
return