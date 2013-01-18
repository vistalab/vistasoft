function view = setPhWindow(view, phWindow)
%
% view = setPhWindow(view, phWindow)
%
% Sets phWindow values in phWindow sliders (non-hidden views)
% or in the view.settings.phWin field (hidden views). If can't
% find either, defaults to [0 2*pi].
%
% ras 08/07.
if nargin<1, view = getCurView; end

if isequal(view.name, 'hidden')
	% hidden view: set in a special settings field
	view.settings.phWin = phWindow;

else	
	% non-hidden view: set in UI
	setSlider(view, view.ui.phWinMin, phWindow(1)); 
	setSlider(view, view.ui.phWinMax, phWindow(2));

end

return
