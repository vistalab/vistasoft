function vw = addROIpoly(vw,sgn)
%
% vw = addROIpoly(vw,,[sgn])
%
% If sgn~=0, adds user-specified polygon to selected ROI in
% current slice. If sgn==0, removes the polygon from the ROI.
%
% If you change this function make parallel changes in:
%   all addROI*.m functions
%
% gmb, 4/23/98 adapted addROIpoly from mrSelPolyRet, added sgn
% djh, 7/98 updated to use ROIcoords instead of selpts
% 2002.10.23 RFD: Replaced 'markPoly' with matlab's 'roipoly'. We now no
% longer depend on the ancient mex function 'mrManifoldDistance', which 
% seems to be broken in Matlab 6.5 anyway.

% error if no current ROI
if vw.selectedROI == 0
  myErrorDlg('No current ROI');
  return
end

if ~exist('sgn','var')
  sgn = 1;
end

% Get current ROI coords
curCoords = getCurROIcoords(vw);

% Save prevSelpts for undo
vw.prevCoords = curCoords;

% Get curSlice
curSlice = viewGet(vw, 'Current Slice');

% 2002.10.23 RFD We now use matlab's 'roipoly' function to replace
% markPoly.
if strcmp(computer,'PCWIN') && ~isempty(regexp(version,'.*R2007b','once'))
	% Mathworks function roipoly.m (at least with this version & platform combo)
	% is having problems with both the WindowButtonDownFcn and normalized figure units found here.
	% You could temporarily remove the former & set the latter to pixels and use roipoly
	% or take this simpler approach while roipolyold still exists - SCN 3/24/10
	polyIm = roipolyold;
else
	polyIm = roipoly;
end

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
    polyCoords=(rotateCoords(vw,polyCoords,1));
end


% Convert coords to canonical frame of reference
polyCoords = curOri2CanOri(vw,polyCoords);

% Merge/remove coordinates
if sgn
  coords = mergeCoords(curCoords,polyCoords);
else
  coords = removeCoords(polyCoords,curCoords);
end
vw.ROIs(vw.selectedROI).coords = coords;

vw.ROIs(vw.selectedROI).modified = datestr(now);

