function conMat= buildConnectionMatrix(nodes, edges)
% 
% USAGE: conMat= buildConnectionMatrix(nodes, edges)
%   
% AUTHOR:  Dougherty
% DATE:    2001.11.06
% PURPOSE:
%   Builds a sparse connection matrix given mrGray-format nodes and edges.
% 
% HISTORY
%
origNumNodes = size(nodes,2);

% We are trying to do the following simple loop:
%for t=1:numNodes
% 	% Find its edges (the nodes of the things that it's connected to...)
% 	thisOffset=nodes(5,t);
% 	thisNumEdges=nodes(4,t);
% 	theseEdges=edges(thisOffset:(thisOffset-1+thisNumEdges));
% 	
% 	% add these to i,j - eventually we'll call sp=sparse(i,j,s,numNodes,numNodes)
% 	% i contains the y coords, j contains the x coords
% 	endPoint=offset+thisNumEdges-1;
% 	
% 	i(offset:endPoint)=ones(1,thisNumEdges)*t;
% 	j(offset:endPoint)=theseEdges;
% 	
% 	offset=endPoint+1;
% end

nodeIndices = [1:origNumNodes];
i = zeros(length(edges),1);
j = i;
first = 1;
nIter = max(nodes(4,:));
for ii=1:nIter
    numNodes = size(nodes,2);
    last = first+numNodes-1;
    i(first:last) = nodeIndices;
    j(first:last) = edges(nodes(5,:)+(ii-1));
    keep = nodes(4,:)>ii;
    nodes = nodes(:,keep);
    nodeIndices = nodeIndices(keep);
    first = last+1;
end

[i,index] = sort(i);
j = j(index);
s=ones(size(i));
conMat = sparse(i,j,s,origNumNodes,origNumNodes);

return;