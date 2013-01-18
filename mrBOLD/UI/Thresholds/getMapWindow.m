function mapWindow = getMapWindow(view)
%
% mapWindow = getMapWindow(<view=current view>)
%
% Gets mapWindow values from mapWindow sliders (non-hidden views)
% or from the view.settings.mapWin field (hidden views). 
%
% ras, 06/06.
if nargin<1, view = getCurView; end

if isequal(view.name, 'hidden')
    if checkfields(view, 'settings', 'mapWin')
        mapWindow = view.settings.mapWin;
    else
        if length(view.map) >= view.curScan
            map = view.map{view.curScan};
        else
            map = [];
        end
        mapWindow = [min(map(:)) max(map(:))];
%         if isempty(mapWindow)
%             warning('Map Window is empty.')
%         end
    end
else
    mapWindow = [get(view.ui.mapWinMin.sliderHandle,'Value'),...
        get(view.ui.mapWinMax.sliderHandle,'Value')];
end

return
