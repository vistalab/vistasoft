function grayConMat=dhkGrayConMat(gNodes, gEdges, coords, sigma, mask)
% dhkGrayConMat - returns a weighted gray matter connection matrix
%
%  grayConMat = dhkGrayConMat(gNodes, gEdges, coords, sigma, mask)
%
% This function creates a normalized truncated Gaussian function along the
% gray matter connection matrix. The size of the Gaussian is determined by
% sigma. The Gaussian is only made on the edges, directly connecting
% voxels, hence it is truncated. It is normalized so the total weight is 1.
% 
% 2008/03 SOD: modified from makeGrayConMat

if ~exist('gNodes','var') || isempty(gNodes), error('Need gray nodes'); end
if ~exist('gEdges','var') || isempty(gEdges), error('Need gray edges'); end
if ~exist('coords','var') || isempty(coords), error('Need gray coords'); end
if ~exist('sigma','var') || isempty(sigma), sigma = 0.5; end
if ~exist('mask','var') || isempty(mask), 
    selectVoxels=false; 
else
    selectVoxels = true;
    mask = logical(mask);
end

% we need -2*sigma.^2
denom = -2.*sigma.^2;

nGnodes=length(gNodes);

i=zeros(nGnodes*30,1); % no more that 30 connenctions per gNode on average!
j=i; s=i;

offset=1;

for t=1:nGnodes % for each gNode...
    % Find its edges (the nodes of the things that it's connected to...)
    thisOffset=gNodes(5,t);
    thisNumEdges=gNodes(4,t);
    theseEdges=gEdges(thisOffset:(thisOffset-1+thisNumEdges)); %thisoffset-1 or 0?
    
    if selectVoxels
       theseEdges = theseEdges(mask(theseEdges));
       thisNumEdges = numel(theseEdges);
    end
    
    % add these to i,j - eventually we'll call sp=sparse(i,j,s,nGnodes,nGnodes)
    % i contains the y coords, j contains the x coords
    endPoint=offset+thisNumEdges; % not -1 because we include the node itself
    
    i(offset:endPoint)=ones(1,thisNumEdges+1)*t;
    j(offset:endPoint)=[t theseEdges];
    
    % compute weight
    tmpc = coords(:,[t theseEdges]);  
    tmpc = tmpc - (coords(:,t)*ones(1,size(tmpc,2)));
    tmpc = sum(tmpc.^2);    % distance
    tmpc = exp(tmpc./denom); % gaussian weight
    tmpc = tmpc./sum(tmpc); % normalize to 1
    s(offset:endPoint) = tmpc;
    
    offset=endPoint+1;
end


i=i(1:offset-1);
j=j(1:offset-1);
s=s(1:offset-1);

% Sparse connection matrix for the gray matter nodes.
grayConMat=sparse(i,j,s,nGnodes,nGnodes)'; 
return


