function phWindow = getPhWindow(view)
%
% phWindow = getPhWindow(<view = current view>)
%
% Gets phWindow values from phWindow sliders (non-hidden views)
% or from the view.settings.phWin field (hidden views). If can't
% find either, defaults to [0 2*pi].
%
% ras 06/06.
if nargin<1, view = getCurView; end

if isequal(view.name, 'hidden')
    if checkfields(view, 'settings', 'phWin')
        phWindow = view.settings.phWin;
    else
        phWindow = [0 2*pi];
    end
else
    phWindow = [get(view.ui.phWinMin.sliderHandle,'Value'),...
        get(view.ui.phWinMax.sliderHandle,'Value')];
end

return
