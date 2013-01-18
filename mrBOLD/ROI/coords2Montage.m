function montageCoords = coords2Montage(vw,coords)
%
% montageCoords = coords2Montage(vw,coords);
%
% For montage views (inplane montage & flat across-levels),
% convert a set of coordinates given in standard vw
% coordinates (i.e. those used by ROIs) to image coordinates
% for the currently-viewed montage, taking into account
% the slices being shown and the area being zoomed.
%
% coords should be a 3 x N matrix;
% montageCoords is a 2 x N' matrix of x,y positions
% for each voxel given relative to vw.ui.image.
% N' is <= N, and reflects only those points
% included in the montage image.
%
% 09/04 ras.
if nargin < 2
    help coords2Montage
    return
end

if size(coords,1) < 3
    error('coords needs >= 3 rows.');
end

%%%%% get info about the montage size, slice size
ui = viewGet(vw,'ui');
viewType = viewGet(vw,'viewType');
switch viewType
    case 'Inplane',        
        firstSlice = viewGet(vw, 'curSlice');
        if isfield(ui, 'montageSize')
    		nSlices = get(ui.montageSize.sliderHandle,'Value');
        else
            nSlices = 1;
        end
        selectedSlices = firstSlice:firstSlice+nSlices-1;
        
    case 'Flat',
        if checkfields(vw, 'ui', 'levelButtons')
            selectedSlices = getFlatLevelSlices(vw);    
        else
            selectedSlices = viewGet(vw, 'curSlice');
        end
        
    otherwise,
        error('drawROIsMontage: no support for this vw type.');
end
selectedSlices = selectedSlices(selectedSlices <= viewGet(vw, 'numSlices'));
nSlices = length(selectedSlices); 
nrows = ceil(sqrt(length(selectedSlices)));
ncols = ceil(nSlices/nrows);

% get zoom size (size of each img in montage)
zoom = vw.ui.zoom;
dims = [zoom(4)-zoom(3)+1 zoom(2)-zoom(1)+1];
dims = round(dims);
ycorner = ui.zoom(3) - 1; % location of upper-right corner w/ zoom
xcorner = ui.zoom(1) - 1;

montageCoords = zeros(2,size(coords,2));

for iSlice = 1:length(selectedSlices)
    curSlice = selectedSlices(iSlice);
    
    row = ceil(iSlice/ncols);
    col = mod(iSlice-1,ncols) + 1;
    
    ind = find(coords(3,:)==curSlice);
    
    y = coords(1,ind) + (row-1)*dims(1) - ycorner;
    x = coords(2,ind) + (col-1)*dims(2) - xcorner;
    
    % remove x,y coords outside the zoomed-in area
    outOfBounds = find(coords(1,ind) < ui.zoom(3) |...
                       coords(1,ind) > ui.zoom(4) | ...
                       coords(2,ind) < ui.zoom(1) | ...
                       coords(2,ind) > ui.zoom(2));
    y(outOfBounds) = 0;
    x(outOfBounds) = 0;
    
    montageCoords(1,ind) = y;
    montageCoords(2,ind) = x;
end

% remove unassigned coords
unassigned = find(montageCoords(1,:)==0);
keep = setdiff(1:size(montageCoords,2),unassigned);
montageCoords = montageCoords(:,keep);

return
