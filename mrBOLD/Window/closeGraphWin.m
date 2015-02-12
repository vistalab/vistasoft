function closeGraphWin
%
% closeGraphWin
%
% Closes the current graphWin.  Sets the global GRAPHWIN=0
%
% djh, 3/3/98

global GRAPHWIN

curFigure = get(0,'CurrentFigure');

if isstruct(curFigure)
    curFigure = get(curFigure, 'Number');
end

if GRAPHWIN
  if (GRAPHWIN == curFigure)
    GRAPHWIN=0; 
  end
end 

delete(curFigure);


