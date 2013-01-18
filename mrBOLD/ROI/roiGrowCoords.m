function coords = roiGrowCoords(ui);
% Grow Coords from a seed in mrViewer.
%
% coords = roiGrowCoords(ui);
%
% Get a point from the user from which to grow a 'blob' of
% interconnected points in 3D, and return a 3xN list of coordinates
% for those points (in the base MR data).
% ras 09/2005.
figure(ui.fig);
tmp = get(ui.panels.display,'BackgroundColor');
set(ui.panels.display,'BackgroundColor','y');
hmsg = mrMessage('Select point from which to grow.');
pt = round(ginput(1));
close(hmsg);
set(ui.panels.display,'BackgroundColor',tmp);

% figure out what image was clicked on
imgNum = find(ui.display.axes==gca);
if isempty(imgNum)
    warning('Didn''t click on mrViewer display. No points added.')
    coords = [];
    return
end

% find seed location in the data coords
imgCoords = mrViewGet(ui,'DataCoords',imgNum);
imgSz = size(ui.display.images{imgNum});
ind = sub2ind(imgSz,pt(2),pt(1));
seed = round(imgCoords(:,ind));

% First-pass method of growing a blob efficiently:
% (1) Create an initial box, centered on seed
% (2) Restrict the box to coords which pass overlay thresholds
% (3) Find contiguous blob which contains seed
% (4) Test if box contains whole blob: if not, repeat 1-4 iteratively
hmsg = msgbox('Growing ROI...');
boxSize = 10; stepSize = 10;
coords = [];
while 1
    % (1) create box (get coords specifying box in data)
    ymin = max(1,seed(1)-boxSize);
    ymax = min(ui.mr.dims(1),seed(1)+boxSize);
    xmin = max(1,seed(2)-boxSize);
    xmax = min(ui.mr.dims(2),seed(2)+boxSize);
    zmin = max(1,seed(3)-boxSize);
    zmax = min(ui.mr.dims(3),seed(3)+boxSize);
    [X Y Z] = meshgrid(xmin:xmax,ymin:ymax,zmin:zmax);
    boxCoords = [Y(:) X(:) Z(:)]'; clear X Y Z
    mask = logical(zeros(ui.mr.dims(1:3)));

    % (2) restrict box to overlays
    boxCoords = mrViewRestrict(ui,boxCoords);
    ok = sub2ind(size(mask),boxCoords(1,:),boxCoords(2,:),boxCoords(3,:));
    mask(round(ok)) = 1;

    % (3) Find contiguous blob which contains seed
    L = bwlabeln(mask, 6); % integer label matrix of 6-connected blobs
    seedLabel = L(seed(1),seed(2),seed(3));
    if seedLabel==0, return;   end;  % no data so quit
    blob = (L==seedLabel); % binary matrix where blob is 1
    [i1, i2, i3] = ind2sub(size(mask),find(blob>0.5));
    coords = [i1 i2 i3]';

    % (4) Test if the box contains the entire blob
    % (Or is otherwise flush with the bounds of the data)
    inBoundsY=(all(i1>ymin)|ymin==1) & (all(i1<ymax)|ymax==ui.mr.dims(1));
    inBoundsX=(all(i2>xmin)|xmin==1) & (all(i2<xmax)|xmax==ui.mr.dims(2));
    inBoundsZ=(all(i3>zmin)|zmin==1) & (all(i3<zmax)|zmax==ui.mr.dims(3));
    if inBoundsX & inBoundsY & inBoundsZ
        break;
    else
        boxSize = boxSize + stepSize;
    end
end
close(hmsg);

return