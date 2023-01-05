function view = restrictAllROIs(view,refScan,cothresh,phWindow,mapWindow)
%
% view = restrictAllROIs(view,refScan,cothresh,phWindow,mapWindow)
%
% Restricts all ROIs according to cothresh, phWindow, and mapWindow.

for r=1:length(view.ROIs)
   view = restrictROI(view,refScan,cothresh,phWindow,mapWindow,r);
end

% Can't undo these modifications
view.prevCoords = [];