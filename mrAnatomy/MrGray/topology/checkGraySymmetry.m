function nMissed = checkGraySymmetry(nodes,edges)
% 
% AUTHOR:  Wandell
% DATE:  04.26.97
% PURPOSE:
%   Pairs of nodes should be symmetrically connected.  This
% routine is an auxiliary written to test removeNodes code.
% Perhaps it will be useful for other tests.
% 
% REVISIONS:
% 10.13.97 SC Modified to run on Matlab 5.0
%

numNodes = size(nodes,2);
numEdges = nodes(4,:);
offsets = nodes(5,:);

% This will be a count of the number of asymmetric nodes
% 
nMissed = 0; 

% For each gray node, ii, find the edges to other nodes
% 
for ii = 1:numNodes
  l = offsets(ii) + [0:(numEdges(ii)-1) ];
  connectedTo = edges(l);

  % For each node, jj, connected to ii, make sure that this node
  % shows a connection back to ii
  % 
  for jj = connectedTo
    l = offsets(jj) + [0:(numEdges(jj)-1)];
    test = find(ii == edges(l));

    % If test is null, then ii is not in this list and we have a
    % problem. 
    if isempty(test)
      fprintf('\n\nMissing connection\n\n');
      fprintf('Problem nodes are %d and %d\n',ii, jj);
      nMissed = nMissed + 1;
    end

  end
end

if nMissed == 0
  fprintf('Graph appears symmetric.\n');
end

return;
