function coords = mergeCoords(coords1,coords2)
%
% coords = mergeCoords(coords1,coords2,dims)
%
% Merges coords1 and coords2, removing duplicates, used for
% example to merge ROI coordinates into one big ROI.
%
% coords, coords1, and coords2: 3xN arrays of (y,x,z) coordinates
% dims is size of volume
%
% djh, 7/98
% djh, 2/2001, dumped coords2Indices & replaced with union(coords1',coords2','rows')

if ~isempty(coords1) && ~isempty(coords2)
    %coords = union(coords1',coords2','rows');
    %coords = coords';
    % 2003.12.17 RFD: replaced the union call to avoid sorting.
    duplicates = ismember(coords2', coords1', 'rows');
    coords = [coords1 coords2(:,~duplicates)];
else
    coords = [coords1 coords2];
end

return
