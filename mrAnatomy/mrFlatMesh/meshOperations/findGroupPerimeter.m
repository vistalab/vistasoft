function [perimeterEdges,eulerCondition]=findGroupPerimeter(mesh,nodeIndices)
% Returns a list of perimeter edges (pairs of indices) and the Euler number of the enclosed mesh. 
%
%  [perimeterEdges,eulerCondition]=findGroupPerimeter(mesh,nodeIndices)
%
% 
% The nodes must be fully connected.
% Works by creating a list of all edges and a list of all faces
% Perimeter is found by looking for edges that are part of only one face
% Edges that are part of >no< faces might exist (do they?)
%
%    mesh:   Mesh structure
%    nodeIndices:  List (1xN) of node indices in the mesh
%
% AUTHOR:  Wade
% DATE : 020107


nVerts=length(mesh.uniqueVertices);

% Now find all the faces contained in this group
faceList=findFacesInGroup(mesh,nodeIndices);

% And find a list of edges ordered so that the lowest node is listed first.
sortedEdgeList=findEdgesInGroup(mesh,nodeIndices);

[numUniqueEdges,dummy]=size(sortedEdgeList);
fprintf('%d edges in this group\n',numUniqueEdges);

if (~isempty(faceList))
   
   % Now convert the list of faces into three sets of (sorted!) edges
   % And convert the x,y coordinates into unique indices 
   
   FaceEdges1=[mesh.uniqueFaceIndexList(faceList,1),mesh.uniqueFaceIndexList(faceList,2)];
   FaceEdges2=[mesh.uniqueFaceIndexList(faceList,1),mesh.uniqueFaceIndexList(faceList,3)];
   FaceEdges3=[mesh.uniqueFaceIndexList(faceList,2),mesh.uniqueFaceIndexList(faceList,3)];
   
   % Sort them so that [a b] and [b a] are seen as the same edge.
   sortedFaceEdges1=sort(FaceEdges1,2);
   sortedFaceEdges2=sort(FaceEdges2,2);
   sortedFaceEdges3=sort(FaceEdges3,2);

   % Make them into unique index numbers to help searching and sorting
   [FaceEdges1]=sub2ind([nVerts,nVerts],sortedFaceEdges1(:,1),sortedFaceEdges1(:,2));
   [FaceEdges2]=sub2ind([nVerts,nVerts],sortedFaceEdges2(:,1),sortedFaceEdges2(:,2));
   [FaceEdges3]=sub2ind([nVerts,nVerts],sortedFaceEdges3(:,1),sortedFaceEdges3(:,2));
   
   % concatenate the list of Face edges into one long list of indices
   FaceEdges=[FaceEdges1,FaceEdges2,FaceEdges3]';
   
   % Sort them - should produce doublets of most edges 'cos most edges are part of two faces
   sortedFaceEdges=sort(FaceEdges(:));
   
   % SortedFaceEdges is a sorted list of all the edges in the face list. If all the edges are
   % members of two faces, it'll just be pairs of numbers.
   % Lone edges (part of only one face) will be on their own here as well.
   % So the list might look like 
   % 1,1,2,2,3,3,4,4,5,5,6,6,7,8,9,9,10,10....
   % Where edge 7 and edge 8 are lone...
   % if n(i)==n(i+1) or n(i)==n(i-1) then n(i) is an internal edge
   
   % So in fact we're looking for cases where the above fails...
  
   diffFromUpper=(sortedFaceEdges-shift(sortedFaceEdges,[1,0]));
   diffFromLower=(sortedFaceEdges-shift(sortedFaceEdges,[-1,0]));
   loneEdges=sortedFaceEdges(find(diffFromUpper.*diffFromLower));
   
   %[a b c]=unique(sortedFaceEdges(:));
   % Just a quick check:
   % 'a' tells you what unique edges there are in the faces. This should be the same as edgeList
   
   % See if we've found any perimeter edges
   
   nFound=length(loneEdges);
   if (nFound>0)
  		
      fprintf('%d perimeter edges\n',nFound);
      [perimeterEdges(:,1),perimeterEdges(:,2)]=ind2sub([nVerts,nVerts],loneEdges);
	  
      perimeterEdges=unique(perimeterEdges,'rows');
	  
      % Take a look at the euler number of this group
      % Euler number derived from 
      % x=F-E+V;
 
      F=length(faceList);
      E=numUniqueEdges;
      V=length(nodeIndices);
      eulerCondition=F-E+V;
      
   else

      %fprintf ('\nNo Perimeter edges found - mesh is closed\n');
      perimeterEdges = [];
      eulerCondition = [];

   end
else
   error ('No faces found in this group - it''s probably a line');
   perimeterEdges=[];
   eulerCondition=NaN;
end

return;









