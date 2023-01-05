% Script
% 
% Create and unfold a mesh using the white matter classification
%
% THe unfold method creates a properly triangulated mesh from a white
% matter classification data set. A region of the mesh is identified for
% unfolding. Then the mesh is flattened using Floater/Tutte's linear  
% method. The method's principle is this:  Each vertex is assigned a
% position in the plane at a location equal to the average of its connected
% neighbors. Then maps layer one grey nodes to the flattened 
%
% The initial unfolding occurs just for the layer 1 (L1) levels. The
% remaining grey layers are then assigned a position corresponding to the
% position of the nearest L1 neighbor point.
%
%    1. Read in the white matter created by mrGray.  
%    2. Create the mesh that will be unfolded
%    3. Select the portion of the full mesh that is within the criterion
%    distance from the startCoords. 
%    3. Flatten this portion of the mesh.
%    4. [Optional]: The flat positions are adjusted to make the spacing more nearly
%    like the true distances.
%    5. Assign gray matter data to the flat map positions.
%
% Stanford University


% For now, start up a Nakadomari 3 deg data set.  In the future, we will
% just set the path to the anatomy here.

% if ieNotDefined('spacingMethod'), spacingMethod = 'None'; end
% if ieNotDefined('gridSpacing'), gridSpacing = 0.4; end
% if ieNotDefined('showFigures'), showFigures = 0; end

anatFileName  = 'C:\u\brian\Matlab\mrDataExample\anatomy\nakadomari\vAnatomy.dat';
classFileName = 'C:\u\brian\Matlab\mrDataExample\anatomy\nakadomari\left\20040311\left.Class';
mmPerPix      = readVolAnatHeader(anatFileName);

[msh,classData] = mfmInitiateMesh(classFileName,mmPerPix);
% meshVisualize(msh);

% mrReadMrM scales everything to voxel coords. So mrGray writes out a mesh
% in real world coordinates (say 0.5,0.5,0.5) and saves the voxel size(say
% 0.5x0.5x0.5) with the mesh. Then mrReadMrM returns the coordinate as [1 1
% 1] and tells you the voxel size it used. scaleFactorFromMesh is in
% mm/voxel.
% Boy, this needs to be explained again. (BW).

%-------------------------------------------------
% Step 1.  We build the mesh from the mrGray output mesh.  This contains
% all of the segmentation information.  This should be a separate routine.
%-------------------------------------------------

% This shows whether have a unique set of vertices
% b = unique(msh.vertices,'rows');
% size(b)
% size(msh.vertices)

% This is how we decide whether we have a unique set of triangles
%
% b = sort(msh.triangles);
% c = unique(b','rows');
% size(b), size(c)

%-------------
%
%  If you already have a mesh built by the code above, you can start the
%  unfold part of things here
%

tic
showFigures = 1;
adjustSpacing = 0;

% This start coord is from the left hemisphere of Nakadomari 3 deg
% In  mrFlatMesh GUI these are: X Y Z. In brain these are
startCoords = [220 135 121];       % Ant/Post, Sup/Inf, Left/Right
perimDist   =  40;                 % Radius of mesh to flatten

% N.B.  The indices in the msh.triangles start from 0, not 1.  So we have
% to be careful in all of these routines to add 1 when we do the indexing.
%
% Now we find the connection matrix:
% a sparse matrix of nxn points where M(i,j) is 1 if i and j are connected
disp('Building connection matrix of large mesh')
msh.connectionMatrix = findConnectionMatrix2(msh);
% figure; spy(msh.connectionMatrix)

% Check to make sure that this is a clean mesh: no edge points yet.
disp('Checking perimeter of large mesh.')
nVertices = meshGet(msh,'nvertices');
edgeList = findGroupPerimeter2(msh,1:nVertices);
if (~isempty(edgeList))
    error('Error - initial mesh is not closed!');
end

% Find the nearest mesh point to the startCoords (Euclidian distance).
% [startNode,snDist] = assignToNearest(mesh.vertices',startCoords([2 1 3]));
[startNode,snDist] = nearpoints(startCoords([1 2 3])',msh.vertices);
fprintf('Distance between closest vertex and start coord %.0f\n',snDist);

% Print the distance from the gray matter and warn if you're more than 15
% voxels away
% str=sprintf('Start node %d selected at %d voxel units from input coords.',startNode,sqrt(snDist));
% statusStringAdd(statusHandle,str);
if (sqrt(snDist)>15)
    beep;
    fprintf('** Warning: mesh node far from start coord. Expect trouble.');
end

% Find the distance of all nodes from the start node so that we can unfold
% just a sub-region of the whole mesh

% To this point, we are in a voxel framework:
% Everything has been scaled in the mrReadMrM function.
%
% D is the connection matrix using the true (non-squared) distance.
disp('Creating distance map of large mesh.')
D = sqrt(find3DNeighbourDists2(msh,mmPerPix));

% Find distances from the startNode to all the nodes
msh.dist = dijkstra(D,startNode);

% We now have the basic mesh information.  We are starting to identify the
% perimeter and inside nodes for flattening. We generate a perimeter, based
% on the user's choice of perimeter distasnce  by thresholding these
% distances
msh.perimDist = perimDist;

% Though, this number is not used here other than for printing out.
disp('Creating legal perimeter.')
perimeterEdges = findLegalPerimeters2(msh,perimDist);

% The routine above can generate islands - fix it by zeroing the connection
% matrix for the largest perimeter and then doing a flood fill with no
% limits to generate the inside group

% uniquePerimPoints=unique(perimeterEdges(:));
[orderedUniquePerimeterPoints,biggest] = orderMeshPerimeterPointsAll(msh,perimeterEdges);

% nPerims = size(orderedUniquePerimeterPoints);
orderedUniquePerimeterPoints = orderedUniquePerimeterPoints{biggest}.points;

% DO THE FLOOD FILL TO FILL UP THE INNER HOLES
tempConMat  = msh.connectionMatrix; % save it for later
msh.connectionMatrix(orderedUniquePerimeterPoints,:) = 0;
msh.connectionMatrix(:,orderedUniquePerimeterPoints) = 0;

disp('Flood filling to find region within perimeter')
insideNodes = floodFillFindPerim(msh,Inf,startNode);
insideNodes = [insideNodes(:); orderedUniquePerimeterPoints(:)];

disp('Finding Group Perimeter')
msh.connectionMatrix = tempConMat;
perimeterEdges       = findGroupPerimeter2(msh,insideNodes);

% We now have a fully-connected mesh, and we have identified perimeter and
% inside nodes.  We are ready to build the portion of the mesh that we will
% unfold.

%-------------------------------------------------
% Step 2.  Extract the part of the mesh that we will unfold.  This part
% is defined by the distance and start node selected by the user.
% We now have a fully-connected mesh, and we have identified perimeter and
% inside nodes.  We are ready to build the portion of the mesh that we will
% unfold.
%-------------------------------------------------
disp('Extracting portion of mesh')
[unfoldMesh, nFaces] = ...
    mfmBuildSubMesh(msh, perimeterEdges, insideNodes, ...
    orderedUniquePerimeterPoints);

% Make this work some day ... we should be able to visualize the unfoldMesh
% easily.  Once this works, we should be able to convert it to the same
% format as the standards msh.
%
% uMesh = meshCreate;
% uMesh = meshSet(uMesh,'triangles',unfoldMesh.uniqueFaceIndexList');
% uMesh = meshSet(uMesh,'vertices',unfoldMesh.uniqueVertices');
% uMesh = meshSet(uMesh,'colors',unfoldMesh.uniqueCols');
% uMesh = meshSet(uMesh,'normals',unfoldMesh.normal');
% uMesh = meshSet(uMesh,'origin',round(meshGet(uMesh,'origin')));
% uMesh = meshSet(uMesh,'lights',meshGet(msh,'lights'));
% 
% meshVisualize(msh);
% meshVisualize(uMesh);

%-------------------------------------------------
% Step 3.  Unfold the unfoldMesh.  This is the key mathematical step in the
% process.
%-------------------------------------------------

% Find the N and P connection matrices
% statusStringAdd(statusHandle,'Finding sub-mesh connection matrix.');
[N, P, unfoldMesh.internalNodes] = findNPConnection(unfoldMesh);

% Here we find the squared 3D distance from each point to its neighbours.
unfoldMesh.distSQ = find3DNeighbourDists(unfoldMesh,mmPerPix);

fullConMatScaled = scaleConnectionMatrixToDist(sqrt(unfoldMesh.distSQ));

% Now split the full conMat up until N and P
N = fullConMatScaled(unfoldMesh.internalNodes,unfoldMesh.internalNodes);
P = fullConMatScaled(unfoldMesh.internalNodes,unfoldMesh.orderedUniquePerimeterPoints);

% Assign the initial perimeter points - they're going to go in a circle for now...
% Can set distances around circle to match actual distances from the center.
unfoldMesh.X_zero = assignPerimeterPositions(perimDist,unfoldMesh);

% THIS IS WHERE WE SOLVE THE POSITION EQUATION -
% THIS EQUATION IS THE HEART OF THE ROUTINE!
disp('Solving Main equation')
X =(speye(size(N)) - N) \ (sparse(P * unfoldMesh.X_zero));

% Remember what these variables are:
% X: 2d locations of internal points
% X_zero : 2d locations of perimeter
% N sparse connection matrix for internal points
% P sparse connection matrix between perimeter and internal points
% (Note - the connection matrix between the perimeter points is implicit in
% their order - they are connected in a ring)
% The 3D coordinates o

unfoldMesh.N = N;
unfoldMesh.P = P;
unfoldMesh.X = X;

% Find the face areas for the unfolded and folded versions of the unfoldMesh
% This is a good error metric. We'll save this out with the flat.mat file.
% (ARW)
%
% Do this by calling findFaceArea. We call it twice, once with the 3D vertices and once with
% a pseudo-3D vertex set with the 3rd dimension set to 0
% The areaList3D and errorList are saved out,
% but I don't know where they are used.  Perhaps Bob? (BW)

% This seems like an important piece of code, the ordering used to define
% unfolded2D is complicated.  We need comments and it would be better to
% have it in a function.
unfolded3D = unfoldMesh.uniqueVertices;

indices2D  = unfoldMesh.internalNodes;
unfolded2D(indices2D,1:2) = full(unfoldMesh.X);
unfolded2D(indices2D,1:2) = full(unfoldMesh.X_zero);
unfolded2D(:,3) = 0;
indices2D       = unfoldMesh.orderedUniquePerimeterPoints;

% Uncomment and fix, later
% areaList3D = ...
%     findFaceArea(unfoldMesh.connectionMatrix,unfolded3D,...
%     unfoldMesh.uniqueFaceIndexList);
% 
% areaList2D = ...
%     findFaceArea(unfoldMesh.connectionMatrix,unfolded2D,...
%     unfoldMesh.uniqueFaceIndexList);
% 
% % Hmm.  We get a divide by zero somtimes, indicating that the 2D area is
% % zero.  That can't be good.  I protected this by adding eps.  But that is
% % just to spare the user.
% errorList = areaList3D./(areaList2D + eps);
% zeroAreaList = find(areaList2D == 0);
% if ~isempty(zeroAreaList), fprintf('Zero 2D area (nodes): %.0f\n',zeroAreaList); end
% 
% % In order to plot this as a nice picture, we want to find the (x,y) center
% % of mass of each 2D face.
% % I think cogs means center-of-gravity (BW).  I am not sure we use this
% % any more, and I am not sure we use the areaList stuff above, either.
% [areaErrorMap,meanX,meanY] =  mfmAreaErrorMap(unfoldMesh, nFaces, unfolded2D,errorList);

%--------------------------------------------
%Step 4.  The unfoldMesh is complete. Now we adjust the spacing of the
%points so they don't bunch up too much.  The method is to find a cartesian
%grid within the data, find a Delaunay triangulation of this grid, and then
%use a series of affine transformations to transform each of the triangles
%to an equal area representation with the proper grid topology.  This is
%explained in more detail in flatAdjustSpacing
%--------------------------------------------

% if (adjustSpacing)
%     str = sprintf('Spacing points (method = %s)',spacingMethod);
%     statusStringAdd(statusHandle,str);
% 
%     unfoldMesh.maxFractionDist = 0.8;
%     unfoldMesh.gridSpacing = gridSpacing;
%     unfoldMesh.locs2d = unfolded2D(:,1:2);
%     unfoldMesh.startCoords = startCoords;
%     unfoldMesh.scaleFactor = scaleFactor;
% 
%     % The user can select Cartesian or Polar spacing methods.  Only
%     % Cartesian is working now, though, I think -- BW
%     [newLocs2d,goodIdx] = flatAdjustSpacing(unfoldMesh,spacingMethod);
% end

if (showFigures), mfmPlotMesh(unfoldMesh); end

% Finally - the mapping of grey to mesh points takes place using the entire mesh.
% Therefore, we need to generate X for the mesh as well as the unfold mesh

% insideNodes is an array of indices into the original (non-bounded) mesh.
% Each entry in insideNodes relates a point in the unfoldMesh to a point in
% the original mesh

% Recover the perimeter and internal points
msh.X = zeros(length(msh.vertices),2);

% In order to deal with a cropped mesh (as generated by flatAdjustSpacing)
% we need to compute the ... Alex?
if (adjustSpacing)

    msh.X(insideNodes(goodIdx),:)=newLocs2d;
    hasCoords=insideNodes(goodIdx);

else

    unfoldToOrigPerimeter = insideNodes(unfoldMesh.orderedUniquePerimeterPoints);
    unfoldToOrigInside    = insideNodes(unfoldMesh.internalNodes);

    msh.X(unfoldToOrigPerimeter,:)= unfoldMesh.X_zero;
    msh.X(unfoldToOrigInside,:)   = unfoldMesh.X;
    hasCoords=[unfoldToOrigPerimeter(:);unfoldToOrigInside(:)];

end

coords = msh.X(hasCoords,:);
dists  = msh.dist(hasCoords);

% use griddata to image the distance map
warning off MATLAB:griddata:DuplicateDataPoints;
msh.distMap=makeMeshImage(coords,dists,128);
warning on MATLAB:griddata:DuplicateDataPoints;

ZI = msh.distMap; %#ok<NASGU>

if (showFigures), mfmPlotDist(msh); end

% Record which nodes in the big mesh are in the unfold
msh.insideNodes = insideNodes;

% if (SAVE_INTERMEDIATE)
%     % statusStringAdd(statusHandle,'Saving intermediate data.');
%     save ('meshOutTemp.mat','msh');
% end

%------------------------------------------------
% Step 5.  We have the unfolded mesh.  We assign gray matter locations to the
% unfolded positions
%------------------------------------------------

% statusStringAdd(statusHandle,'Reading gray graph...');
numGrayLayers = 4;
[gNodes,gEdges] = mrgGrowGray(classData,numGrayLayers);
% [gNodes, gEdges, gvSize] = readGrayGraph_progress(grayFileName,0);
% 
% % Do all the gray node stages in a loop so that we can have arbitrary
% % numbers of layers.
% numGrayLayers=max(gNodes(6,:));
% 
% Get the indices for all the gnodes (all layers)
for t=1:numGrayLayers
    grayNodeIndices{t}=find(gNodes(6,:)==t);
end

% Extract the layer 1 nodes. These are special because they are used to map
% down to the unfolded boundary mesh.
l1gNodes = gNodes(:,grayNodeIndices{1});
l1mesh.vertices = l1gNodes(1:3,:);
l1mesh.indices  = grayNodeIndices{1};

% % How many gNodes are there?
% nGnodes=length(gNodes);
% % How many gEdges are there?
% nGedges=length(gEdges);

% We want to make a grey node connection matrix - which grey nodes are connected to which other gnodes?
% statusStringAdd(statusHandle,'Finding grey connection matrix (slow)');

grayConMat = makeGrayConMat2(gNodes,gEdges);

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

% statusStringAdd(statusHandle,'Mapping L1 to mesh.');

% Find 3D coords of all the l1 gnodes
l1GNodeCoords=l1gNodes(1:3,:)';

% Find 3D coords of all the mesh points (not just the unfolded ones)
meshCoords=msh.vertices';

% Mesh coords are in voxels, gnode coords are in voxels. Bring them into alignment
% Use this -1 to bring them into perfect alignment. 
% This was the source of an error in V1.0
l1GNodeCoordsN=l1GNodeCoords-1; 

% Now restrict the mesh coords to just those points in the unfold
meshCoordsN = meshCoords(msh.insideNodes,:);

% And now restrict the set of l1 gray nodes so that only those that are relatively near the
% mesh are included in the search - this is done first as a simple bounds check
boundedL1NodeIndices=boundsCheck3D(min(meshCoordsN)-3,max(meshCoordsN)+3,l1GNodeCoordsN);
boundedL1GNodes=l1GNodeCoordsN(boundedL1NodeIndices,:);
boundedL1NodeIndices=grayNodeIndices{1}(boundedL1NodeIndices); % This is now a list of indices into the full gNode array

% statusStringAdd(statusHandle,'Finding nearest Ll gray points to mesh (very slow)');

% Find mesh points near the l1 gNodes
[boundedL1toMeshIndices,sqrDist]=assignToNearest((meshCoordsN),boundedL1GNodes);

% This returns a list of indices into the meshCoordsN array that links a
% single 3D mesh point to each l1Gnode) and then eliminate any l1gNodes
% that are more than a set distance away from the mesh - here sqrt(0.25)

% *************************
closeEnough = find(sqrDist<=0.2501);
% *************************

% remember, assignToNearest returns the squared distance
boundedL1toMeshNodes  = boundedL1GNodes(closeEnough,:); 
boundedL1toMeshIndices= boundedL1toMeshIndices(closeEnough);

% For each member of the bounded l1Gnodes, this tells us the index of the full mesh point that it maps to.
fullBoundedL1toMeshIndices=insideNodes(boundedL1toMeshIndices);

restNodeIndices{1}=boundedL1NodeIndices(closeEnough);

% statusStringAdd(statusHandle,'Setting L1 glocs');
% We can start setting gLocs
% Note the +1 here! Because we subtracted 1 from the original node coords
% to align them with the mesh.
layerGlocs3d{1} = boundedL1toMeshNodes+1;
layerGlocs2d{1} = msh.X(fullBoundedL1toMeshIndices,:);

numNodes(1) = length(layerGlocs3d{1});

layerCurvature{1} = msh.colors(1,fullBoundedL1toMeshIndices)';

if (showFigures)
    mfmPlotMeshLayer(grayConMat(restNodeIndices{1},restNodeIndices{1}),...
        layerGlocs2d{1});
end

% Now we have to find l2tol1Indices, l3tol2Indices and l4tol3Indices. This
% is faster since for each point, we restrict its  potential nearest
% neighbours to points that it is connected to in the previous layer.  We
% also restrict the l2 nodes to just those that are connected to the
% restricted l1 nodes and the l3 nodes to those connected to the l2 nodes.
% Use the full connection matrix to find which l2 Gnodes are connected to the restricted l1Gnodes
% statusStringAdd(statusHandle,'Mapping other gray layers (2,3,4..)');

% Set up the 3 critical arrays curvature, gLocs2d, gLocs3d. These are what
% eventually get written to the flat.
meshCurvature = layerCurvature{1};
gLocs2d = layerGlocs2d{1};
gLocs3d = layerGlocs3d{1};

for t=2:numGrayLayers
    % Finds all the things connected to the t-1th layer...
    layerInterconnect=grayConMat(:, restNodeIndices{t-1});
    [restNodeIndices{t},dummy]   = find(layerInterconnect);
    restNodeIndices{t}           = unique(restNodeIndices{t});
    
    % Only take potential l2 node indices
    restNodeIndices{t} = intersect(restNodeIndices{t},grayNodeIndices{t});
    finalConnectIndices{t-1} = findNearestConnected(gNodes', restNodeIndices{t},restNodeIndices{t-1},grayConMat);

    % Set glocs3d, glocs2d, meshCurvature
    layerGlocs3d{t} = gNodes(1:3,restNodeIndices{t})';
    numNodes(t)     = length(layerGlocs3d{t});
    layerGlocs2d{t} = layerGlocs2d{t-1}(finalConnectIndices{t-1},:);
    layerCurvature{t} = zeros(length(finalConnectIndices{t-1}),1);
    gLocs2d = [gLocs2d;layerGlocs2d{t}];
    gLocs3d = [gLocs3d;layerGlocs3d{t}];
    meshCurvature = [meshCurvature;layerCurvature{t}];

end

if (showFigures), mfmPlotgLocs2d(numGrayLayers,layerGlocs2d); end

toc

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

endTime = now;

%----------------------------------
% Step 6.
% Save stuff
%----------------------------------

% Always show the curvature map, even when the others are suppressed.
% mRange=linspace(-perimDist,perimDist,256);
% unfoldPlotCurvatureMap(gLocs2d,numNodes,mRange,layerCurvature);
% 
% if (saveExtra)
% 
%     % statusStringAdd(statusHandle,'Saving user data.');
%     % statusString=char(get(statusHandle,'UserData'));
% 
%     % This is the number of l1,l2,l3 and l4 nodes in gLocs3d.
%     % Useful for identifying the layers of the
%     % various gLocs3d points (since gLocs3d is generated by concatenating l1,l2,l3,l4 gLocs3d)
%     infoStr.numNodes.num=numNodes;
%     infoStr.numNodes.comment='This is the number of L1,L2,L3 and L4 nodes in gLocs3d. useful for identifying the layers of the various gLocs3d points (since gLocs3d is generated by concatenating L1,L2,L3,L4 gLocs3d)';
% 
%     % Save area error maps
%     infoStr.faceArea.areaList3D=areaList3D;
%     infoStr.faceArea.areaList2D=areaList2D;
%     infoStr.faceArea.uniqueFaces=unfoldMesh.uniqueFaceIndexList;
%     infoStr.faceArea.errorMap=areaErrorMap;
%     infoStr.faceArea.comment='Error map calculated using the center of gravity of the faces and the 3D area/2D area of each face';
%     infoStr.faceArea.faceCOGs=[meanY,meanX];
%     infoStr.faceArea.errorList=errorList;
%     infoStr.faceArea.originalUnfoldMeshVertexList=unfoldMesh.uniqueVertices;
% 
%     infoStr.perimDist=perimDist;
% 
%     infoStr.startTime=datestr(startTime);
%     infoStr.endTime=datestr(endTime);
%     infoStr.perimType=truePerimDist;
% 
%     infoStr.meshFile=meshFileName;
%     infoStr.grayFile=grayFileName;
% 
%     unfoldMeshSummary.startCoords=startCoords;
%     unfoldMeshSummary.connectionMatrix = unfoldMesh.connectionMatrix;
%     unfoldMeshSummary.uniqueVertices = unfoldMesh.uniqueVertices;
%     unfoldMeshSummary.uniqueFaceIndexList = unfoldMesh.uniqueFaceIndexList;
%     unfoldMeshSummary.internalNodes = unfoldMesh.internalNodes;
%     unfoldMeshSummary.orderedUniquePerimeterPoints = unfoldMesh.orderedUniquePerimeterPoints;
%     unfoldMeshSummary.scaleFactor = mmPerPix;
%     unfoldMeshSummary.locs2d = unfolded2D(:,1:2);
%     unfoldMeshSummary.fullBoundedL1toMeshIndices=fullBoundedL1toMeshIndices; % These are indices into the layer 1 gNodes that each mesh point maps to.
% 
%     % we convert the mrGray color index (0-255) to a -1 to 1 curvature value:
%     unfoldMeshSummary.curvature = meshCurvature;
% 
%     save (flatFileName,'gLocs2d','gLocs3d','meshCurvature','statusString','infoStr','ZI','unfoldMeshSummary');
% else
%     save (flatFileName,'gLocs2d','gLocs3d','meshCurvature');
% end





