function [insideNodes]=correctBadNodes(mesh,insideNodes,badNodes)
% function [insideNodes]=correctBadNodes(mesh,perimeterEdges,badNodes)
% Bad nodes lie on a perimeter of a set of inside nodes. They are bad because 
% they connect to more than two other perimeter nodes.
% Solution is to grow out from these points and add their neighbours to the list of inside nodes, then
% recalculate the perimeter
% ARW - Last edited 032201
l=length(insideNodes(:));
%fprintf('\n****** Entered routine with %d inside nodes and %d bad nodes',l,length(badNodes));
%disp ('****************************')
[badNodeIndex,badNodeNeighbours]=find(mesh.connectionMatrix(badNodes,:));
%[nab2Index,nab2nabs]=find(mesh.connectionMatrix(badNodeNeighbours,:));

%fprintf('\nThese are the bad nodes:%d',badNodes);
%fprintf('\nThey are connected to these nodes:%d',badNodeNeighbours);

insideNodes=[insideNodes(:);badNodeNeighbours(:)];
insideNodes=unique(insideNodes(:));
nAdded=length(insideNodes)-l;
%fprintf('\n%d nodes addded to the mesh.',nAdded);
