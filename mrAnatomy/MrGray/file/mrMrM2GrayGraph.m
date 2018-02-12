function [uniqueSparse, grayGraph] = mrMrM2GrayGraph(filename)
% 
% [uniqueSparse, grayGraph] = mrMrM2GrayGraph(filename)
%
% AUTHOR:  Maher Khoury 
% DATE:    08.19.99
% PURPOSE:
% 		Reads in Vertices (strips and triangles) from an .MrM file and returns corresponding edges
%	A strip is an OpenGL construct where the first three nodes defines triangle, the next one,
%	along with the previous two nodes, etc...
% 
% INPUT:
%	filename is a .MrM file 
%   
% SEE ALSO:  MrReadMrM
%
% Notes: 

%% Read in .MrM file
%
mesh = mrReadMrM(filename);

%% Rounding
%
vertices = round(mesh.vertices);

%% Get number of nodes
%
numNodes = size(vertices,1);

%% Initialize nodeConnection sparse matrix
%
nodeConnections = sparse(numNodes,numNodes);

%% Build unique list
%
[uniqueNodes, nodeIdx, uniqueIdx] = unique(vertices,'rows');

%% Fill the sparse matrix with stripList
%
h = mrvWaitbar(0,'Reading Edges from Stripped List');
for k=1:size(mesh.stripList,1),
   vertex = mesh.stripList(k,1)+3;
   nodeConnections(vertex,vertex-1)=1; 
   nodeConnections(vertex,vertex-2)=1; 
   nodeConnections(vertex-2,vertex-1)=1;
   nodeConnections(vertex-1,vertex)=1; 
   nodeConnections(vertex-2,vertex)=1; 
   nodeConnections(vertex-1,vertex-2)=1;
   
   while vertex < mesh.stripList(k,1)+mesh.stripList(k,2),
      vertex = vertex + 1;       
      nodeConnections(vertex,vertex-1)=1;
      nodeConnections(vertex,vertex-2)=1; 
      nodeConnections(vertex-1,vertex)=1; 
      nodeConnections(vertex-2,vertex)=1;
      
      mrvWaitbar(vertex/(mesh.triangleOffset-1),h);   
   end
end

close(h);

%% Check statement
%
if ~((vertex+1)==mesh.triangleOffset)
   disp('Problem !!');
   return;
end

ptr = mesh.triangleOffset;

%% Fill the sparse matrix with triangle
%
h = mrvWaitbar(0,'Reading Edges from Triangles');
while ptr<size(mesh.vertices,1),
   nodeConnections(ptr,ptr+1)=1;nodeConnections(ptr,ptr+2)=1;nodeConnections(ptr+1,ptr+2)=1;
   nodeConnections(ptr+1,ptr)=1;nodeConnections(ptr+2,ptr)=1;nodeConnections(ptr+2,ptr+1)=1;
   ptr = ptr+3;   
   mrvWaitbar(ptr/numNodes,h);   
end
close(h);


%% So now we have an unconnected set of strips and triangles in the nodeConnections structure
%  We go through the unique list, find all the strips and triangles the nodes in that list
%  belong to and we merge them.  We then copy the new connection lines back in the structure

h = mrvWaitbar(0,'Finishing connections...');
for k=1:length(uniqueNodes),
   % For a particular unique node, find the indices in nodeConnections of all similar nodes
   sameNodes = find(uniqueIdx==k);   
   mergedNodes = sum(nodeConnections(sameNodes,:),1);
   nodeConnections(sameNodes,:) = or(nodeConnections(sameNodes,:),...
      repmat(mergedNodes,size(nodeConnections(sameNodes,:),1),1)); 
   nodeConnections(:,sameNodes') = or(nodeConnections(:,sameNodes'),...
      nodeConnections(sameNodes,:)');
   mrvWaitbar(k/length(nodeIdx),h);   
end
close(h);


%% Compacting the matrix
uniqueSparse = nodeConnections(sort(nodeIdx),sort(nodeIdx)');


%%%%%%%%%%%%%%%%%%%%%%%%

if nargout == 1,
   return;
else   
   
   %% Compute nodes and edges
 
   % +1's to do the C to Matlab conversion
   % writeGrayGraph will remove these
   
   % NEW numNodes
   numNodes = size(uniqueSparse,1);
   
   nodes = zeros(8,numNodes);
   nodes(1,:) = uniqueNodes(:,1)'+1;
   nodes(2,:) = uniqueNodes(:,2)'+1;
   nodes(3,:) = uniqueNodes(:,3)'+1;
   nodes(4,:) = full(sum(uniqueSparse,2))';
   nodes(5,:) = [0 cumsum(nodes(4,1:(numNodes-1)))] +1;
   nodes(6,:) = ones(1,numNodes);
   %% 7,8 are junk.  No need to fill them.
   
   % The column numbers should have C numbering from 0 to N-1
   % in order to be consistent with mrGray.  Matlab returns ordering
   % from 1 to N so we subtract 1.
   % This code efficiently finds the connections for all nodes all at once.
   % Explain the mod operation.
   edges = mod((find(uniqueSparse)-1),numNodes)+1; 
   
   grayGraph.nodes = nodes;
   grayGraph.edges = edges';
   grayGraph.dimdist = mesh.parameters.structural.voxSize;
   
end
