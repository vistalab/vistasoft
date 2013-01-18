function myWarnDlg(warnstr)
% Calls Matlab's warndlg but leaves the CurrentFigure selected.
%
% myWarnDlg(warnstr)
%
% djh, 7/98

h = get(0,'CurrentFigure');
warndlg(warnstr);
% set(0,'CurrentFigure',h);

return;
