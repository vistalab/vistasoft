function startPointIdx = flatStartPoint(flatView,hemisphere)
%
%  startPointIdx = flatStartPoint(flatView,hemisphere)
%
%Author:  Wandell
%Purpose:
%  In some cases we did not save the index of the start node for the
%  unfold.  Yes, I know, I know.  This will be a node at the center of the
%  flat map.  This routine returns an index into the coordinates of the
%  unfolded points in the flat view that is close to the start point.
%  Called by getFlat.
%
% Example:
%
%  startIdx = flatStartPoint(flatView,'left');

switch hemisphere
    case 'left'
        coords = flatView.coords{1};
    case 'right'
        coords = flatView.coords{2};
    otherwise
        error('unknown hemisphere')
end

mx = abs(max(coords(:)));
center = mx/2;
d2 = (coords(1,:) - center).^2 + (coords(2,:) - center).^2;

[v,startPointIdx] = min(d2);

return;