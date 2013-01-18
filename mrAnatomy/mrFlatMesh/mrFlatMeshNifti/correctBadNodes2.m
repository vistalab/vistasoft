function [insideNodes] = correctBadNodes2(mesh,insideNodes,badNodes)
%
% Bad nodes lie on a perimeter of a set of inside nodes. They are bad
% because they connect to more than two other perimeter nodes. Solution is
% to grow out from these points and add their neighbours to the list of
% inside nodes, then recalculate the perimeter
%
% OK - but this routine doesn't do any of that.  Maybe we can get rid of
% it. (BW)
%
% ARW - Last edited 032201

% l = length(insideNodes(:));
[badNodeIndex,badNodeNeighbours] = find(mesh.connectionMatrix(badNodes,:));

insideNodes = [insideNodes(:);badNodeNeighbours(:)];
insideNodes = unique(insideNodes(:));

return;
