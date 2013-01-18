function [coords inds] = getSelectedCoords(vw)
%
% [coords inds] = getSelectedCoords(vw)
%
% Get all voxel coordinates and indices according to cothresh, phWindow,
% and map window.
%
% Uses curScan as the reference scan.
%
%  JW,  4/2010


% which scan?
curScan     = viewGet(vw, 'curscan');

% read slider limits
cothresh    = viewGet(vw, 'cothresh');
phWindow    = viewGet(vw, 'phasewindow');
mapWindow   = viewGet(vw, 'mapwindow');

% read data
co          = viewGet(vw, 'co', curScan);
ph          = viewGet(vw, 'ph', curScan);
map         = viewGet(vw, 'map', curScan);

% convert to vectors
if iscell(co),  co  = co{1};  end
if iscell(ph),  ph  = ph{1};  end
if iscell(map), map = map{1}; end

% get all the coords
coords = viewGet(vw, 'coords');
inds   = 1:length(coords);

% now restrict coords according to each field

if ~isempty(co),
    inds = inds(co > cothresh);
end

if ~isempty(ph),
    inds = inds(ph(inds) > min(phWindow) & ph(inds) < max(phWindow));
end

if ~isempty(map),
    inds = inds(map(inds) > min(mapWindow) & map(inds) < max(mapWindow));
end

coords = coords(:, inds);

