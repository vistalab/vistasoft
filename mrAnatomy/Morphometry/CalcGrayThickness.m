function [thickness, maxThick] = CalcGrayThickness(coneRadius);

% thickness = CalcGrayThickness(coneWidth);
%
% Calculate the thickness of the gray matter using mrGray nodes. Uses a
% search-cone and nearest-neighbor approach to associate voxels from layer
% 1 with ascending layers. The highest layer node that lies within the
% search cone is defined as the thickness at that node. This
% produces a voxel-wise integer measurement of the thickness that is 
% returned as a vector.
%
% Ress, 08/05

mrGlobals

% Find anatomy path:
if exist(vANATOMYPATH)
  vPath = fileparts(vANATOMYPATH);
else
  vPath = uigetdir;
end
if vPath(1) == 0, return, end

if ~exist('coneWidth', 'var'), coneRadius = 1/sqrt(2); end

% Calculate gray graph for all nodes
waitH = mrvWaitbar(0, 'Getting gray graph...');
view = initHiddenGray;
view = loadAnat(view);
view.nodes = [view.allLeftNodes, view.allRightNodes];
view.edges = [view.allLeftEdges, view.allRightEdges];
view.coords = view.nodes([2 1 3], :);
view.grayConMat = makeGrayConMat(view.nodes, view.edges, 0);
layers = view.nodes(6, :);
nLayers = max(layers);

% Determine bounding box for gray matter:
bBox = zeros(3, 2);
for ii=1:3
  bBox(ii, 1) = min(view.coords(ii, :)');
  bBox(ii, 2) = max(view.coords(ii, :)');
end

mrvWaitbar(0, waitH, 'Build classification volume...')
% Create volume containing white-matter voxels set to 1, gray-matter voxels
% set to -1:
anat = double(permute(BuildWhiteVolume, [2 1 3]));
vDims = size(anat);
anat(anat == 0) = -1; % Set non-white matter to -1

% To reduce computations, restrict volume to bounding-box dimensions and
% adjust coordinates to match: 
anat = anat(bBox(1, 1):bBox(1, 2), bBox(2, 1):bBox(2, 2), bBox(3, 1):bBox(3, 2));
vDims = size(anat);
for ii=1:3, view.coords(ii, :) = view.coords(ii, :) - bBox(ii, 1) + 1; end

% Form an isosurface at their boundary, that is, at an isodensity value of
% zero, and get surface normals
mrvWaitbar(0, waitH, 'Create gray-white interface surface...');
whiteSurface = isosurface(anat, 0);
whiteSurface.normals = isonormals(anat, whiteSurface.vertices);
whiteSurface.vertices = whiteSurface.vertices(:, [2 1 3])';
whiteSurface.faces = whiteSurface.faces(:, [2 1 3])';
whiteSurface.normals = whiteSurface.normals(:, [2 1 3])';

% Advance through the gray layers and associate layer 1 nodes with
% subsequent layers that within a search cone around the white-matter
% surface normal.

% Associate layer 1 with the white isosurface normals.
L1inds = find(layers == 1);
L1 = view.coords(:, L1inds);
L1toWhiteMap = nearpoints(L1, whiteSurface.vertices);
L1normals = whiteSurface.normals(:, L1toWhiteMap);
nLength = sqrt(sum(L1normals.^2));
L1normals = L1normals ./ repmat(nLength, [3 1]);

% Loop through all layer-1 vertices.
nL1 = length(L1inds);
thickness = ones(1, nL1);
maxThick = zeros(1, nL1);
mrvWaitbar(0, waitH, 'Calculating thickness...');
for iN=1:nL1
  mrvWaitbar(iN/nL1, waitH);
  cc = L1(:, iN);
  nn = L1normals(:, iN);
  nInds = iN;
  mThick = 0;
  % Dilate in the gray matter by number of layers:
  [neighbors, nInds] = DilateGrayCoords(view, nInds, nLayers);
  nNeighbors = size(neighbors, 2) - 1;
  % Calculate unit vectors pointing from the original point to each of the
  % neighbors:
  vec = neighbors - repmat(cc, [1, nNeighbors+1]);
  lVec = sqrt(sum(vec.^2));
  keep = find(lVec > 0);
  neighbors = neighbors(:, keep);
  nInds = nInds(keep);
  uVec = vec(:, keep) ./ repmat(lVec(keep), [3 1]);
  dotP = sum(uVec .* repmat(nn, [1 nNeighbors]));
  minDotP = cos(atan(coneRadius ./ layers(nInds)));
  % Thickness is defined as the maximum layer number within the search cone:
  thickVals = layers(nInds(dotP >= minDotP));
  if ~isempty(thickVals)
    thickness(iN) = max(thickVals);
    maxThick(iN) = max(layers(nInds));
  end
end

mrvWaitbar(1, waitH, 'Saving thickness results...')
fName = fullfile(vPath, 'thickness.mat');
save(fName, 'thickness');

close(waitH);

return