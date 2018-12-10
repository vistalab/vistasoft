function grayConMat=makeGrayConMat(gNodes,gEdges,busyHandle)
% grayConMat=makeGrayConMat(gNodes,gEdges)
%
% Returns a gray matter connection matrix given the gNodes and
% gEdges extracted from readGrayGraph
% 
% This routine originally part of unfoldMeshFromGUI
%
% AUTHOR: Wade
% Date: 2003/01/07 06:29:06
nGnodes=length(gNodes);

i=zeros(nGnodes*30,1); % no more that 30 connenctions per gNode on average!
j=i;

offset=1;

for t=1:nGnodes % for each gNode...
    
    if ((~mod(t,1000)) & ~isempty(busyHandle))
        updateBusybar(busyHandle,t);
    end
    % Find its edges (the nodes of the things that it's connected to...)
    thisOffset=gNodes(5,t);
    thisNumEdges=gNodes(4,t);
    theseEdges=gEdges(thisOffset:(thisOffset-1+thisNumEdges)); %thisoffset-1 or 0?
    
    % add these to i,j - eventually we'll call sp=sparse(i,j,s,nGnodes,nGnodes)
    % i contains the y coords, j contains the x coords
    endPoint=offset+thisNumEdges-1;
    
    i(offset:endPoint)=ones(1,thisNumEdges)*t;
    j(offset:endPoint)=theseEdges;
    
    offset=endPoint+1;
    
end


i=i(1:offset-1);
j=j(1:offset-1);
s=ones(size(i));
grayConMat=sparse(i,j,s,nGnodes,nGnodes); % Sparse connection matrix for the gray matter nodes.

return;