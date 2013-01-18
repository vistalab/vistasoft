function closeSSWindow()
%
% closeSSWindow()
%
% clears SS while closing the corresponding window.
%
% rmk, 9/17/98

% Clear the variable
clear global SS

% Delete the window
delete(get(0,'CurrentFigure'));

return