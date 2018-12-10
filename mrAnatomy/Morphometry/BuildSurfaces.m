function [graySurface, whiteSurface] = BuildSurfaces(path)

% [graySurface, whiteSurface] = BuildSurfaces(path);
%
% Build surface models of the white-gray interface and gray-matter outer
% surface that correspond to the classification volume. The technique used
% here is the isodensity surface routine that was available starting with
% Matlab R13. This method circumvents the methods used in mrGray, obtaining
% similar results. Results are always saved as a file, surfaces.mat, at the
% top level of the anatomy directory. The results are also returned as
% matlab surface structures.
%
% Ress, 07/05

mrGlobals

if ~exist('path', 'var')
  if exist('vANATOMYPATH', 'var')
    path = fileparts(vANATOMYPATH);
  else
    path = uigetdir;
  end
end

% Get gray-matter coordinates for entire volume:
leftPath = fullfile(path, 'left', '*.?r?y');
[file, path1] = uigetfile(leftPath, 'Select left hemisphere gray file');
if file(1) == 0
  allLeftNodes = [];
else
  allLeftNodes = loadGrayNodes('left', fullfile(path1, file));
end
rightPath = fullfile(path, 'right', '*.?r?y');
[file, path1] = uigetfile(rightPath, 'Select right hemisphere gray file');
if file(1) == 0
  allRightNodes = [];
else
  allRightNodes = loadGrayNodes('right', fullfile(path1, file));
end
grayCoords = [];
if ~isempty(allLeftNodes), grayCoords = allLeftNodes([2 1 3], :); end
if ~isempty(allRightNodes), grayCoords = [grayCoords, allRightNodes([2 1 3], :)]; end

% Determine bounding box for gray matter:
bBox = zeros(3, 2);
for ii=1:3
  bBox(ii, 1) = min(grayCoords(ii, :)');
  bBox(ii, 2) = max(grayCoords(ii, :)');
end

waitH = mrvWaitbar(0, 'Build classification volume...');
% Create volume containing white-matter voxels set to 1, gray-matter voxels
% set to -1:
anat = double(permute(BuildWhiteVolume, [2 1 3]));
vDims = size(anat);
anat(anat == 0) = -1; % Set non-white matter to -1

% To reduce computations, restrict volume to bounding-box dimensions and
% adjust coordinates to match: 
anat = anat(bBox(1, 1):bBox(1, 2), bBox(2, 1):bBox(2, 2), bBox(3, 1):bBox(3, 2));
for ii=1:3, grayCoords(ii, :) = grayCoords(ii, :) - bBox(ii, 1) + 1; end

% Form an isosurface at their boundary, that is, at an isodensity value of
% zero:
mrvWaitbar(0.1, waitH, 'Create gray-white interface surface...');
whiteSurface = isosurface(anat, 0.5);
whiteSurface.vertices = whiteSurface.vertices(:, [2 1 3])';
whiteSurface.faces = whiteSurface.faces(:, [2 1 3])';

% Add the gray matter to the classification volume and create a surface at
% its outer edge by forming an isodensity surface at zero. 
mrvWaitbar(.55, waitH, 'Create gray outer surface...');
anat(coords2Indices(grayCoords, size(anat))) = 1;
graySurface = isosurface(anat, -0.5);
graySurface.vertices = graySurface.vertices(:, [2 1 3])';
graySurface.faces = graySurface.faces(:, [2 1 3])';

% Adjust the vertex and face coordinates for the bounding box offset:
for ii=1:3
  whiteSurface.vertices(ii, :) = whiteSurface.vertices(ii, :) + bBox(ii, 1) - 1;
  whiteSurface.faces(ii, :) = whiteSurface.faces(ii, :) + bBox(ii, 1) - 1;
  graySurface.vertices(ii, :) = graySurface.vertices(ii, :) + bBox(ii, 1) - 1;
  graySurface.faces(ii, :) = graySurface.faces(ii, :) + bBox(ii, 1) - 1;
end

% Calculate gray-matter thickness and mappings:
mrvWaitbar(0.9, waitH, 'Calculating gray-matter thickness...');
[GWmap, gThick2] = nearpoints(whiteSurface.vertices, graySurface.vertices);
whiteSurface.thickness = sqrt(gThick2);
whiteSurface.grayMap = GWmap;

mrvWaitbar(0.95, waitH, 'Saving surfaces...');
fName = fullfile(path, 'surfaces');
save(fName, 'whiteSurface', 'graySurface');

close(waitH);

return