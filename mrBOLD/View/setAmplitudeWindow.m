function view = SetAmplitudeWindow(view)
%
%       view = SetAmplitudeWindow(view)
%
% Sets the map-sliders to correspond to a normalized [0 1] range for amplitude mode.
%
% ress, 6/03

if isfield(view, 'ui')
    minVal = 0;
    maxVal = 1;
    view = resetSlider(view,view.ui.mapWinMin, minVal, maxVal, minVal);
    view = resetSlider(view,view.ui.mapWinMax, minVal, maxVal, maxVal);
end

return;
