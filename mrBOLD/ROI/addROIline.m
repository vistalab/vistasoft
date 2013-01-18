function view = addROIline(view,sgn)
%
% view = addROIline(view,[sgn])
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
if view.selectedROI == 0
  myErrorDlg('No current ROI');
  return
end

if ~exist('sgn','var')
  disp('Default:  adding coords')
  sgn = 1;
end

% Get current ROI coords
curCoords = getCurROIcoords(view);

% Save prevCoords for undo
view.prevCoords = curCoords;

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

% Check if outside image
% 
dims=size(view.ui.image);
if (min(rgn(:,1))< 1 | max(rgn(:,1))>dims(1) | ...
      min(rgn(:,2))< 1 | max(rgn(:,2))>dims(2))
  myWarnDlg('Must choose line endpoints within image boundaries');
  return;
end

% In findLinePoints, if y1 == y2, we draw the horizontal line.
% if x1 == x2 we draw a vertical line.
% otherwise, we sample along the longer direction and find the
% appropriate value along the shorter direction.
% 
y1 = rgn(1,1); y2 = rgn(2,1);
x1 = rgn(1,2); x2 = rgn(2,2);
[x1 y1 x2 y2]
[x, y] = findLinePoints([x1 y1], [x2 y2]);

newCoords = zeros(3,length(x));
newCoords(1,:) = y;
newCoords(2,:) = x;
newCoords(3,:) = curSlice*ones(1,length(x));

% Do an (inverse) rotation if necessary
if (strcmp(view.viewType,'Flat'))
    newCoords=(rotateCoords(view,newCoords,1));
end

% Convert coords to canonical frame of reference
newCoords = curOri2CanOri(view,newCoords);

% Merge/remove coordinates
if sgn
  disp('Merging Coords')
  coords = mergeCoords(curCoords,newCoords);
else
  disp('Removing Coords')
  coords = removeCoords(newCoords,curCoords);
end

view.ROIs(view.selectedROI).coords = coords;

view.ROIs(view.selectedROI).modified = datestr(now);

return;
