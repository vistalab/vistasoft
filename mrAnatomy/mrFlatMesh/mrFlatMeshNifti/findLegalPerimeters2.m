function [perimeterEdges,eulerCondition] = findLegalPerimeters2(mesh,perimDist)
% Calculate edges that on distinct perimeters perimDist mm from startVertex
% 
%  [perimeterEdges,eulerCondition] = findLegalPerimeters2(mesh,perimDist)
%
% Given a mesh structure (nodes, edges, distances from start point) and a
% threshold distance return a list of edges that constitute separate
% perimeters at a distance of perimDist from the start point.
%
% Note that because of intrinsic curvature, there can be more than one
% perimeter at the required distance. This routine makes sure that it
% returns separate perimeters (ones with no common nodes).
%

% Find perims with simple threshold
insideNodes = find(mesh.dist<=perimDist);
insideNodes = insideNodes(:);  

% Some triangles have one or two vertices outside the perimeter.  These
% triangles will not be included; any nodes that are within the perimeter
% but only part of these excluded triangles are removed here.
insideNodes = removeHangingNodes2(mesh,insideNodes); 

% We could write a short piece of code that verifies these new nodes have
% no hanging nodes ...

numBadNodes = 1; 

while (numBadNodes>0)
    
    [perimeterEdges,eulerCondition] = findGroupPerimeter2(mesh,insideNodes);

    length(perimeterEdges);
    length(unique(perimeterEdges,'rows'));
    fprintf('Euler number=%d\n',eulerCondition);

    badPerimNodes = findBadPerimNodes2(mesh,perimeterEdges);
    numBadNodes   = length(badPerimNodes);
    fprintf('There are %d bad perim nodes.\n',numBadNodes);

    if(numBadNodes)
        % Splits up joined perimeters
        [insideNodes] = correctBadNodes2(mesh,insideNodes,badPerimNodes);
        
        % Cleans up mesh again
        insideNodes = removeHangingNodes2(mesh,insideNodes);
    end
end

return;

