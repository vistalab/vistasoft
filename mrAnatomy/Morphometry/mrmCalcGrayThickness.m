function [thickness, maxThick] = mrmCalcGrayThickness(coneRadius, wMesh)

% thickness = mrmCalcGrayThickness(coneRadius, whiteMesh);
%
% Calculate the thickness of the gray matter using mrGray nodes. Uses a
% search-cone and nearest-neighbor approach to associate voxels from layer
% 1 with ascending layers. The highest layer node that lies within the
% search cone is defined as the thickness at that node. Note that this
% produces a voxel-wise integer measurement of the thickness. Results are
% returned as a vector corresponding to the layer-1 nodes.
%
% Ress, 08/05

mrGlobals

% Find anatomy path:
if exist('vANATOMYPATH', 'var')
  vPath = fileparts(vANATOMYPATH);
else
  vPath = uigetdir;
end
if vPath(1) == 0, return, end

if ~exist('coneRadius', 'var'), coneRadius = 1/sqrt(2); end
if ~exist('wMesh', 'var')
  view = VOLUME{selectedVOLUME};% Find anatomy path:
  if isfield(view, 'mesh')
    if ~isempty(view.mesh)
      wMesh = viewGet(view,'mesh',1);
    end
  end
end
if ~exist('wMesh', 'var')
  Alert('No gray-white mesh!')
  return
end

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

% Get the gray-white interface surface and normals from the mrMesh
% structure:
whiteVerts = mrmGet(wMesh, 'vertices');
whiteNorms = mrmGet(wMesh, 'normals');

% Create nearest-neighbor associations between the gray-white surface and the layer-1
% mesh vertices. Use these to associate the mesh normals with the
% layer-1 vertices.
L1 = view.nodes(:, layers == 1);
g2vMap = MapGrayToVertices(L1, whiteVerts, view.mmPerVox);
L1Normals = whiteNorms(:, g2vMap);

% After making the associations, convert to matlab coordinate ordering.
L1Normals = L1Normals([2 1 3], :);
L1 = L1([2 1 3], :);

% Advance through the gray layers and associate layer 1 nodes with
% subsequent layers that are within a search cone around the white-matter
% surface normal.

% Associate layer 1 with the white isosurface normals.
nLength = sqrt(sum(L1Normals.^2));
L1Normals = L1Normals ./ repmat(nLength, [3 1]);

% Loop through all layer-1 vertices.
nL1 = size(L1, 2);
thickness = ones(1, nL1);
maxThick = zeros(1, nL1);
mrvWaitbar(0, waitH, 'Calculating thickness...');
for iN=1:nL1
  mrvWaitbar(iN/nL1, waitH);
  cc = L1(:, iN);
  nn = L1Normals(:, iN);
  nInds = iN;
  % Dilate in the gray matter by number of layers:
  [neighbors, nInds] = DilateGrayCoords(view, nInds, nLayers);
  nNeighbors = size(neighbors, 2) - 1;
  % Calculate unit vectors pointing from the original point to each of the
  % neighbors:
  vec = neighbors - repmat(cc, [1, nNeighbors+1]);
  lVec = sqrt(sum(vec.^2));
  keep = find(lVec > 0);
  nInds = nInds(keep);
  uVec = vec(:, keep) ./ repmat(lVec(keep), [3 1]);
  dotP = sum(uVec .* repmat(nn, [1 nNeighbors]));
  minDotP = cos(atan(coneRadius ./ layers(nInds)));
  % Thickness is defined as the maximum layer number within the search cone:
  thickVals = layers(nInds(dotP >= minDotP));
  if ~isempty(thickVals), thickness(iN) = max(thickVals); end
  maxThick(iN) = max(layers(nInds));
end

mrvWaitbar(1, waitH, 'Saving thickness results...')
fName = fullfile(vPath, 'thickness.mat');
save(fName, 'thickness');

close(waitH);

return