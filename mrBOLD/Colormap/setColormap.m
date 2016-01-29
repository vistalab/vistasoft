function mode = setColormap(mode,cmapFn)
%
%  mode = setColormap(mode,cmapFn)
%
% Author:  My guess, Dave Heeger
% Purpose:
%   If you call a color map function, say hsv,
%   this routine builds a color map entry for that mode using the hsv function.
%

numGrays  = mode.numGrays;
numColors = mode.numColors;

% mode.cmap=cmapFn(numGrays,numColors);
eval(['mode.cmap=',cmapFn,'(numGrays,numColors);']);
mode.name = cmapFn;

return
