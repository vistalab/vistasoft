function vw = replaceROIQuadrilateralCoords(vw,corners)
%
% vw = replaceROIQuadrilateralCoords(vw,corners)
%
% Author:  BW,AAB
% Purpose:
%   Replace the coordinates in the currently selected roi with a
%   quadrilateral region defined by the corners.

curSlice =viewGet(vw, 'Current Slice');

% is this a flat view with potential rotations/flips?
% if so, we need to rotate the corners to reflect how they would be
% displayed given the current settings
if strcmp(vw.viewType, 'Flat')
	% we need to do some reorienting to get the corners into the standard
	% view coordinate system, then rotate them:
	cornerCoords = [fliplr(corners) repmat(curSlice, [size(corners, 1) 1])]';
	cornerCoords = (rotateCoords(vw, cornerCoords, 0));
	corners = cornerCoords([2 1],:)';
end
	
% Create a binary image with 1s within this quadrilateral
polyIm = roipoly(vw.ui.image,corners(:,1),corners(:,2));

% % markPoly returns an image with 1's marking the polygon
% dims=size(vw.ui.image);
% polyIm = markPoly(dims);

% Compute image coordinates
polyImIndices = find(polyIm);
polyImCoords = indices2Coords(polyImIndices,size(polyIm));

% Add curSlice as 3rd row to get volume coordinates
polyCoords = [polyImCoords; curSlice*ones(1,size(polyImCoords,2))];

% Do an (inverse) rotation if necessary
if (strcmp(vw.viewType,'Flat'))
    polyCoords = (rotateCoords(vw,polyCoords,1));
end


% Convert coords to canonical frame of reference
polyCoords = curOri2CanOri(vw,polyCoords);

vw.ROIs(vw.selectedROI).coords = polyCoords;

return;
