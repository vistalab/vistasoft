function newGraphWin
%
% newGraphWin
%
% Opens a new window, sets the global GRAPHWIN to be the handle
% to the new window.  Sets closeRequestFcn to clean up properly
% (by calling closeGraphWin) when the window is closed.
%
% djh, 3/3/98
global GRAPHWIN

GRAPHWIN=figure;
set(gcf,'CloseRequestFcn','closeGraphWin');
