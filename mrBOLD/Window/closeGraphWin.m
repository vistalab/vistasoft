function closeGraphWin
%
% closeGraphWin
%
% Closes the current graphWin.  Sets the global GRAPHWIN=0
%
% djh, 3/3/98

global GRAPHWIN

if GRAPHWIN
  if (GRAPHWIN == get(0,'CurrentFigure'))
    GRAPHWIN=0; 
  end
end 

delete(get(0,'CurrentFigure'));


