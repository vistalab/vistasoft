function result = sumOfNeighbors(input,edges,edgeOffsets,numNeighbors)

numNodes = length(input);
result = zeros(size(input));
for n = 1:numNodes
   for e = [edgeOffsets(n):edgeOffsets(n)+numNeighbors(n)-1]
      result(n) = result(n) + input(edges(e));  
   end
end

% ras 03/2007:
% let's make this agree with sumOfNeighbors.mex: it outputs a
% transverse:
result = result';

return
