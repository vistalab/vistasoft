function view = setBrightness(view,val);
%
% view = setBrightness(view,[val]);
%
% Set the brightness of a view, by
% changing the color maps in each 
% view mode. Only those parts which
% are used for the anatomical underlay
% image (the first 1:numGrays entries)
% are brightened -- the overlays are 
% unchanged.
%
% Val can range from 0 to 1. If omitted,
% it is read off of the view's brightness
% slider (so hopefully, in these circumstances,
% it has one).
%
%
% ras 01/05.
if notDefined('val')
    val = get(view.ui.brightness.sliderHandle,'Value');
end

setSlider(view,view.ui.brightness,val);

numGrays = view.ui.mapMode.numGrays;
cmap = gray(numGrays);

delta = 2*val - 1;
if delta ~= 0
    cmap = brighten(cmap,delta);
end

view.ui.anatMode.cmap = cmap;
view.ui.ampMode.cmap(1:numGrays,:) = cmap;
view.ui.phMode.cmap(1:numGrays,:) = cmap;
view.ui.coMode.cmap(1:numGrays,:) = cmap;
view.ui.mapMode.cmap(1:numGrays,:) = cmap;

view = refreshScreen(view, 1);

return
