function view = restrictAllROIsfromMenu(view)
%
% view = restrictAllROIsfromMenu(view)
%
% Restricts ROI according to cothresh and phWindow.
% Uses curScan as the reference scan.

% read cothresh from the slide bar
cothresh = getCothresh(view);
phWindow = getPhWindow(view);
mapWindow = getMapWindow(view);
curScan = getCurScan(view);

view = restrictAllROIs(view,curScan,cothresh,phWindow,mapWindow);

