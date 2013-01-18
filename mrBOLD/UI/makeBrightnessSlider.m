function view = makeBrightnessSlider(view,pos);
%
% view = makeBrightnessSlider(view,pos);
%
% Make a slider (+ edit field and label) to
% adjust image brightness, in the specified 
% position relative to the figure's lower-left
% corner (Normalized units).
%
%
% ras 01/05.
view = makeSlider(view, 'brightness', [0 1], pos);

% set slider callback
cbstr = sprintf('%s = setBrightness(%s);',view.name,view.name);
set(view.ui.brightness.sliderHandle,'Callback',cbstr);

% set edit callback
cbstr = ['val = str2num(get(gcbo, ''String'')); ' ...
         sprintf('%s = setBrightness(%s, val);',view.name, view.name)];
set(view.ui.brightness.labelHandle,'Callback',cbstr);

return
