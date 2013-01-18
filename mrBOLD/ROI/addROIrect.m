function vw = addROIrect(vw,sgn)
%Add a rectangular region of interest
%
% vw = addROIrect(vw,[sgn])
%
% If sgn~=0, adds user-specified rectangle to selected ROI in
% current slice. If sgn==0, removes the rectangle from the ROI.
%
% djh, 7/98
%
% If you change this function make parallel changes in:
%   all addROI*.m functions
%

% error if no current ROI
if vw.selectedROI == 0
    myErrorDlg('No current ROI');
    return
end

if ~exist('sgn','var'), sgn = 1;        end

% Get current ROI coords
curCoords = getCurROIcoords(vw);

% Save prevCoords for undo
vw.prevCoords = curCoords;

% Get curSlice
curSlice = viewGet(vw, 'Current Slice');

% Get region from user.
% (rgn is short for region)
rgn = round(ginput(2));

% Note: ginput hands them back in x, y order (1st col is x and
% 2nd col is y).  But we use them in the opposite order (y then
% x), so flip 'em.
%
rgn = fliplr(rgn);

% ras 01/06: allow clicking on an axis to auto-update the orientation,
% without needing to click the orientation buttons
if checkfields(vw, 'ui', 'axiAxesHandle')
    h=[vw.ui.axiAxesHandle vw.ui.corAxesHandle vw.ui.sagAxesHandle];
    ori = find(h==gca);
    setCurSliceOri(vw, ori);
    curSlice = vw.loc(ori);  % take different current slice
end

% Check if outside image
% (ras 01/06: generalized for 3-axis views)
himg = findobj('Type', 'Image', 'Parent', gca);
dims = size(get(himg, 'CData'));
if (min(rgn(:,1))< 1 || max(rgn(:,1))>dims(1) || ...
        min(rgn(:,2))< 1 || max(rgn(:,2))>dims(2))
    myWarnDlg('Must choose rect entirely within image boundaries');
    return;
end

% Make sure 2nd value is larger than the 1st.
for i=1:2
    if rgn(2,i) < rgn(1,i)
        rgn(:,i) = flipud(rgn(:,i));
    end
end

% Get rgnSize
rgnSize = rgn(2,:) - rgn(1,:) + 1;

% Compute new coordinates
indices = (1:prod(rgnSize));
tmpCoords = indices2Coords(indices,rgnSize);
newCoords = zeros(3,length(indices));
newCoords(1,:) = tmpCoords(1,:) + rgn(1,1) - 1;
newCoords(2,:) = tmpCoords(2,:) + rgn(1,2) - 1;
newCoords(3,:) = curSlice * ones(1,length(indices));

% Do an (inverse) rotation if necessary
if (strcmp(vw.viewType,'Flat'))
    newCoords=(rotateCoords(vw,newCoords,1)); % The '1' here signifies inverse rotation (from screen to zero (internal) representation)
end

% Convert coords to canonical frame of reference
newCoords = curOri2CanOri(vw,newCoords);


% Merge/remove coordinates
if sgn, coords = mergeCoords(curCoords,newCoords);
else    coords = removeCoords(newCoords,curCoords);
end
vw.ROIs(vw.selectedROI).coords = coords;

vw.ROIs(vw.selectedROI).modified = datestr(now);    

return;
