function [perimeterEdges,eulerCharacteristic] = findGroupPerimeter2(mesh,nodeIndices)
% Returns a list of perimeter edges (pairs of indices)
%
%  [perimeterEdges,eulerCharacteristic] = findGroupPerimeter2(mesh,nodeIndices)
%
% The nodes must be fully connected.
%
% Works by creating a list of all edges and a list of all faces
% Perimeter is found by looking for edges that are part of only one face
% Edges that are part of >no< faces might exist if, say, we climb a hill.
% We check this elsewhere, I think???
%
%    mesh:   Mesh structure
%    nodeIndices:  List (1xN) of node indices in the mesh
%
% The Euler characteristic of the enclosed mesh can also be returned.
% Discussion on Euler characteristic see:
%   http://en.wikipedia.org/wiki/Planar_graph
%
% A fully connected planar graph with no edge intersections has an Euler
% characteristic of 2.
%
% AUTHOR:  Wade
% DATE : 020107

nVerts=meshGet(mesh,'nVertices');

% Now find all the faces contained in this set of nodes
faceList = findFacesInGroup2(mesh,nodeIndices);

% And find a list of edges ordered so that the lowest node is listed first.
sortedEdgeList = findEdgesInGroup2(mesh,nodeIndices);

[numUniqueEdges,dummy] = size(sortedEdgeList); %#ok<NASGU>
fprintf('%d edges in this group\n',numUniqueEdges);

if (~isempty(faceList))

    % Now convert the list of faces into three sets of (sorted!) edges
    % And convert the x,y coordinates into unique indices

    % This should be nTriangles x 2.  Each triangle has three face edges.
    % We find them here.  They are represented as pairs of indices into the
    % vertex list.
    FaceEdges1=[mesh.triangles(1,faceList);mesh.triangles(2,faceList)]' + 1;
    FaceEdges2=[mesh.triangles(1,faceList);mesh.triangles(3,faceList)]' + 1;
    FaceEdges3=[mesh.triangles(2,faceList);mesh.triangles(3,faceList)]' + 1;

    % Sort them so that [a b] and [b a] are seen as the same edge.
    sortedFaceEdges1 = sort(FaceEdges1,2);
    sortedFaceEdges2 = sort(FaceEdges2,2);
    sortedFaceEdges3 = sort(FaceEdges3,2);

    % We want to assign each edge a unique index.
    % We do this by
    %  (a) Make them into unique index numbers to help searching and sorting
    %  (b) Concatenating all of the edges
    %
    FaceEdges1 =sub2ind([nVerts,nVerts],sortedFaceEdges1(:,1),sortedFaceEdges1(:,2));
    FaceEdges2 =sub2ind([nVerts,nVerts],sortedFaceEdges2(:,1),sortedFaceEdges2(:,2));
    FaceEdges3 =sub2ind([nVerts,nVerts],sortedFaceEdges3(:,1),sortedFaceEdges3(:,2));

    % Concatenate the edge indices into one long list
    FaceEdges=[FaceEdges1,FaceEdges2,FaceEdges3]';

    % Sort them - should produce doublets of most edges 'cos most edges are
    % part of two faces
    sortedFaceEdges=sort(FaceEdges(:));

    % SortedFaceEdges is a sorted list of all the edges in the face list. If
    % all the edges are members of two faces, it'll just be pairs of
    % numbers. Lone edges (part of only one face) will be on their own here
    % as well.
    % So the list might look like
    % 1,1,2,2,3,3,4,4,5,5,6,6,7,8,9,9,10,10....
    % Where edge 7 and edge 8 are lone...
    % if n(i)==n(i+1) or n(i)==n(i-1) then n(i) is an internal edge

    % So we're looking for cases where the pseudo-code above fails...
    % We want to find the values that differ from the entries prior and
    % following.
    diffFromUpper = (sortedFaceEdges - shift(sortedFaceEdges,[1,0]));
    diffFromLower = (sortedFaceEdges - shift(sortedFaceEdges,[-1,0]));
    loneEdges     = sortedFaceEdges(find(diffFromUpper.*diffFromLower));

    %[a b c]=unique(sortedFaceEdges(:));
    % Just a quick check: 'a' tells you what unique edges there are in the
    % faces. This should be the same as edgeList

    % See if we've found any perimeter edges

    % Lone edges have a face on one side of the edge, but not on the other.
    % Some of these are perimeter edges that we want to find.  Others are
    % lone edges that are not on the perimeter we are interested in.
    % Instead they are up on a hill that is the right distance from the
    % start point, but they are not really on the main outside perimeter.
    % We find all the perimeter groups (connected lone edges) and we pick
    % the largest group as the true perimeter.
    nFound=length(loneEdges);
    if (nFound>0)

        %
        fprintf('%d perimeter edges\n',nFound);
        [perimeterEdges(:,1),perimeterEdges(:,2)]=ind2sub([nVerts,nVerts],loneEdges);
        perimeterEdges = unique(perimeterEdges,'rows');

        % Take a look at the Euler number of this group
        % Euler number derived from
        % x=F-E+V;
        % The Euler number

        % To compute the Euler number we just find the number of triangles
        % (F) and the number of unique edges (E) and the number of nodes (V).
        %  The Euler number is F - E + V.  When the mesh has no handles the
        %  Euler characteristic is XX.
        F = length(faceList);
        E = numUniqueEdges;
        V = length(nodeIndices);
        eulerCharacteristic = F - E + V;

    else
        %fprintf ('\nNo Perimeter edges found - mesh is closed\n');
        perimeterEdges      = [];
        eulerCharacteristic = [];
    end
else
    error ('No faces found in this group - it''s probably a line');
end

return



