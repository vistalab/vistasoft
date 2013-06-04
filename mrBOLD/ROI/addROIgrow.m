function vw = addROIgrow(vw,sgn,fillholes)
% vw = addROIgrow(vw,[sgn],[filholes]);
%
% Grows a ROI region in 3D (ie not just in current slice) using a
% three-dimensional six-connected neighborhood.
%
% If sgn~=0, adds user-specified rectangle to selected ROI in
% current slice. If sgn==0, removes the rectangle from the ROI.
%
% If fillholes~=0, [default = 0] then fill holes in ROI 
% (regardless of their value).
%
% 27/06/2005 SOD

if notDefined('sgn'), sgn = 1; end
if notDefined('fillholes'), fillholes = 0; end;

% error if no current ROI
if vw.selectedROI==0, myErrorDlg('No current ROI'); return; end

% Get current ROI coords
curCoords = getCurROIcoords(vw);

% Save prevSelpts for undo
vw.prevCoords = curCoords;

% Get curSlice
curSlice = viewGet(vw, 'Current Slice');

% Get starting point from user.
% (rgn is short for region)
rgn = round(ginput(1));

% Note: ginput hands them back in x, y order (1st col is x and
% 2nd col is y).  But we use them in the opposite order (y then
% x), so flip 'em.
rgn = fliplr(rgn);

% ras 01/06: allow clicking on an axis to auto-update the orientation,
% without needing to click the orientation buttons
if checkfields(vw, 'ui', 'axiAxesHandle')
    h=[vw.ui.axiAxesHandle vw.ui.corAxesHandle vw.ui.sagAxesHandle];
    ori = find(h==gca);
    setCurSliceOri(vw, ori);
    curSlice = vw.loc(ori);  % take different current slice
end


% % Check if outside image
% dims = size(get(findobj('Parent', gca, 'Type', 'Image'), 'CData'));
% if (min(rgn(:,1))< 1 | max(rgn(:,1))>dims(1)),
%     myWarnDlg('Must choose starting point within image boundaries');
%     return;
% end;

% Compute new coordinates
newCoords = zeros(3,1);
newCoords(1,:) = rgn(1,1);
newCoords(2,:) = rgn(1,2);
newCoords(3,:) = curSlice;

% for montage views, convert from montage coords to vw coords
if checkfields(vw, 'ui', 'montageSize')
    newCoords = montage2Coords(vw,newCoords);
end

% Convert coords to canonical frame of reference
newCoords = curOri2CanOri(vw,newCoords);

% get thesholds
cothresh =  getCothresh(vw);
phWindow =  getPhWindow(vw);
mapWindow = getMapWindow(vw);
curScan =   getCurScan(vw);

% get data, above cothresh, between phthresh and mapthresh
% coherence
data = [];
if ~isempty(vw.co) & cothresh~=0,
    tmp  = getCurData(vw,'co',curScan);
    data = tmp>cothresh;
end;

% phase
if ~isempty(vw.ph),
    tmp = getCurData(vw,'ph',curScan);
    
    % we need to check whether there is a phase wrap
    if phWindow(2) > phWindow(1),
        tmp = tmp>=phWindow(1) & tmp<=phWindow(2);
    else
        tmp = tmp>=phWindow(1) | tmp<=phWindow(2);
    end
    
    if isempty(data),
        data = tmp;
    else,
        data = tmp.*data;
    end;
end;

% map
if ~isempty(vw.map),
    tmp = getCurData(vw,'map',curScan);
    tmp = tmp>=mapWindow(1) & tmp<=mapWindow(2);
    if isempty(data),
        data = tmp;
    else,
        data = tmp.*data;
    end;
end;

if isempty(data),
    data = viewGet(vw,'anatomy');
end;

% find clusters
[imgLabel] = bwlabeln(data, 6);

% correct for upsample factor of ui
uiScale = upSampleFactor(vw,curScan);
newCoords(1:2,:) = round(newCoords(1:2,:)./uiScale(1:2)');

% find our cluster
Label = imgLabel(newCoords(1),newCoords(2),newCoords(3));
if Label==0, % no data so quit
    return;
end;

% data with only our cluster
data = imgLabel==Label;

if fillholes~=0,
  % find clusters again, flipped to we get background only
  imgLabel2 = bwlabeln(data*-1+1,6);
  % loop over clusters and make the ones that are larger than the ROI
  % background - assume smaller clusters are holes
  roisize = sum(data(:));
  % another loop... sigh
  labels = unique(imgLabel2)';
  labels = labels(find(labels>0));
  for n=labels,
    label = find(imgLabel2==n);
    if length(label) >= roisize,
      data(label) = 0;
    else,
      data(label) = 1;
    end;
  end;
end;

% apply upsample factor again for each slice
dims = viewGet(vw,'Size');
sliceWithData = find(squeeze(max(max(data))));
datanew = zeros(dims);
for slice = sliceWithData, % loops...
    datanew(:,:,slice)=imresize(data(:,:,slice),dims(1:2),'nearest',0);
end;
data = datanew;

% convert matrix to coords
[i1, i2, i3] = ind2sub(size(data),find(data>.5));
newCoords = [i1 i2 i3]';

% Merge/remove coordinates
if sgn
    coords = mergeCoords(curCoords,newCoords);
else
    coords = removeCoords(newCoords,curCoords);
end
vw.ROIs(vw.selectedROI).coords = coords;

vw.ROIs(vw.selectedROI).modified = datestr(now);

return;
