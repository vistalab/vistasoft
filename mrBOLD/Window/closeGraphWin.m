function closeGraphWin
%
% closeGraphWin
%
% Closes the current graphWin.  Sets the global GRAPHWIN=0
%
% djh, 3/3/98
% arw, 06/15/15 Modify to cope with graphic handle behavior in R2014b onwards

global GRAPHWIN

if ~isempty(GRAPHWIN)
  if (GRAPHWIN == get(0,'CurrentFigure'))
    GRAPHWIN=0; 
  end
end 

delete(get(0,'CurrentFigure'));



