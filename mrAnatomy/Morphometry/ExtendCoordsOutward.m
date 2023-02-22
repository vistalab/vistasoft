function [eCoords, layers, iV] = ExtendCoordsOutward(view, coords, norm, iV)

% coords = ExtendCoordsOutward(coords);
%
% Extends the input layer-1 coords toward more outward layers, preserving
% the surface area of the initial coords as much as possible.
%
% Ress, 9/05

mrGlobals

vDims = size(view.anat);

nCoords = size(coords, 2);

if ~exist('iV', 'var') | isempty(iV)
  % Build reverse-lookup volume:
  iV = int32(view.anat*0);
  inds = coords2Indices(view.coords, vDims);
  for jj=1:length(inds), iV(inds(jj)) = jj; end
end

% Initialize extension process:
inds = iV(coords2indices(coords, vDims));
maxLayers = max(view.nodes(6, :));
nNeighbors = 1;
layer = 1;
eCoords = coords;
nCoords = size(coords, 2);
layers = ones(1, nCoords);
startCoord = mean(coords, 2);

% Begin extension loop:
while nNeighbors > 0
  layer = layer + 1;
  % Dilate coordinates within gray mesh to find all neighbor coordinates on
  % next outward layer:
  [nc, ni, neighbors] = DilateGrayCoords(view, inds, 1);
  neighLayers = view.nodes(6, neighbors);
  neighbors = neighbors(neighLayers == layer);
  nNeighbors = length(neighbors);
  neighCoords = view.coords(:, neighbors);
  % Find the subset of these neighbors that fall within appropriate angular
  % tolerances:
  angTol = cos(atan(sqrt(nCoords)/(layer-1)));
  initCoords = repmat(startCoord, 1, nNeighbors);
  neighNorms = neighCoords - initCoords;
  neighNorms = neighNorms ./ repmat(sqrt(sum(neighNorms.^2)), 3, 1);
  dotP = sum(neighNorms .* repmat(norm, 1, nNeighbors));
  neighbors = neighbors(dotP >= angTol);
  nNeighbors = length(neighbors);
  if nNeighbors > nCoords
    % If more neighbors on next layer than on previous layer, then select
    % only the closest vertices.
    neighCoords = view.coords(:, neighbors);
    iClosest = nearpoints(coords, neighCoords);
    neighCoords = neighCoords(:, iClosest);
    neighbors = iV(coords2Indices(neighCoords, vDims));
  end
  neighbors = unique(neighbors);
  nNeighbors = length(neighbors);
  layers = [layers, repmat(layer, 1, nNeighbors)];
  coords = view.coords(:, neighbors);
  eCoords = [eCoords, coords];
  inds = neighbors;
end

return