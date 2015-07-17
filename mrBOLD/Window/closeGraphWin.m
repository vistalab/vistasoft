function closeGraphWin
%
% closeGraphWin
%
% Closes the current graphWin.  Sets the global GRAPHWIN=0
%
% djh, 3/3/98

global GRAPHWIN

curFigure = get(0,'CurrentFigure');

if isnumeric(GRAPHWIN)
  if isequal(GRAPHWIN, curFigure)
    GRAPHWIN=0; d
  end
end 

delete(curFigure);


