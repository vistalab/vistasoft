
grayFileName='test.gray';

[gNodes, gEdges, gvSize] = readGrayGraph_progress(grayFileName,0);


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
%statusStringAdd(statusHandle,'Finding grey connection matrix (slow)');

grayConMat=makeGrayConMat(gNodes,gEdges,0);


% We can assign layer 1 grey nodes to the white matter mesh using assignToNearest.dll (see assignToNearest.c)
% Can't do this for higher levels of grey matter 'cos they might get mis-assigned. (Also, potential problem near 
% very crinkly edges. - Could we accidentally assign a l1 grey matter node to the wrong WM point?)
% (I think the answer is 'yes, rarely'. If a single layer or gray is sandwiched between two sides of a sulcus (say) : It's grown from
% one side but mrFlatMesh has no way of telling which one. 
% Going deeper into mrGray's source code to determine the parentage of l1 gray nodes might be possible...)


% So for higher grey matter points, we have to restrict the possible sub node search space by assigning them >only< to 
% points they are connected to. Note that a single layer2 grey node may be connected to several l1 nodes


% The gray may be defined over the entire mesh but we only want to deal with gray points over the 
% unfolded part. The strategy should be....
% 1) do assignToNearest for each mesh point to find the nearest connected l1 node
% 2) Use the set of l1 nodes found in 1) to build up a list of other connected gray nodes
% 3) Repeat stage 2 for l3,l4

%statusStringAdd(statusHandle,'Mapping L1 to mesh.');

% Find 3D coords of all the l1 gnodes
l1GNodeCoords=l1gNodes(1:3,:)';

% Find conmat of l1 gNodes
l1conMat=grayConMat(grayNodeIndices{1},grayNodeIndices{1});

% Find the 3d neighbour distances
mesh.connectionMatrix=l1conMat;
mesh.uniqueVertices=l1GNodeCoords;
scaleFactor=[1 1 1];

D=find3DNeighbourDists(mesh,scaleFactor); % We're now in a voxel framework: everything has been scaled in the mrReadMrM function. 
perimDist=30;
startNode=1000; % I don't know where this is
mesh.dist=dijkstra(D,startNode);

mesh.perimDist=perimDist;

[perimeterEdges,eulerCondition]=findLegalPerimeters(mesh,perimDist);
gplot3(mesh.connectionMatrix,mesh.uniqueVertices) ;
