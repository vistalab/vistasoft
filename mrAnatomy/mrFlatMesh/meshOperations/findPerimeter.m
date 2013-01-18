function perimeterEdges=findPerimeter(mesh)
% function perimeterPoints=findPerimeter(mesh,faceIndexList)
% Finds perimeter points.
% Works by looking at the connection matrix (which is a list of edges)
% The perimeter points are those points that are on edges that are used by only one face

%nVerts=length(mesh.uniqueVertices);

% Create a list of edges...
[edgeList1,edgeList2]=find(triu(mesh.connectionMatrix));

edgeList=[edgeList1,edgeList2];

disp ('Number of edges found:');
numUniqueEdges=length(edgeList);

disp (length(edgeList));

sortedEdgeList=sort(edgeList')';
sortedEdgeList=sub2ind([numUniqueEdges,numUniqueEdges],sortedEdgeList(:,1),sortedEdgeList(:,2));

% Now convert the list of faces into three sets of (sorted!) edges
% And convert the x,y coordinates into unique indices 
FaceEdges1=[mesh.uniqueFaceIndexList(:,1),mesh.uniqueFaceIndexList(:,2)];
FaceEdges2=[mesh.uniqueFaceIndexList(:,1),mesh.uniqueFaceIndexList(:,3)];
FaceEdges3=[mesh.uniqueFaceIndexList(:,2),mesh.uniqueFaceIndexList(:,3)];

% Sort them so that [a b] and [b a] are seen as the same edge.
sortedFaceEdges1=sort(FaceEdges1')';
sortedFaceEdges2=sort(FaceEdges2')';
sortedFaceEdges3=sort(FaceEdges3')';

% Make them into unique index numbers to help searching and sorting
[FaceEdges1]=sub2ind([numUniqueEdges,numUniqueEdges],sortedFaceEdges1(:,1),sortedFaceEdges1(:,2));
[FaceEdges2]=sub2ind([numUniqueEdges,numUniqueEdges],sortedFaceEdges2(:,1),sortedFaceEdges2(:,2));
[FaceEdges3]=sub2ind([numUniqueEdges,numUniqueEdges],sortedFaceEdges3(:,1),sortedFaceEdges3(:,2));

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
diffFromUpper=sortedFaceEdges-shift(sortedFaceEdges,[1,0]);
diffFromLower=sortedFaceEdges-shift(sortedFaceEdges,[-1,0]);
loneEdges=sortedFaceEdges(find(diffFromUpper.*diffFromLower));

[a b c]=unique(sortedFaceEdges(:));
% Just a quick check:
% 'a' tells you what unique edges there are in the faces. This should be the same as edgeList

nFound=length(loneEdges);
if (nFound>0)
   disp(nFound);
   disp ('Perimeter edges found');
   
% In the test cases, the mesh is closed so there's no perimeter, loneEdges should be empty
% But let's pretend we've found some...
[perimeterEdges(:,1),perimeterEdges(:,2)]=ind2sub([numUniqueEdges,numUniqueEdges],loneEdges);
else
   disp ('No Perimeter edges found - mesh is closed');
   perimeterEdges=[];
end
