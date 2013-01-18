function vw = addROIlineMontage(vw,sgn)
%
% vw = addROIlineMontage(vw,[sgn])
%
% Click on two points in the image and find an ROI along a line
% between them.  What does line mean?  Geodesic or screen line?
% 
% If sgn~=0, adds user-specified line to selected ROI in
% current slice. If sgn==0, removes the line from the ROI.
%
% If you change this function make parallel changes in:
%   all addROI*.m functions
%
% bw, 4/30/99

% error if no current ROI
if vw.selectedROI == 0
  myErrorDlg('No current ROI');
  return
end

if ~exist('sgn','var')
  disp('Default:  adding coords')
  sgn = 1;
end

% Get current ROI coords
curCoords = getCurROIcoords(vw);

% Save prevCoords for undo
vw.prevCoords = curCoords;

% Get curSlice
curSlice = viewGet(vw, 'Current Slice');

% Get two points from user. 
% (rgn is short for region)
rgn = round(ginput(2));

% Note: ginput hands them back in x, y order (1st col is x and
% 2nd col is y).  But we use them in the opposite order (y then
% x), so flip 'em.  When we are done we have two points in the form
% 
%    y1 x1
%    y2 x2
% 
% where y means row and x means column
% 
rgn = fliplr(rgn);

%%%%% get info about the montage size, slice size
ui = viewGet(vw,'ui');
viewType = viewGet(vw,'viewType');
switch viewType
    case 'Inplane',
        firstSlice = viewGet(vw, 'Current Slice');
		nSlices = get(ui.montageSize.sliderHandle,'Value');
    case 'Flat',
        firstSlice = get(ui.level.sliderHandle,'Value');
        nSlices = str2num(get(ui.level.numLevelEdit,'String'));
    otherwise,
        error('drawROIsMontage: no support for this view type.');
end
selectedSlices = firstSlice:firstSlice+nSlices-1;
selectedSlices = selectedSlices(selectedSlices <= numSlices(vw));
ncols = ceil(sqrt(nSlices));
nrows = ceil(nSlices/ncols);

% get zoom size (size of each img in montage)
zoom = vw.ui.zoom;
dims = [zoom(4)-zoom(3) zoom(2)-zoom(1)];
dims = round(dims);
xcorner = ui.zoom(3); % location of upper-right corner w/ zoom
ycorner = ui.zoom(1);

% get slice #
row = ceil(rgn(1,1)/dims(1));
col = ceil(rgn(1,2)/dims(2));
montageInd = (row-1)*ncols + col;
slice = selectedSlices(montageInd);

% get x/y pos within slice
rgn(:,1) = mod(rgn(:,1)-1,dims(1)) + 1;
rgn(:,2) = mod(rgn(:,2)-1,dims(2)) + 1;
rgn(:,1) = rgn(:,1) + xcorner;
rgn(:,2) = rgn(:,2) + ycorner;

% check for wrap-around of diff't mosaic images
if rgn(2,1) < rgn(1,1)
    rgn(2,1) = dims(1);
end
if rgn(2,2) < rgn(1,2)
    rgn(2,2) = dims(2);
end

% In findLinePoints, if y1 == y2, we draw the horizontal line.
% if x1 == x2 we draw a vertical line.
% otherwise, we sample along the longer direction and find the
% appropriate value along the shorter direction.
y1 = rgn(1,1); y2 = rgn(2,1);
x1 = rgn(1,2); x2 = rgn(2,2);
[x1 y1 x2 y2]
[x, y] = findLinePoints([x1 y1], [x2 y2]);


% build set of new coords from this info
newCoords = zeros(3,length(x));
newCoords(1,:) = y;
newCoords(2,:) = x;
newCoords(3,:) = slice*ones(1,length(x));

% Do an (inverse) rotation if necessary
if (strcmp(vw.viewType,'Flat'))
    newCoords=(rotateCoords(vw,newCoords,1));
end

% Convert coords to canonical frame of reference
newCoords = curOri2CanOri(vw,newCoords);

% Merge/remove coordinates
if sgn
  disp('Merging Coords')
  coords = mergeCoords(curCoords,newCoords);
else
  disp('Removing Coords')
  coords = removeCoords(newCoords,curCoords);
end

vw.ROIs(vw.selectedROI).coords = coords;
vw.ROIs(vw.selectedROI).modified = datestr(now);

return
