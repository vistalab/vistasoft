function mappedIndices=findNearestConnected(nodeList, upperIndices,lowerIndices,connectionMatrix)
% function mappedIndices=findNearestConnected(nodeList, upperIndices,lowerIndices,connectionMatrix)
% For each node in the upper layer, find its nearest >connected< neighbour 
% in the layer beneath. 
% Inputs: nodeList (nPoints*3) : 3D coordinates of all the nodes 
%       : upperIndices (nUpper*1) : Indices of the upper nodes in nodeList
%       : lowerIndices (nLower*1) : Indices of the lower nodes in nodeList
%       : connectionMatrix (nPoints*nPoints, sparse) : ==1 when nodes(x,y) are connected
% ARW 020101 : Wrote it


% Restrict the connection matrix
connectionMatrix=connectionMatrix(lowerIndices,upperIndices);

% Get the coords of the upper and lower nodes
upperCoords=nodeList(upperIndices,1:3);
lowerCoords=nodeList(lowerIndices,1:3);

% How many nodes in each layer?
nUpperNodes=length(upperIndices);
nLowerNodes=length(lowerIndices);

mappedIndices=zeros(nUpperNodes,1);

% For each member of upperNodes
for thisNode=1:nUpperNodes

    connectedIndices=find(connectionMatrix(:,thisNode));
    currentUpperCoords=upperCoords(thisNode,:);
    connectedCoords=lowerCoords(connectedIndices,:);

    % This returns the index of the nearest connected node within the list.
    if(~isempty(connectedIndices))
        if(length(connectedIndices)==1)
            nearestNode=1;
        else
            % Call assignToNearest to find which of the few connected lower nodes the upper point is
            % closest to.
            nearestNode=nearpoints(currentUpperCoords',connectedCoords');
        end
        % convert this to an index for the entire l1Gnodes
        mappedIndices(thisNode)=connectedIndices(nearestNode);
    end

end






