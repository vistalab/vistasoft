function successFlag=unfoldMeshFromGUI(meshFileName,grayFileName,flatFileName,startCoords,scaleFactor,perimDist,statusHandle,busyHandle,showFigures,saveExtra,truePerimDist);
% function successFlag=unfoldMeshFromGUI(meshFileName,grayFileName,flatFileName,startCoords,scaleFactor,perimDist,statusHandle,busyHandle,showFigures,saveExtra,truePerimDist);
% To be called from unfoldMeshAlpha.m
% This is pre-release code 0.1
% 
% ARW 021401
% Unfolds a legally-triangulated mesh using floater/tuele's sparse linear matrix method. Then maps L1 grey nodes to the flattened
% mesh and squeezes remaining grey layers to L1 to generate a flat.mat file for use in mrLoadRet


NPERIMS=1;
SAVE_INTERMEDIATE=0;

if (length(startCoords)~=3)
	error ('Error: you must enter 3 start coords');
end

startTime=now;

% READ IN THE ORIGNIAL MRGRAY MESH
statusStringAdd(statusHandle,['Loading: ',meshFileName]);

mesh=mrReadMrM(meshFileName,0); % 
statusStringAdd(statusHandle,'Finding faces');

mesh.faceIndexList=findFaces(mesh,busyHandle);
% The entries in mesh.vertices aren't unique. That is, the same
% vertex can be represented by two different numbers.  This happens
% because strips always contain shared vertices.
%
% This next series of functions finds the unique vertices and
% and builds hash tables for vert->uniqueVerts and uniqueVerts->vert.
% Using these tables, we can adjust the list of colors and faces
% to represent each vertex by a unique index.

[mesh.uniqueVertices,mesh.vertsToUnique,mesh.UniqueToVerts]= unique(mesh.vertices,'rows'); % Get rid of identical points
mesh.uniqueVertices=mesh.uniqueVertices./(repmat(scaleFactor,length(mesh.uniqueVertices),1));
mesh.uniqueNormal=mesh.normal(mesh.vertsToUnique);

mesh.uniqueCols=mesh.rgba(mesh.vertsToUnique,:); % try to assign the colors that came in from mrGray

mesh.uniqueFaceIndexList=findUniqueFaceIndexList(mesh); % this gets rid of faces with multiple duplicate vertices and different permutations of the same face

% Now we find the connection matrix: 
% a sparse matrix of nxn points where M(i,j) is 1 if i and j are connected

statusStringAdd(statusHandle,'Finding connection matrix.');

[mesh.connectionMatrix]=findConnectionMatrix(mesh);
messageString=sprintf('%d connections found',length(mesh.connectionMatrix));
statusStringAdd(statusHandle,messageString);

statusStringAdd(statusHandle,'Checking group perimeter.');

% Check to make sure that this is a clean surface: no edge points yet.
edgeList=findGroupPerimeter(mesh,1:length(mesh.uniqueVertices));
if (~isempty(edgeList))
	error('Error - initial mesh is not closed!');
	break;
else
	fprintf('\nInitial mesh is closed');
end

statusStringAdd(statusHandle,'Finding closest mesh point.');

% **********************************
% THIS IS ****** CHECKPOINT 1 ******
% **********************************

[startNode,snDist]=assignToNearest(mesh.uniqueVertices,startCoords);

messageString=sprintf('Start node %d selected at %d voxel units from input coords.',startNode,sqrt(snDist));
statusStringAdd(statusHandle,messageString);

if (sqrt(snDist)>15)
	beep;
	messageString=sprintf('** Warning: mesh node far from start coord. Expect trouble.');
	statusStringAdd(statusHandle,messageString)
end

% Have replaced mrManDist with dll dijkstra
statusStringAdd(statusHandle,'Finding distances from start node');

D=find3DNeighbourDists(mesh,scaleFactor);

% find distances to all the nodes
% When we go to the newer mrGray, dimdist can
% be recovered from the mesh.parameters field, we think.
% Probably mesh.parameters.voxsize.  See mrReadMrM.m

mesh.dist=dijkstra(D,startNode);

% Now we want to generate a perimeter by thresholding these distances
% First find a good distance to take for the perimeter

mesh.perimDist=perimDist;
messageString=sprintf('Perimeter minimum distance=%d',perimDist);
statusStringAdd(statusHandle,messageString);

statusStringAdd(statusHandle,'Using threshold to find perimeter(s).');

% Find perims with simple thold
insideNodes=find(mesh.dist<=perimDist);
insideNodes=insideNodes(:);

% Eliminate 'hanging nodes' : nodes that are not part of a face:
%insideNodes=removeHangingNodes(mesh,insideNodes);

statusStringAdd(statusHandle,'Internal nodes found. Defining perimeter.');

% Find the perimeter points of this group (there can be more than perimeter at this point)
numBadNodes=9999999;
 [perimeterEdges,eulerCondition]=findGroupPerimeter(mesh,insideNodes);
 
while (numBadNodes>0)
    [perimeterEdges,eulerCondition]=findGroupPerimeter(mesh,insideNodes);
	length(perimeterEdges)
	length(unique(perimeterEdges,'rows'))
    fprintf('\nEuler number=%d',eulerCondition);
    
    badPerimNodes=findBadPerimNodes(mesh,perimeterEdges);
    numBadNodes=length(badPerimNodes)
    disp(badPerimNodes);
	
    
    if(numBadNodes)
        [insideNodes]=setdiff(insideNodes,badPerimNodes);
		%insideNodes=removeHangingNodes(mesh,insideNodes);
    end
end

% The euler number will tell you whether you've got a mesh with no holes in it.

messageString=sprintf('Euler number for this set=%d',eulerCondition);
statusStringAdd(statusHandle,messageString);
uniquePerimPoints=unique(perimeterEdges(:));
messageString=sprintf('%d unique perimeter points found.',length(uniquePerimPoints));
statusStringAdd(statusHandle,messageString);
[orderedUniquePerimeterPoints,biggest]=orderMeshPerimeterPointsAll(mesh,perimeterEdges);
nPerims=size(orderedUniquePerimeterPoints);
fprintf('\n%d different perimeters found',nPerims);
orderedUniquePerimeterPoints=orderedUniquePerimeterPoints{biggest}.points;

%insideNodes=[insideNodes(:),setdiff(perimeterEdges(:),perimeterEdges2(:))];
%perimeterEdges=perimeterEdges2;

% internal points (the ones we want)
unfoldMesh.connectionMatrix=mesh.connectionMatrix(insideNodes,insideNodes);
unfoldMesh.uniqueVertices=mesh.uniqueVertices(insideNodes,:);
unfoldMesh.dist=mesh.dist(insideNodes);


% Convert the edges to feed into orderMeshPerimeterPoints
fullEdgePointList=perimeterEdges(:);

[numEdges,x]=size(perimeterEdges);

newEdges=zeros((numEdges*2),1);
statusStringAdd(statusHandle,'Finding sub-mesh edges.');

for t=1:(numEdges*2)  
	if ((~mod(t,100)) & busyHandle)
		updateBusybar(busyHandle,t);
	end
	newEdges(t)=find(insideNodes==fullEdgePointList(t));
end

newEdges=reshape(newEdges,numEdges,2);
statusStringAdd(statusHandle,'Finding sub-mesh perim.');

% Find the perimeter points.
unfoldMesh.orderedUniquePerimeterPoints=zeros(length(orderedUniquePerimeterPoints),1);

for t=1:length(orderedUniquePerimeterPoints)
	f1=find(insideNodes==orderedUniquePerimeterPoints(t));%
	unfoldMesh.orderedUniquePerimeterPoints(t)=f1;%orderMeshPerimeterPoints(newEdges);

end


% Unfolding bit...
% Now we'd like to unfold this.
% Need the following things...
% Connection matrix N (nxn) - almost the same as the connection matrix except that rows=rows/sum(rows)
% and all points on the perimeter have been removed.
% X0 - a px2 matrix containing the 2D locations of the perimeter points.
% P - The perimeter connection matrix: (nxp) 'whose (i,j)th entry is 1/mi when perimeter node j is connected
% to sample node i. 

% Find the N and P connection matrices
statusStringAdd(statusHandle,'Finding sub-mesh con. mat.');
[N,P,unfoldMesh.internalNodes]=findNPConnection(unfoldMesh);
[unfoldMesh.distSQ]=find3DNeighbourDists(unfoldMesh);   % Here we find the 3D distance from each point to its neighbours.


% Assign the initial perimeter points - they're going to go in a circle for now...
numPerimPoints=length(unfoldMesh.orderedUniquePerimeterPoints);

perimeterDists=mesh.dist(orderedUniquePerimeterPoints); % Distance of each perimeter point from the start node

statusStringAdd(statusHandle,'Assigning perimeter points');

% We'd like to place the perimeter points down in an intelligent manner. We can place them at the correct distance from the start node
% and at the correct distance from each other. I think.
% We already know their distance from the start node, now we'd like to get their distances
% from each other.

% Should be able to extract this from unfoldMesh.distSQ

%  start at the first perimeter point in unfoldMesh.orderedUniquePerimeterPoints
% Find the distance between this and the next point, etc etc...
nPerimPoints=length(unfoldMesh.orderedUniquePerimeterPoints);
interPerimDists=zeros(nPerimPoints,1);

for thisPerimPoint=1:nPerimPoints
	nextIndex=mod((thisPerimPoint+1),nPerimPoints);
	if(nextIndex==0)
		nextIndex=1;
	end
	
	interPerimDists(thisPerimPoint)=unfoldMesh.distSQ(unfoldMesh.orderedUniquePerimeterPoints(thisPerimPoint),unfoldMesh.orderedUniquePerimeterPoints(nextIndex));
end

interPerimDists=sqrt(interPerimDists);


unfoldMesh.X_zero=assignPerimeterPositions(perimeterDists); % Can set distances around circle to match actual distances from the center. 
% Angular positions will come next.

statusStringAdd(statusHandle,'Solving position equation (slow)');
X=(speye(size(N)) - N) \ (sparse(P * unfoldMesh.X_zero));


unfoldMesh.N=N;
unfoldMesh.P=P;
unfoldMesh.X=X;

% Find out the differences between  
dist2DSQ=find2DNeighbourDists(unfoldMesh);
d1=sparse(unfoldMesh.distSQ)-sparse(dist2DSQ);
d1=abs(d1);


goodness=sum(sum(d1.^2));

messageString=sprintf('Current error per node: %d',full(sqrt(goodness))/length(insideNodes));
statusStringAdd(statusHandle,messageString);

% Show the mesh
if (showFigures)

	statusStringAdd(statusHandle,'Displaying unfold');
	figure(50);
	
	hold off;
	gplot(unfoldMesh.N,unfoldMesh.X);
	
	axis equal;
	axis off;
	zoom on

end

% Finally - the mapping of grey to mesh points takes place using the entire mesh. 
% Therefore, we need to generate X for the mesh as well as the unfold mesh'

unfoldToOrigPerimeter=insideNodes(unfoldMesh.orderedUniquePerimeterPoints);
unfoldToOrigInside=insideNodes(unfoldMesh.internalNodes);

mesh.X=zeros(length(mesh.uniqueVertices),2);
mesh.X(unfoldToOrigPerimeter,:)=unfoldMesh.X_zero;
mesh.X(unfoldToOrigInside,:)=unfoldMesh.X;

hasCoords=[unfoldToOrigPerimeter(:);unfoldToOrigInside(:)];
coords=mesh.X(hasCoords,:);%mesh.X(unfoldToOrigInside,:);
dists=mesh.dist(hasCoords);

    
% use griddata to image the distance map

	mesh.distMap=makeDistanceImage(coords,dists,128);
	ZI=mesh.distMap;
	
	if (showFigures)
		figure(51);
		
		imagesc(mesh.distMap);
		axis image;
		
		colormap hot;
		title('Manifold distance map');
		colorbar;
	end

mesh.strain=zeros(length(mesh.uniqueVertices),1);
strain=d1.^2;
mesh.strain(unfoldToOrigPerimeter)=sum(strain(unfoldMesh.orderedUniquePerimeterPoints,:)');
mesh.strain(unfoldToOrigInside)=sum(strain(unfoldMesh.internalNodes,:)');
% Record which nodes in the big mesh are in the unfold
mesh.insideNodes=insideNodes;
if (SAVE_INTERMEDIATE)
	statusStringAdd(statusHandle,'Saving intermediate data.');
	save ('meshOutTemp.mat','mesh');
end


% (At this point, switch to testGray....)

% *********************************************************************************
% ************************************************************************************
% **********************************************************************************

statusStringAdd(statusHandle,'Reading grey graph...');


[gNodes, gEdges, gvSize] = readGrayGraph_progress(grayFileName,0);

% Get the indices for all the gnodes (all 3 layers)
l1NodeIndices=find(gNodes(6,:)==1);
l2NodeIndices=find(gNodes(6,:)==2);
l3NodeIndices=find(gNodes(6,:)==3);
l4NodeIndices=find(gNodes(6,:)==4);

% Extract the layer 1 nodes
l1gNodes=gNodes(:,l1NodeIndices);
l1mesh.vertices=l1gNodes(1:3,:);
l1mesh.indices=l1NodeIndices;


% How many gNodes are there?
nGnodes=length(gNodes);
% How many gEdges are there?
nGedges=length(gEdges);


% We want to make a grey node connection matrix - which grey nodes are connected to which other gnodes?
sp=sparse(nGnodes,nGnodes);
i=zeros(nGnodes*30,1); % no more that 30 conenctions per gNode on average!
j=i;

offset=1;


statusStringAdd(statusHandle,'Finding grey connection matrix (slow)');

for t=1:nGnodes % for each gNode...
	if ((~mod(t,1000)) & busyHandle)
		updateBusybar(busyHandle,t);
	end
	% Find its edges (the nodes of the things that it's connected to...)
	thisOffset=gNodes(5,t);
	thisNumEdges=gNodes(4,t);
	theseEdges=gEdges(thisOffset:(thisOffset-1+thisNumEdges));
	
	% add these to i,j - eventually we'll call sp=sparse(i,j,s,nGnodes,nGnodes)
	% i contains the y coords, j contains the x coords
	endPoint=offset+thisNumEdges-1;
	
	i(offset:endPoint)=ones(1,thisNumEdges)*t;
	j(offset:endPoint)=theseEdges;
	
	offset=endPoint+1;
	
	% % This takes about 18 secs on gwyrdd (nGnodes=32000)
	% and 2.1 seconds on Gwyn :)
end


i=i(1:offset-1);
j=j(1:offset-1);
s=ones(size(i));
sp=sparse(i,j,s,nGnodes,nGnodes);

clear i;
clear j;
clear s;


% We can assign layer 1 grey nodes to the white matter mesh using assignToNearest.dll (see assignToNearest.c)
% Can't do this for higher levels of grey matter 'cos they might get mis-assigned. (Also, potential problem near 
% very crinkly edges. - Could we accidentally assign a l1 grey matter node to the wrong WM point?)

% So for higher grey matter points, we have to restrict the possible sub node search space by assigning them >only< to 
% points they are connected to. Note that a single layer2 grey node may be connected to several l1 nodes


% The gray is defined over the entire mesh but we only want to deal with gray points over the 
% unfolded part. The strategy should be....
% 1) do assignToNearest for each mesh point to find the nearest connected l1 node
% 2) Use the set of l1 nodes found in 1) to build up a list of other connected gray nodes
% 3) Proceed as before...

statusStringAdd(statusHandle,'Mapping L1 to mesh.');
% Find 3D coords of all the l1 gnodes
l1GNodeCoords=l1gNodes(1:3,:)';

% Find 3D coords of all the mesh points (not just the unfolded ones) We have to do this in order
% to shift the two sets to a common mean
meshCoords=mesh.uniqueVertices;

% These coordinate sets seem to have very similar shapes (as we'd expect) but offset to each other. Remove the means to 
% center them (but there must be a better way...);
% Mesh coords are in mm, gnode coords are in voxels:
%scaleFactor=[240/256 240/256 1.2]; % This has to be sent in eventually.... IMPORTANT!


l1GNodeCoordsN=l1GNodeCoords;


% There are roughly half as many l1gnodes as there are unique vertices in the mesh.

% Now restrict the mesh coords to just those points in the unfold
meshCoordsN=meshCoords(mesh.insideNodes,:);

% And now restrict the set of l1 gray nodes so that only those that are relatively near the 
% mesh are included in the search - this is done first as a simple bounds check
boundedL1NodeIndices=boundsCheck3D(min(meshCoordsN)-3,max(meshCoordsN)+3,l1GNodeCoordsN);
boundedL1GNodes=l1GNodeCoordsN(boundedL1NodeIndices,:);
boundedL1NodeIndices=l1NodeIndices(boundedL1NodeIndices); % This is now a list of indices into the full gNode array

statusStringAdd(statusHandle,'Finding nearest Ll gray points to mesh (very slow)');

% Now we >could< restrict further at this point by running
% [meshToBoundedL1Indices,sqrDist]=assignToNearest(boundedL1GNodes,meshCoordsN); 
% to define a subset of l1gNodes closest to the mesh. However, this seems to bugger things up - probably becasue the
% l1gNodes are sampled more densely than the mesh in places.

% What we do instead is run
[boundedL1toMeshIndices,sqrDist]=assignToNearest(meshCoordsN,boundedL1GNodes);
% This returns a list of indices into the meshCoordsN array that links a single 3D mesh point to each l1Gnode)

% and then eliminate any l1gNodes that are more than a set distance away from the mesh - here 3.2mm

% *************************
closeEnough=find(sqrDist<2);
% *************************

boundedL1toMeshNodes=boundedL1GNodes(closeEnough,:); % remember, assignToNearest returns the squared distance
boundedL1toMeshIndices=boundedL1toMeshIndices(closeEnough);

% For each member of the bounded l1Gnodes, this tells us the index of the full mesh point that it maps to.
fullBoundedL1toMeshIndices=insideNodes(boundedL1toMeshIndices);


restL1NodeIndices=boundedL1NodeIndices(closeEnough);
statusStringAdd(statusHandle,'Setting L1 glocs');
% We can start setting gLocs
l1Glocs3d=boundedL1toMeshNodes;
l1Glocs2d=mesh.X(fullBoundedL1toMeshIndices,:);

%l1Curvature=mesh.uniqueNormal(fullBoundedL1toMeshIndices);

l1ConMat=sp(restL1NodeIndices,restL1NodeIndices);

% Prune the l1gray nodes here ? Eliminate connections that are too big (roughly >2 or so.).
% PRUNE
% PRUNE


if (showFigures);
	statusStringAdd(statusHandle,'Displaying L1 gray mesh.');
	figure(8);
	hold off;
	gplot(l1ConMat,l1Glocs2d);
	title('L1 gray mesh');
	zoom on
end

% Now we (only!) have to find l2tol1Indices, l3tol2Indices and l4tol3Indices. This is faster since for each point, we restrict its 
% potential nearest neighbours to points that it is connected to in the previous layer. 
% We also restrict the l2 nodes to just those that are connected to the restricted l1 nodes and the l3 nodes to those connected to the
% l2 nodes.

% Use the full connection matrix to find which l2 Gnodes are connected to the restricted l1Gnodes
statusStringAdd(statusHandle,'Mapping higher levels (2,3,4)');
L1L2sp=sp(:, restL1NodeIndices);

% We assume here that, almost by definition, the only things that l1 nodes connect to are l2 nodes and other l1 nodes
[restL2NodeIndices,dummy]=find(L1L2sp);
restL2NodeIndices=unique(restL2NodeIndices);
restL2NodeIndices=intersect(restL2NodeIndices,l2NodeIndices); % Only take potential l2 node indices

% repeat this for the l3 nodes
L2L3sp=sp(:,restL2NodeIndices);
[restL3NodeIndices,dummy]=find(L2L3sp);
restL3NodeIndices=unique(restL3NodeIndices);
restL3NodeIndices=intersect(restL3NodeIndices,l3NodeIndices);

% repeat again for the l4 nodes
L3L4sp=sp(:,restL3NodeIndices);
[restL4NodeIndices,dummy]=find(L3L4sp);
restL4NodeIndices=unique(restL4NodeIndices);
restL4NodeIndices=intersect(restL4NodeIndices,l4NodeIndices);


% For each l2 node, find the l1 nodes it's connected to, then find the
% 3D coords of the l2 node and all the connected l1 nodes and send them
% in to assignToNearest.


l2ToL1Indices=findNearestConnected(gNodes', restL2NodeIndices,restL1NodeIndices,sp);
l3ToL2Indices=findNearestConnected(gNodes', restL3NodeIndices,restL2NodeIndices,sp);
l4ToL3Indices=findNearestConnected(gNodes', restL4NodeIndices,restL3NodeIndices,sp);

statusStringAdd(statusHandle,'Setting upper levels glocs');
% Set the l2, l3 and l4 glocs3d
l2Glocs3d=gNodes(1:3,restL2NodeIndices)';
l3Glocs3d=gNodes(1:3,restL3NodeIndices)';
l4Glocs3d=gNodes(1:3,restL4NodeIndices)';

% And the gLocs2
l2Glocs2d=l1Glocs2d(l2ToL1Indices,:);
l3Glocs2d=l2Glocs2d(l3ToL2Indices,:);
l4Glocs2d=l3Glocs2d(l4ToL3Indices,:);

% and the curvature
l2Curvature=l1Curvature(l2ToL1Indices);
l3Curvature=l2Curvature(l3ToL2Indices);
l4Curvature=l3Curvature(l4ToL3Indices);


if (showFigures)
	statusStringAdd(statusHandle,'Displaying 2D glocs');
	figure(12);
	hold off;
	subplot(4,1,1);
	plot(l1Glocs2d(:,1),l1Glocs2d(:,2),'.');
	title('L1 2d glocs');
	subplot(4,1,2);
	plot(l2Glocs2d(:,1),l2Glocs2d(:,2),'g.');
	title('L2 2d glocs');
	subplot(4,1,3);
	plot(l3Glocs2d(:,1),l3Glocs2d(:,2),'r.');
	title('L3 2d glocs');
	subplot(4,1,4);
    plot(l4Glocs2d(:,1),l4Glocs2d(:,2),'k.');
	title('L4 2d glocs');


end
% old skool flat.mat structure looks like
%   curvature      47263x1         378104  double array
%   gLocs2d        47263x2         756208  double array
%   gLocs3d        47263x3        1134312  double array
%   gLocs3dfloat       0x0              0  double array
%   startPoint         1x1              8  double array
%   unfList            1x47263     378104  double array
%   xSampGray          1x701         5608  double array


% But all we really need are.....
statusStringAdd(statusHandle,'Creating flat.mat structure');
gLocs2d=[l1Glocs2d;l2Glocs2d;l3Glocs2d;l4Glocs2d];
gLocs3d=[l1Glocs3d;l2Glocs3d;l3Glocs3d;l4Glocs3d];
curvature=[l1Curvature;l2Curvature;l3Curvature;l4Curvature];

% Curvature goes from 1 to 64
curvature=normalize(curvature)*63+1;
endTime=now;

% TODO , Get this file name from a GUI
statusStringAdd(statusHandle,'Saving:');
statusStringAdd(statusHandle,flatFileName);

messageString=sprintf('Unfold started at %s\nFinished at %s',datestr(startTime),dateStr(endTime));
statusStringAdd(statusHandle,messageString);
if (saveExtra)
	statusString=char(get(statusHandle,'UserData'));
	
	info.perimDist=perimDist;
	
	infoStr.startTime=datestr(startTime);
	infoStr.endTime=datestr(endTime);
	
	infoStr.perimType=truePerimDist;
	infoStr.meshFile=meshFileName;
	infoStr.grayFile=grayFileName;
	
	
	save (flatFileName,'gLocs2d','gLocs3d','curvature','statusString','infoStr','ZI');
else
	save (flatFileName,'gLocs2d','gLocs3d','curvature');
end
statusStringAdd(statusHandle,'Done.');


successFlag=1;


