function [newCoords, newIndices, neighbors, view] = DilateGrayCoords(view, indices, iterations)

% [newCoords, newIndices, view] = DilateGrayROI(view, indices, iterations);
%
% Dilate the input gray coordinates along the gray graph for the specified
% number of iterations. This function assumes that the gray connection
% (sparse) matrix has been precalculated and attached to the current VOLUME
% view structure as field grayConMat. If not, this matrix is calculated and
% attached for later use.
%
% Ress, 0805 Mostly borrowed from mrv_DilateGrayROI

mrGlobals

if ~isfield(view, 'grayConMat')
  disp('Calculating gray connection graph...');
  view.grayConMat = makeGrayConMat(view.nodes, view.edges, 0);
end

newIndices = indices;

% Dilation loop:
neighbors = [];
for thisIteration=1:iterations
  [neighborInds, dum] = find(view.grayConMat(:, newIndices));
  neighbors = [neighbors, neighborInds'];
  newIndices = [newIndices, neighborInds'];
end

newIndices = unique(newIndices);
newCoords = view.coords(:, newIndices);

return;