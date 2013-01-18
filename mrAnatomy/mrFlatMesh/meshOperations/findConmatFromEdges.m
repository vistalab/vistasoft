function sp=findConmatFromEdges(nodeList,edgeList)
% function connectionMatrix=findConmatFromEdges(edgeList)
% Generates a connection matrix from a list of edges
% The returned connection matrix is max(edgeList(:)) square
%
% nodeList is an 8xn array 
% nodes:  8xN array of 
%    Nx(x,y,z,num_edges,edge_offset,layer,dist,pqindex).
% edges:  1xM array of node indices.  The edge_offset of
%    each node points into the starting location of its set
%    of edges.

nNodes=size(nodeList,2);

mxNode=max(edgeList(:));
sp=spalloc(nNodes,nNodes,fix(nNodes/40));

for t=1:nNodes
	
	nEdges=nodeList(4,t);
	offset=nodeList(5,t);
	
	theseNodes=edgeList(offset:(offset+nEdges-1));
	sp(t,theseNodes)=1;
end
	
sp=((sp+sp')~=0); % Matrix is symmetrical


