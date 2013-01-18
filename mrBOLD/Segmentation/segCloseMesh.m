function seg = segCloseMesh(seg);
% seg = segCloseMesh(seg);
%
% Close a mesh in a segmentation. Also closes any display windows.
%
% ras, 10/2006.
m = seg.settings.mesh;
if meshGet(seg.mesh{m}, 'id') > 0
    % close mesh display window
    mrmSet(seg.mesh{m}, 'Close');
end
ok = setdiff(1:length(seg.mesh), m);
seg.mesh = seg.mesh(ok);
if isempty(ok)
	seg.settings.mesh = 0;
else
	seg.settings.mesh = max(m-1, 1); % either prev. mesh in list, or mesh 1
end

return