function [perimeterEdges,eulerCondition] = findLegalPerimeters2(mesh,perimDist)
% 
%  [perimeterEdges,eulerCondition] = findLegalPerimeters2(mesh,perimDist)
% 
% Given a mesh structure (nodes, edges, distances from start point) and a
% threshold distance this routine will return a list of edges that
% constitute separate perimeters at a distance of perimDist from the start
% point.
%
% Note that because of intrinsic curvature, there can be more than one
% perimeter at the required distance. This routine makes sure that it
% returns separate perimeters (ones with no common nodes).

% Find perims with simple thold
insideNodes=find(mesh.dist<=perimDist);
insideNodes=insideNodes(:);

insideNodes = removeHangingNodes(mesh,insideNodes); % Cleans up the mesh
[perimeterEdges,eulerCondition]=findGroupPerimeter(mesh,insideNodes); % Find perimeter(s) - there may be more than 1
badPerimNodes = findBadPerimNodes(mesh,perimeterEdges); % See if some perimeters are joined up.

numBadNodes=9999999; % Hope we don't get more than this...

while (numBadNodes>0)
    [perimeterEdges,eulerCondition]=findGroupPerimeter(mesh,insideNodes);
	length(perimeterEdges);
	length(unique(perimeterEdges,'rows'));
    fprintf('Euler number=%d\n',eulerCondition);
    
    badPerimNodes=findBadPerimNodes(mesh,perimeterEdges);
    numBadNodes=length(badPerimNodes);
    fprintf('There are %d bad perim nodes.\n',numBadNodes);
	
    if(numBadNodes)
		[insideNodes]=correctBadNodes(mesh,insideNodes,badPerimNodes); % Splits up joined perimeters
		insideNodes=removeHangingNodes(mesh,insideNodes); % Cleans up mesh again
    end
end

return;

