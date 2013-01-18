function [areaList]=findFaceArea(connectionMatrix,uniqueVertices,uniqueFaceIndexList)
%  [areaList,uniqueFaceIndexList]=findFaceArea(mesh)
%
% Takes a mesh with at least:
%   connectionMatrix, vertices, uniqueFaceIndexList
%
% Returns a list of the face areas and the corresponding vertex indices
% It will use the following if they are available:
%   mesh.edgeDists : List of the ordered edge distances
%   mesh.uniqueFaceIndexList - indices into mesh.uniqueVertices. 
%
% Each triplet of indices is a face.
% One idea is to call this twice: once for the 3D mesh, once for its
% unfolded counterpart. The ratio between the face areas gives the error at
% each location. Maybe this could be used as part of an interative
% error-reduction process...?
%
% ARW 040402

% Check for the existance of uniqueVertices.,  .UniqueToVerts, .vertsToUnique

if (nargin~=3), error('Must have exactly 3 arguments'); end

if (~issparse(connectionMatrix)),error('Connection matrix not sparse'); end

% For each row of uniqueFaceIndexlist, we find a,b,c: the lengths of the 3
% edges. The semiperimeter 's' is 1/2(a+b+c) The triangle area is (from
% Heron's formula) sqrt(s(s-a)(s-b)(s-c))

% First, we need to calculate the face side lengths.
% Construct a dummy mesh structure...
mesh.connectionMatrix=connectionMatrix;
mesh.uniqueVertices=uniqueVertices;
dist=sqrt(find3DNeighbourDists(mesh));
% returns dist: an nNodes * nNodes sparse matrix where each entry i,j is
% the distance between node i and its neighbour node j

conMatSize=size(dist);

% Generate a,b,c vectors (edgeLengths)
nFaces=length(uniqueFaceIndexList);
edgeLengths=zeros(nFaces,3); % Each face has 3 edges

edgePairs=[1,2;1,3;2,3];

for thisEdge=1:3
    
    i1=uniqueFaceIndexList(:,edgePairs(thisEdge,1));
    i2=uniqueFaceIndexList(:,edgePairs(thisEdge,2));
    
    % Turn these into linear indices
    ind=sub2ind(conMatSize,i1,i2);
    
    edgeLengths(:,thisEdge)=dist(ind);
end

% Calculate the semi-perimeters
s=0.5*sum(edgeLengths,2);

areaList=sqrt(s.*prod((repmat(s,1,3)-edgeLengths),2));

% this happens sometimes when matlab rounds things off.
areaList = real(areaList);

return;
