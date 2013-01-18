function vw = restrictROIfromMenu(vw)
%
% vw = restrictROIfromMenu(vw)
%
% Restricts ROI according to cothresh and phWindow.
% Uses curScan as the reference scan.
%
%   1/21/2010, JW: switch threshold calls to viewGet's

% read cothresh from the slide bar
cothresh    = viewGet(vw, 'cothresh');
phWindow    = viewGet(vw, 'phasewindow');
mapWindow   = viewGet(vw, 'mapwindow');
curScan     = viewGet(vw, 'curscan');

vw = restrictROI(vw,curScan,cothresh,phWindow,mapWindow);

