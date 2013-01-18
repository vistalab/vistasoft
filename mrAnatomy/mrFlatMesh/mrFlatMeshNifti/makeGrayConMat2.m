function grayConMat = makeGrayConMat2(gNodes,gEdges)
% Returns a gray matter connection matrix
%
%   grayConMat=makeGrayConMat2(gNodes,gEdges)
%
% The gNodes and gEdges can be read by readGrayGraph or created using
% mrgGrowGray
%
% AUTHOR: Wade
% Date: 2003/01/07 06:29:06

nGnodes=length(gNodes);

% no more that 30 connenctions per gNode on average!
i=zeros(nGnodes*30,1); 
j=i;

offset=1;

% for each gNode...
for t=1:nGnodes 
    
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


i = i(1:offset-1);
j = j(1:offset-1);
s = ones(size(i));

% Sparse connection matrix for the gray matter nodes.
grayConMat = sparse(i,j,s,nGnodes,nGnodes); 

return;