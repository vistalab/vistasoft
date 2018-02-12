function [uniqueSparse, grayGraph] = Mesh2Connections(mesh)
% 
%  [uniqueSparse,grayGraph] = Mesh2Connections(mesh)
%
% AUTHOR:  Maher Khoury 
% DATE:    08.19.99
% PURPOSE:
%  Takes in a Mesh structure and computes a connections matrix.
% 
%  The Mesh structure has data in a striplist and triangles.
%  These are OpenGL constructs.  A striplist is organized so that 
%  the first three nodes defines triangle, the 2-4 define another 
%  triangle, 3-5, and so forth.
%  
% 
% INPUT:
%   Mesh
%   
% SEE ALSO:  MrReadMrM to understand more about the Mesh structure.
%
% 09.03.99  BW.
%    Rounding the mesh early caused problems.  So, I leave the
%    vertices as floats.  The rounding only happens now when the
%    data are converted to nodes in Connections2Graph.
%    

%    vertices = round(mesh.vertices); -- MK rounded.  Why?  I
%    removed this rounding from here.
%  There is also an issue of when the vertices should have 1
% added to them.  This should probably happen in Connections2Graph?
%    
vertices = mesh.vertices;

%% Get number of nodes
%
numNodes = size(vertices,1);

%% Initialize nodeConnection sparse matrix
%
nodeConnections = sparse(numNodes,numNodes);

%% Build unique list.  nodeIdx maps the unique node entries back
%  to the redundant node list.  uniqueIdx are the nodes in
%  vertices that are instances of unique node.
%    uniqueVertices = vertices(nodeIdx)
%    vertices    = uniqueVertices(uniqueIdx)
%    
[uniqueVertices, nodeIdx, uniqueIdx] = unique(vertices,'rows');

%% Fill the sparse matrix with stripList
%
h = mrvWaitbar(0,'Reading Edges from Stripped List');
for k=1:size(mesh.stripList,1),
  % Start at the 3rd vertex on the list, and build your triangles 
  % looking backwards.
  % 
   vertex = mesh.stripList(k,1)+3;
   nodeConnections(vertex,vertex-1)=1; 
   nodeConnections(vertex,vertex-2)=1; 
   nodeConnections(vertex-2,vertex-1)=1;
   nodeConnections(vertex-1,vertex)=1; 
   nodeConnections(vertex-2,vertex)=1; 
   nodeConnections(vertex-1,vertex-2)=1;
   
   % Go on to the next vertex if you are between the current one
   % and the next strip list location.
   % 
   while vertex < mesh.stripList(k,1)+mesh.stripList(k,2),
      vertex = vertex + 1;       
      nodeConnections(vertex,vertex-1)=1;
      nodeConnections(vertex,vertex-2)=1; 
      nodeConnections(vertex-1,vertex)=1; 
      nodeConnections(vertex-2,vertex)=1;
      
      if ~mod(vertex,100)
	mrvWaitbar(vertex/(mesh.triangleOffset-1));   
      end
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
while ptr<size(vertices,1),
   nodeConnections(ptr,ptr+1)=1;nodeConnections(ptr,ptr+2)=1;nodeConnections(ptr+1,ptr+2)=1;
   nodeConnections(ptr+1,ptr)=1;nodeConnections(ptr+2,ptr)=1;nodeConnections(ptr+2,ptr+1)=1;
   ptr = ptr+3;   
   if ~mod(ptr,100)
     mrvWaitbar(ptr/numNodes);   
   end
end
close(h);

%% So now we have an unconnected set of strips and triangles in the nodeConnections structure
%  We go through the unique list, find all the strips and triangles the nodes in that list
%  belong to and we merge them.  We then copy the new connection lines back in the structure

%    BW.  Nothing is connected to itself up to here.  But,
%    something in here causes same nodes to be connected to
%    themselves.  Let's clear up this logic and see why.
%    
tmp = nodeConnections;
h = mrvWaitbar(0,'Removing redundant vertices from connections...');
for k=1:length(uniqueVertices),

  % For each unique node, find rows of nodeConnections 
  % that are really the same and refer to that unique node.
  % 
  sameNodes = find(uniqueIdx==k)  ;

  % Now, we are going to collapse the larger matrix by copying
  % all of the entries from all of the same nodes into each other.
  % I think this can produce some diagonal entries. -- BW

  % This sums the nodeConnections along the first (row) dimension
  % 
  mergedNodes = sum(nodeConnections(sameNodes,:),1);

  % repmat belows up the mergedNodes to the same size or
  % nodeConnections(sameNodes,:)  
  % The two are or'd together to make the entries all 0s and 1s
  % 
  nodeConnections(sameNodes,:) = or(nodeConnections(sameNodes,:),...
      repmat(mergedNodes,size(nodeConnections(sameNodes,:),1),1)) ;

  % And then this is done again but for the corresponding columns
  % 
  nodeConnections(:,sameNodes') = or(nodeConnections(:,sameNodes'),...
      nodeConnections(sameNodes,:)');

  % 
  if ~mod(k,100)
    mrvWaitbar(k/length(nodeIdx));   
  end
end
close(h);

%% Compacting the connections matrix
%
uniqueSparse = nodeConnections(sort(nodeIdx),sort(nodeIdx)');


% Did the user want a gray graph, too?
% 
if nargout == 1,
   return;
elseif nargout == 2   
  [grayGraph.nodes, grayGraph.edges] = Connections2Graph(uniqueSparse,uniqueVertices);
  grayGraph.dimdist = mesh.parameters.structural.voxSize;
else
  error('Mesh2Connections:  Wrong number of output arguments.');
end
