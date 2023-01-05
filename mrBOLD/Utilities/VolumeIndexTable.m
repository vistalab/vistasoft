function iVol = VolumeIndexTable(view, layer);

% iVol = VolumeIndexTable([view, layer]);
%
% Generate a reverse look-up table for the current volume coordinates. That
% is, create a volume where where each voxel contains the index of the
% voxel's coordinate vector. In other words, 
% iVol(view.coords(1,j), view.coords(2,j), view.coords(3,j)) = j
% This table enables immediate conversion between coordinates and vector
% indices. Volume voxels that lie outside of the coordinate vector have
% index value = 0, and can thereby be easily distinguished.

mrGlobals

if ~exist('view', 'var')
  selectedVOLUME = viewSelected('Volume');
  view = VOLUME{selectedVOLUME};
end

vDims = size(view.anat);
iVol = repmat(int32(0), vDims);
if exist('layer', 'var')
  coords = view.coords(:, view.nodes(6, :) == layer);
else
  coords = view.coords;
end
inds = coords2Indices(uint32(coords), vDims);
for ii=1:size(coords, 2)
  iVol(inds(ii)) = ii;
end

return
