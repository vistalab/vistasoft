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
% This is only really meaningful in the flat view... DO a check to make
% sure it's a FLAT
% Get curSlice
curSlice = viewGet(vw, 'Current Slice');

if view.rotateImageDegrees(curSlice)>0  %detects if the Flat your are currently selecting the points ist rotated
            errordlg('Flat must not be rotated','Warning!'); %Results would be wrong!
end


% Get current ROI coords
curCoords = getCurROIcoords(view);

% Save prevCoords for undo
view.prevCoords = curCoords;




% -------- Copied and edited from measureCOrticalDistance...

    % Select flat figure and get a single point from the user
    figure(view.ui.figNum)
    disp('Click left to add points, right to quit');
    button = 1;
    count = 0;
    w = 0.5;
    coords = [];

    while(button~=3)
        [x,y,button] = ginput(1);
        if(button==3)
            break;
        end
        count = count+1;
        coords = [coords,round([y;x;curSlice])];
        h(count) = line([x-w,x-w,x+w,x+w,x-w],[y-w,y+w,y+w,y-w,y-w],'Color','w');
     
    end
    % Delete the temporarily drawn squares
    for ii=1:length(h)
        delete(h(ii));
    end
    clear h;



nPoints=size(coords,2);




% Check if outside image
% 
% dims=size(view.ui.image);
% if (min(rgn(:,1))< 1 | max(rgn(:,1))>dims(1) | ...
%       min(rgn(:,2))< 1 | max(rgn(:,2))>dims(2))
%   myWarnDlg('Must choose line endpoints within image boundaries');
%   return;
% end

% In findLinePoints, if y1 == y2, we draw the horizontal line.
% if x1 == x2 we draw a vertical line.
% otherwise, we sample along the longer direction and find the
% appropriate value along the shorter direction.
finalCoords=[];


for thisLineSegment=1:nPoints-1

y1 = coords(2,thisLineSegment); y2 = coords(2,thisLineSegment+1);
x1 = coords(1,thisLineSegment); x2 = coords(1,thisLineSegment+1);

[thisXList, thisYList] = findLinePoints([x1 y1], [x2 y2]);

if ieNotDefined('newCoords')
    newCoords=[thisXList(:),thisYList(:)];
else
    newCoords=[newCoords;[thisXList(:),thisYList(:)]];
end

end

% Do an (inverse) rotation if necessary
if (strcmp(view.viewType,'Flat'))
    newCoords=(rotateCoords(view,newCoords,1));
end

% Add in the slice index
newCoords=[newCoords,ones(size(newCoords,1),1)*curSlice]';


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

return;
