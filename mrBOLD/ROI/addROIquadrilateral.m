function [vw,corners] = addROIquadrilateral(vw,sgn)
%
% [vw, corners] = addROIquadrilateral(vw,[sgn])
%
% If sgn~=0, adds user-specified quadrilateral to selected ROI in
% current slice. If sgn==0, removes the rectangle from the ROI.  
% Main motivation for adding quadrilaterals, and not just using roipoly, is
% we need to define four corner points when creating atlases.
%
% 2003.09.15 BW
%   
% Based on addROIpoly
% Example:
%  FLAT{1} = newROI(FLAT{1},'test');
%  FLAT{1} = addROIquadrilateral(FLAT{1});
%
% error if no current ROI
if vw.selectedROI == 0, myErrorDlg('No current ROI');  return; end
if ~exist('sgn','var'), sgn = 1; end

% Get current ROI coords
curCoords = getCurROIcoords(vw);

% Save prevSelpts for undo
vw.prevCoords = curCoords;

% Get curSlice
curSlice = viewGet(vw, 'Current Slice');

% Get four points to define the quadrilateral region from user.
curFig = gcf;
figure(vw.ui.figNum);
corners = round(ginput(4));
figure(curFig);

% Now, we need to figure out how to turn the rgn points into the C,R and
% we need to figure out how to set up I so that we are returned the polyIm
% that matches the current data image.
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
	
	% we need to do some reorienting to get the corners into the standard
	% vw coordinate system, then rotate them:
	cornerCoords = [fliplr(corners) repmat(curSlice, [size(corners, 1) 1])]';
	cornerCoords = (rotateCoords(vw, cornerCoords, 1));
	corners = cornerCoords([2 1],:)';
end

% Convert coords to canonical frame of reference
polyCoords = curOri2CanOri(vw,polyCoords);

% Merge/remove coordinates from the current coordinates
if sgn
  coords = mergeCoords(curCoords,polyCoords);
else
  coords = removeCoords(polyCoords,curCoords);
end
vw.ROIs(vw.selectedROI).coords = coords;

return;
