function vw = addROIsinglePoint(vw,sgn)
%
% vw = addROIsinglePoint(vw,[sgn])
%
% AUTHOR:  Wandell
% DATE:   07.26.00
% PURPOSE:
%   The user clicks on a point and all of the gray matter within
% a distance, d, is selected for an ROI.  The calculation of the
% disk is managed by mrManifoldDistance.
% 
% We find gray matter that is within some distance of the selected point.  
% This is always done using gray matter graph in the VOLUME and coords data set
% via the routine mrManifoldDistance.  It appears that the proper nodes and
% edges are in Gray/coords.mat
%
% Hence, we have to 
%   (a) make sure the gray graph is loaded, 
%   (b) find the selected point in the gray matter, 
%   (c) compute the disk around the point
%       return the corresponding values in whatever view we are in.
% If sgn~=0, the routine adds user-specified disk to the selected ROI in
% current slice. If sgn==0, the disk is removed from the current ROI.
%
% Follows logic from:  djh, 7/98
%
% If you change this function make parallel changes in:
%   all addROI*.m functions

% error if no current ROI.  This is usually created by the
% callback, so it should be here.
if vw.selectedROI == 0
  myErrorDlg('No current ROI');
  return
end

% Default is to add the data to the current ROI
if ~exist('sgn','var')
  sgn = 1;
end

% Get current ROI coords
curCoords = getCurROIcoords(vw);

% Save prevSelpts for undo
vw.prevCoords = curCoords;

% Get curSlice
curSlice = viewGet(vw, 'Current Slice');

% Get a single point from the user.  We leave the designation
% rgn, rather than pnt, for now.
% (rgn is short for region)
figure(vw.ui.figNum);
rgn = round(ginput(1));

% Note: ginput hands them back in x, y order (1st col is x and
% 2nd col is y).  But we use them in the opposite order (row,col), so that 
% we want (y,x).  So we flip 'em. Hmmm....BW, but, but ...
%
rgn = fliplr(rgn);

% Check if outside image
dims=size(vw.ui.image);
if (min(rgn(:,1))< 1 | max(rgn(:,1))>dims(1) | ...
      min(rgn(:,2))< 1 | max(rgn(:,2))>dims(2))
  myWarnDlg('Selected point is outside image boundaries');
  return;
end

% Compute new coordinates
newCoords(1,:) = rgn(1);
newCoords(2,:) = rgn(2);
newCoords(3,:) = curSlice;

% Convert coords to canonical frame of reference
% Do an (inverse) rotation if necessary
if (strcmp(vw.viewType,'Flat'))
    newCoords=(rotateCoords(vw,newCoords,1));
end

% for VOLUME vw.  It does nothing for other views.
newCoords = curOri2CanOri(vw,newCoords);

% Merge/remove coordinates
if sgn
  coords = mergeCoords(curCoords,newCoords);
else
  coords = removeCoords(newCoords,curCoords);
end
vw.ROIs(vw.selectedROI).coords = coords;

return;
