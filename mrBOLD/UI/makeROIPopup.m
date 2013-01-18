function view = makeROIPopup(view)
% 
% view = makeROIPopup(view)
%
% Make a popup window for selecting the current ROI.

% ras 05/06: updated so that it doesn't redraw everything
% (previous use of the refreshScreen(view,0) flag was still a bit slow --
% you would always redraw ROIs, even when this was time-consuming and 
% unnecessary.)

% callback: 
% n = get(gcbo, 'Value'); 
% view = selectROI(view, n);
% view = refreshScreen(view);
cb = ['n = get(gcbo, ''Value''); ' ...
      sprintf('%s = selectROI(%s, n);', view.name, view.name) ...
      sprintf('%s = refreshScreen(%s); ', view.name, view.name)];
view = makePopup(view, 'ROI', 'none', [.85 .325 .15 .05], cb);

return
