function [newCoords, rows, cols] = montage2Coords(vw, montageCoords, clipFlag)
%
% newCoords = montage2Coords(vw, montageCoords, <clipFlag=0>);
%
% For montage views (inplane montage & flat across-levels),
% convert a set of coordinates given relative to the view's
% current montage image into the proper coordinates for the
% view.
%
% montageCoords should be a matrix with two rows, 
% specifying the (y,x) (i.e., row/column) location
% of a set of voxels. If there are more than two 
% rows, subsequent rows are ignored. newCoords is 
% a 3xN matrix, specifying the same voxels in the 
% conventions used by ROIs for that view.
%
% The optional clipFlag argument, if 1, will assume all the points in
% montageCoords will be in the same slice as the first coordinate, and if
% it finds points that lie in different slices, will clip those coordinates
% such that they lie at the edge of the slice. E.g., if there are two
% columns in montageCoords, one in slice 3 and one in slice 1, and the
% montage is 2 by 2 (so slice 1 is just above it), it will clip the second
% point so that the y (row) value is 1, and it's in slice 3.
%
% 09/04 ras.
% 04/06 ras: added clipFlag.
if nargin < 2
    help montage2Coords
    return
end

if size(montageCoords,1) < 2
    error('montageCoords needs >= 2 rows.');
end

if nargin<3, clipFlag = 0; end

%%%%% get info about the montage size, slice size
ui = viewGet(vw,'ui');
[selectedSlices nrows ncols] = montageDims(vw); %#ok<*ASGLU>


% get zoom size (size of each img in montage)
zoom = ui.zoom;
dims = [zoom(4)-zoom(3)+1 zoom(2)-zoom(1)+1];
dims = round(dims);
ycorner = ui.zoom(3) - 1; % location of upper-right corner w/ zoom
xcorner = ui.zoom(1) - 1;

% get slice #
rows = ceil(montageCoords(1,:)./dims(1));
cols = ceil(montageCoords(2,:)./dims(2));
sliceInds = (rows-1)*ncols + cols;
slices = selectedSlices(sliceInds);

% if we're clipping points in a different slice from the first point, 
% do that now:
if clipFlag==1
    diffSlice = find(slices ~= slices(1));
    for d = diffSlice(:)'
        if rows(d) < rows(1) % slice is to left of first slice: col = 1
            montageCoords(2,d) = 1; 
        elseif rows(d) > rows(1) % slice is to right: col = max
            montageCoords(2,d) = dims(1);
        end
        
        if cols(d) < cols(1) % slice is above of first slice: row = 1
            montageCoords(1,d) = 1;
        elseif cols(d) > cols(1) % slice is below: row = max
            montageCoords(1,d) = dims(2);
        end
    end
    
    slices(:) = slices(1);
end

% get x/y pos within slice
y = mod(montageCoords(1,:)-1,dims(1)) + 1;
x = mod(montageCoords(2,:)-1,dims(2)) + 1;
y = y + ycorner;
x = x + xcorner;

% check whether our image is flipped u/d
if viewGet(vw, 'flip ud'), y = ui.zoom(4) - y + 1; end
    
% build newCoords from slice, position info
newCoords = zeros(3,size(montageCoords,2));
newCoords(1,:) = y;
newCoords(2,:) = x;
newCoords(3,:) = slices;



newCoords = round(newCoords);

return
