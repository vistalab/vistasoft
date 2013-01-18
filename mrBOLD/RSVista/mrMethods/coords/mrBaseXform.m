function xform = mrBaseXform(base, map);
%
% xform = mrBaseXform(base, map);
%
% Compute a 4x4 transform matrix to translate from
% data coords in a map volume to data coords in a 
% base volume.
%
% base and map are both MR objects (see mrLoad). Will
% prompt if either is not specified.
%
%
% ras 07/05.
if ~exist('base', 'var') | isempty(base),  base = mrLoad; end
if ~exist('map', 'var') | isempty(map),  map = mrLoad; end

% first,  check if the two MR volumes cover the same space
% at the same resolution: then they're already in the same
% coordinate space and the xform is just an identity matrix:
if isequal(base.dims(1:3), map.dims(1:3)) & ...
        isequal(base.voxelSize(1:3), map.voxelSize(1:3))
    disp('Base and map volumes are coregistered')
    xform = eye(4);
    return
end

% next,  check that they don't specify the same extent
% in 3D space,  even if they may be at different resolutions:
if isequal(base.extent(1:3), map.extent(1:3)) | ...
        abs(base.extent(1:3)-map.extent(1:3)) < [1 1 1]
    disp('Base and map cover same extent -- scaling map to fit base')
    szRatio = map.voxelSize(1:3) ./ base.voxelSize(1:3);
    xform = affineBuild([0 0 0], [0 0 0], szRatio);
    return
end

% otherwise,  check if they share a common coordinate space.
% First,  remove the standard spaces (raw data in pix/mm,  L/R
% flipped -- see mrStandardSpaces):
spacesA = {base.spaces.name};
spacesB = {map.spaces.name};
std = {'Raw Data in Pixels' 'Raw Data in mm' 'L/R Flipped'};
spacesA = setdiff(spacesA, std);
spacesB = setdiff(spacesB, std);
common = intersect(spacesA, spacesB);

if isempty(common)
    error('base and map do not share any common coordinate spaces!');
end

% if we're here,  this means there is a common coord system. 
% use the first common space (it shouldn''t matter which one
% is used) to derive the xform:
common = common{1};
fprintf('Coregistering via common space %s \n', common);
spacesA = {base.spaces.name};
spacesB = {map.spaces.name};
iA = cellfind(spacesA, common);
iB = cellfind(spacesB, common);
xform = inv(base.spaces(iA).xform) * map.spaces(iB).xform;

return

