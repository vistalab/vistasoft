function GRAPHWIN = selectGraphWin
%
% GRAPHWIN = selectGraphWin
%
% Checks the global GRAPHWIN.  If nonzero, selects it.
% Otherwise, calls newGraphWin to make a new one.
%
% djh, 3/3/98

global GRAPHWIN

if (isempty(GRAPHWIN) | GRAPHWIN==0)
  newGraphWin;
else
  set(0,'CurrentFigure',GRAPHWIN);
end

% Clear the figure
clf
return;