function view = addROIrectMontage(view,sgn)
%
% view = addROIrectMontage(view,[sgn])
%
% If sgn~=0, adds user-specified rectangle to selected ROI in
% current slice. If sgn==0, removes the rectangle from the ROI.
%
% djh, 7/98
% ras, 9/04 -- updated for montage view
% If you change this function make parallel changes in:
%   all addROI*.m functions

% error if no current ROI
if view.selectedROI == 0
  myErrorDlg('No current ROI');
  return
end

if ~exist('sgn','var')
  sgn = 1;
end

% Get current ROI coords
curCoords = getCurROIcoords(view);

% Save prevSelpts for undo
view.prevCoords = curCoords;

% Get region from user. 
% (rgn is short for region)
rgn = round(ginput(2));

% Make sure 2nd value is larger than the 1st.
for i=1:2
  if rgn(2,i) < rgn(1,i)
    rgn(:,i)=flipud(rgn(:,i));
  end
end

% Note: ginput hands them back in x, y order (1st col is x and
% 2nd col is y).  But we use them in the opposite order (y then
% x), so flip 'em.
rgn = fliplr(rgn);

% Get rgnSize
rgnSize = rgn(2,:) - rgn(1,:) + 1;

% Compute new coordinates
indices = 1:prod(rgnSize);
tmpCoords = indices2Coords(indices,rgnSize);
montageCoords = zeros(2,length(indices));
montageCoords(1,:) = tmpCoords(1,:) + rgn(1,1);
montageCoords(2,:) = tmpCoords(2,:) + rgn(1,2);
newCoords = montage2Coords(view,montageCoords);

% Do an (inverse) rotation if necessary
if (strcmp(view.viewType,'Flat'))
    % The '1' here signifies inverse rotation 
	% (from screen to zero (internal) representation)
    newCoords = rotateCoords(view,newCoords,1); 
end

% Convert coords to canonical frame of reference
newCoords = curOri2CanOri(view,newCoords);

% Merge/remove coordinates
if sgn
  coords = mergeCoords(curCoords,newCoords);
else
  coords = removeCoords(newCoords,curCoords);
end
view.ROIs(view.selectedROI).coords = coords;
view.ROIs(view.selectedROI).modified = datestr(now);

return
