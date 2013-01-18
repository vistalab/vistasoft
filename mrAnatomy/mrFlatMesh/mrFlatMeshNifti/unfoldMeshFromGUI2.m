function unfoldMeshFromGUI2(classFileName, flatFileName, ...
     startCoords, perimDist, showFigures, saveExtra, truePerimDist)
% Unfold a surface mesh using parameters established in mrFlatMesh (GUI)
%
%  unfoldMeshFromGUI2(classFileName, flatFileName, ...
%     startCoords, perimDist, showFigures, saveExtra, truePerimDist)
% Unfolds a properly triangulated mesh using Floater/Tutte's sparse linear
% matrix method. Then maps layer one grey nodes to the flattened mesh and
% squeezes remaining grey layers to L1 to generate a flat.mat file for use
% with mrLoadRet/mrVista
%
%    1. Read in the white matter boundary mesh created by mrGray.  The data
%    in the white matter mesh are organized into the mesh data structure.
%    2. The second section pulls out the portion of this entire mesh that
%    will
%    be unfolded, creating the unfoldMesh structure.  This is the portion
%    of
%    the full mesh that is within the criterion distance from the
%    startCoords.
%    3. The data in the unfoldMesh are flattened.
%    4. The flat positions are adjusted to make the spacing more nearly
%    like the true distances.
%    5. Gray matter data to the flat map positions, building gLocs2d and
%    gLocs3d that are used by mrVista/mrLoadRet.
%
% See Also:  mrFlatMesh (the GUI that calls this).
%
% Stanford University
% classFileName = 'C:\u\brian\Matlab\mrDataExample\anatomy\nakadomari\right\20040311\right.Class';
% NPERIMS            = 1;
% SAVE_INTERMEDIATE  = 0;
% NUMBLURSTEPS       = 20; % Blur the curvature map a little in a connection-dependent manner
%  % Start up a Nakadomari data set, such as the 3 Deg one
if (length(startCoords)~=3), error ('Error: you must enter 3 start coords'); end
if ieNotDefined('spacingMethod'), spacingMethod = 'None'; end
if ieNotDefined('gridSpacing'), gridSpacing = 0.4; end
if ieNotDefined('showFigures'), showFigures = 0; end
if ieNotDefined('perimDist'), perimDist = 60; end
if ieNotDefined('saveExtra'), saveExtra = 0; end
% Only reason we need mrVista to be running.  If we just send in the
% mmPerPix, we can eliminate this.
global vANATOMYPATH;
mmPerPix = readVolAnatHeader(vANATOMYPATH);
%classFileName = 'C:\u\brian\Matlab\mrDataExample\anatomy\nakadomari\left\20040311\left.Class';
% This start coord is from the left hemisphere of Nakadomari 3 deg
% In  mrFlatMesh GUI these are: X Y Z. In brain these are
%startCoords = [220 135 121];       % Ant/Post, Sup/Inf, Left/Right
%perimDist   =  20;
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
% Save space
clear smoothMesh;
scaleFactor = mmPerPix; % mm per voxel
% We'll do everything below in mm space, so we need to scale the
% startCoords to mm space. The mesh vertices 9as returned by
% meshBuildFromClass are in mm space.
startCoords = startCoords.*scaleFactor;
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
% N.B.  The indices in the msh.triangles start from 0, not 1.  So we have
% to be careful in all of these routines to add 1 when we do the indexing.
%
% Now we find the connection matrix:
% a sparse matrix of nxn points where M(i,j) is 1 if i and j are connected
msh.connectionMatrix = findConnectionMatrix2(msh);
% figure; spy(msh.connectionMatrix)
% Check to make sure that this is a clean mesh: no edge points yet.
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
D = sqrt(find3DNeighbourDists2(msh,scaleFactor));
% Find distances from the startNode to all the nodes
msh.dist = dijkstra(D,startNode);
% We now have the basic mesh information.  We are starting to identify the
% perimeter and inside nodes for flattening. We generate a perimeter, based
% on the user's choice of perimeter distasnce  by thresholding these
% distances
msh.perimDist = perimDist;
% Though, this number is not used here other than for printing out.
perimeterEdges = findLegalPerimeters2(msh,perimDist);
% The routine above can generate islands - fix it by zeroing the connection
% matrix for the largest perimeter and then doing a flood fill with no
% limits to generate the inside group
% uniquePerimPoints=unique(perimeterEdges(:));
[orderedUniquePerimeterPoints,biggest] = ...
    orderMeshPerimeterPointsAll(msh,perimeterEdges);
% nPerims = size(orderedUniquePerimeterPoints);
orderedUniquePerimeterPoints = orderedUniquePerimeterPoints{biggest}.points;
% DO THE FLOOD FILL TO FILL UP THE INNER HOLES
tempConMat  = msh.connectionMatrix; % save it for later
msh.connectionMatrix(orderedUniquePerimeterPoints,:) = 0;
msh.connectionMatrix(:,orderedUniquePerimeterPoints) = 0;
insideNodes = floodFillFindPerim(msh,Inf,startNode);
insideNodes = [insideNodes(:); orderedUniquePerimeterPoints(:)];
msh.connectionMatrix = tempConMat;
perimeterEdges = findGroupPerimeter2(msh,insideNodes);
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
[unfoldMesh, nFaces] = ...
    mfmBuildSubMesh2(msh, perimeterEdges, insideNodes, ...
    orderedUniquePerimeterPoints);
%-------------------------------------------------
% Step 3.  Unfold the unfoldMesh.  This is the key mathematical step in the
% process.
%-------------------------------------------------
% Find the N and P connection matrices
% statusStringAdd(statusHandle,'Finding sub-mesh connection matrix.');
[N, P, unfoldMesh.internalNodes] = findNPConnection(unfoldMesh);
% Here we find the squared 3D distance from each point to its neighbours.
unfoldMesh.distSQ = find3DNeighbourDists(unfoldMesh,scaleFactor);
fullConMatScaled = scaleConnectionMatrixToDist(sqrt(unfoldMesh.distSQ));
% Now split the full conMat up until N and P
N = fullConMatScaled(unfoldMesh.internalNodes,unfoldMesh.internalNodes);
P = fullConMatScaled(unfoldMesh.internalNodes,unfoldMesh.orderedUniquePerimeterPoints);
% Assign the initial perimeter points - they're going to go in a circle for now...
% Can set distances around circle to match actual distances from the center.
unfoldMesh.X_zero = assignPerimeterPositions(perimDist,unfoldMesh);
% THIS IS WHERE WE SOLVE THE POSITION EQUATION -
% THIS EQUATION IS THE HEART OF THE ROUTINE!
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
indices2D  = unfoldMesh.orderedUniquePerimeterPoints;
unfolded2D(indices2D,1:2) = full(unfoldMesh.X_zero);
unfolded2D(:,3) = 0;
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
if (showFigures), unfoldMeshFigure(unfoldMesh); end
% Finally - the mapping of grey to mesh points takes place using the entire mesh.
% Therefore, we need to generate X for the mesh as well as the unfold mesh
% insideNodes is an array of indices into the original (non-bounded) mesh.
% Each entry in insideNodes relates a point in the unfoldMesh to a point in
% the original mesh
% Recover the perimeter and internal points
msh.X = zeros(length(msh.vertices),2);
% In order to deal with a cropped mesh (as generated by flatAdjustSpacing)
% we need to compute the ... Alex?
if (exist('adjustSpacing','var') && adjustSpacing)
    msh.X(insideNodes(goodIdx),:)=newLocs2d;
    hasCoords=insideNodes(goodIdx);
else
    unfoldToOrigPerimeter = insideNodes(unfoldMesh.orderedUniquePerimeterPoints);
    unfoldToOrigInside = insideNodes(unfoldMesh.internalNodes);
    msh.X(unfoldToOrigPerimeter,:)=unfoldMesh.X_zero;
    msh.X(unfoldToOrigInside,:)=unfoldMesh.X;
    hasCoords=[unfoldToOrigPerimeter(:);unfoldToOrigInside(:)];
end
coords = msh.X(hasCoords,:);
dists  = msh.dist(hasCoords);
% use griddata to image the distance map
warning off MATLAB:griddata:DuplicateDataPoints;
msh.distMap=makeMeshImage(coords,dists,128);
warning on MATLAB:griddata:DuplicateDataPoints;
ZI = msh.distMap; %#ok<NASGU>
% if (showFigures), unfoldDistFigure(msh); end
% Record which nodes in the big mesh are in the unfold
msh.insideNodes=insideNodes;
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
meshCoordsN=meshCoords(msh.insideNodes,:);
% And now restrict the set of l1 gray nodes so that only those that are relatively near the
% mesh are included in the search - this is done first as a simple bounds check
boundedL1NodeIndices=boundsCheck3D(min(meshCoordsN)-3,max(meshCoordsN)+3,l1GNodeCoordsN);
boundedL1GNodes=l1GNodeCoordsN(boundedL1NodeIndices,:);
boundedL1NodeIndices=grayNodeIndices{1}(boundedL1NodeIndices); % This is now a list of indices into the full gNode array
% statusStringAdd(statusHandle,'Finding nearest Ll gray points to mesh (very slow)');
 
% Find mesh points near the l1 gNodes
disp(size(meshCoordsN))
disp(size(boundedL1GNodes))
[boundedL1toMeshIndices,sqrDist]=nearpoints(double(boundedL1GNodes)',double(meshCoordsN'));
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
    unfoldPlotL1Mesh(grayConMat(restNodeIndices{1},restNodeIndices{1}),layerGlocs2d{1});
end
% Now we have to find l2tol1Indices, l3tol2Indices and l4tol3Indices. This
% is faster since for each point, we restrict its  potential nearest
% neighbours to points that it is connected to in the previous layer.  We
% also restrict the l2 nodes to just those that are connected to the
% restricted l1 nodes and the l3 nodes to those connected to the l2 nodes.
% Use the full connection matrix to find which l2 Gnodes are connected to
% the restricted l1Gnodes
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
if (showFigures)
    unfoldPlotgLocs2d(numGrayLayers,layerGlocs2d); 
end
% statusStringAdd(statusHandle,'Creating flat.mat structure');
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
mRange=linspace(-perimDist,perimDist,256);
unfoldPlotCurvatureMap(gLocs2d,numNodes,mRange,layerCurvature);
%% - --------------------
% At this point we can save out a submesh in a format that mrMesh can
% understand. e.g. 
%     name: 'leftSmooth'
%                   type: 'vistaMesh'
%                   host: 'localhost'
%                     id: 1001
%               filename: 'X:\anatomy\frazor\meshes\left_standard_021908'
%                   path: 'X:\anatomy\frazor\meshes'
%                  actor: 32
%               mmPerVox: [1 1 1]
%                 lights: {[1x1 struct]  [1x1 struct]}
%                 origin: [-149.7884 -110.7920 -96.8690]
%           initVertices: [3x141782 double]
%               vertices: [3x141782 double]
%              triangles: [3x283560 double]
%                 colors: [4x141782 double]
%                normals: [3x141782 double]
%              curvature: [1x141782 double]
%             grayLayers: 0
%          vertexGrayMap: [5x141782 int32]
%                 fibers: []
%     smooth_sinc_method: 0
%      smooth_relaxation: 0.5000 
%      smooth_iterations: 32
%              mod_depth: 0.2500
%c=repmat(mesh.uniqueCols(insideNodes,:)',3,1);
c=ones(3,length(insideNodes))*128;
c=fix([c;ones(1,length(c))*255]);
msh.name='test';
msh.type='vistaMesh'
msh.host='localhost';
msh.id=1001;
msh.filename='';
msh.path='';
msh.actor=32;
msh.mmPerVox=[1 1 1];
 
msh.origin=-[mean(unfolded2D)];
msh.initVertices=unfoldMesh.uniqueVertices';
msh.vertices=unfolded2D';
disp(min(unfoldMesh.uniqueFaceIndexList));
fl=unfoldMesh.uniqueFaceIndexList'-1;
msh.triangles=[fl,fl([3 2 1],:)]; % NOTE ZERO INDEXING! We double and reverse the faces so that you can see the unfolded mesh from both sides.
msh.colors=unfoldMesh.uniqueCols';
% This next bit might be unnecessary. We render using patch and then
% extract the normals, faces etc from the matlab version. In the old mesh
% we didn't have good estimates of normals. But in the mrMesh meshes I
% think we do so we should just bypass then next 4 lines.
figure(200);
l=patch('Faces',msh.triangles'+1,'Vertices',msh.vertices','FaceVertexCData',msh.colors(1,:)','FaceColor','interp');
msh.normals=[get(l,'VertexNormals')]';
msh.triangles=[get(l,'Faces')]'-1; % NOTE ZERO INDEXING!
msh.curvature=[(c(1,:)-128)/255];
msh.grayLayers=0;
msh.vertexGrayMap=[];
msh.fibers=[];
msh.smooth_sinc_method=0;
msh.smooth_relaxation=0.5000;
msh.smooth_iterations=32;
msh.mod_depth=0.2500;
save([flatFileName,'_meshVersion.mat'],'msh'); % Get a better way of naming the file in the future...
if (saveExtra)
    % statusStringAdd(statusHandle,'Saving user data.');
    % statusString=char(get(statusHandle,'UserData'));
    % This is the number of l1,l2,l3 and l4 nodes in gLocs3d.
    % Useful for identifying the layers of the
    % various gLocs3d points (since gLocs3d is generated by concatenating l1,l2,l3,l4 gLocs3d)
    infoStr.numNodes.num=numNodes;
    infoStr.numNodes.comment='This is the number of L1,L2,L3 and L4 nodes in gLocs3d. useful for identifying the layers of the various gLocs3d points (since gLocs3d is generated by concatenating L1,L2,L3,L4 gLocs3d)';
    % Save area error maps
    infoStr.faceArea.areaList3D=areaList3D;
    infoStr.faceArea.areaList2D=areaList2D;
    infoStr.faceArea.uniqueFaces=unfoldMesh.uniqueFaceIndexList;
    infoStr.faceArea.errorMap=areaErrorMap;
    infoStr.faceArea.comment='Error map calculated using the center of gravity of the faces and the 3D area/2D area of each face';
    infoStr.faceArea.faceCOGs=[meanY,meanX];
    infoStr.faceArea.errorList=errorList;
    infoStr.faceArea.originalUnfoldMeshVertexList=unfoldMesh.uniqueVertices;
    infoStr.perimDist=perimDist;
    infoStr.startTime=datestr(startTime);
    infoStr.endTime=datestr(endTime);
    infoStr.perimType=truePerimDist;
    infoStr.meshFile=meshFileName;
    infoStr.grayFile=grayFileName;
    unfoldMeshSummary.startCoords=startCoords;
    unfoldMeshSummary.connectionMatrix = unfoldMesh.connectionMatrix;
    unfoldMeshSummary.uniqueVertices = unfoldMesh.uniqueVertices;
    unfoldMeshSummary.uniqueFaceIndexList = unfoldMesh.uniqueFaceIndexList;
    unfoldMeshSummary.internalNodes = unfoldMesh.internalNodes;
    unfoldMeshSummary.orderedUniquePerimeterPoints = unfoldMesh.orderedUniquePerimeterPoints;
    unfoldMeshSummary.scaleFactor = scaleFactor;
    unfoldMeshSummary.locs2d = unfolded2D(:,1:2);
    unfoldMeshSummary.fullBoundedL1toMeshIndices=fullBoundedL1toMeshIndices; % These are indices into the layer 1 gNodes that each mesh point maps to.
    % we convert the mrGray color index (0-255) to a -1 to 1 curvature value:
    unfoldMeshSummary.curvature = meshCurvature;
    save (flatFileName,'gLocs2d','gLocs3d','meshCurvature','statusString','infoStr','ZI','unfoldMeshSummary');
else
    save (flatFileName,'gLocs2d','gLocs3d','meshCurvature');
end
return;
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
%----------------------------------
function unfoldMeshFigure(msh)
figure;
hold off;
gplot(msh.N,msh.X);
title ('Unfolded mesh'); axis equal; axis off; zoom on
return;
%----------------------------------
function unfoldDistFigure(msh)
figure
imagesc(msh.distMap);
axis image; colormap hot; title('Manifold distance map'); colorbar;
return;
%----------------------------------
function unfoldPlotL1Mesh(x,layer1Glocs2d)
figure;
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
%----------------------------------
function unfoldPlotCurvatureMap(gLocs2d,numNodes,mRange,layerCurvature)
[y x] = meshgrid(mRange);
warning off MATLAB:griddata:DuplicateDataPoints;
fl = griddata(gLocs2d(1:numNodes(1),1),gLocs2d(1:numNodes(1),2),layerCurvature{1},x,y);
warning on MATLAB:griddata:DuplicateDataPoints;
figure;
imagesc((rot90(fl))); colormap gray; title('Curvature map'); axis image
return;
