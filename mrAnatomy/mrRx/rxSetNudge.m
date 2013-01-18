function rxSetNudge(obj);
%  rxSetNudge(obj):
%
% For mrRx, set the first slider step parameter
% (The 'nudge' when you click on the small arrows
% at the edge of the slider).
% 
% obj is a handle to the callback object, since
% this is a callback.
%
% ras 02/05.

% figure out which object called it -- the edit or the slider
style = get(obj,'Style');
if isequal(style,'edit')
    nudge = str2num(get(obj,'String'));
else
    nudge = get(obj,'Value');
end

% update the edit/slider controls to 
% reflect the same value:
rxSetSlider(obj,nudge);

% compute new values for (1) nudge arrows and
% (2) stepping by clicking on slider:
vals(1) = nudge / 180;
vals(2) = nudge / 30;

% get rx struct
cfig = findobj('Tag','rxControlFig');
rx = get(cfig,'UserData');

% get handles to relevant sliders
handles = [...
           rx.ui.axiRot.sliderHandle ...
           rx.ui.corRot.sliderHandle ...
           rx.ui.sagRot.sliderHandle ...
           rx.ui.axiTrans.sliderHandle ...
           rx.ui.corTrans.sliderHandle ...
           rx.ui.sagTrans.sliderHandle ...
       ];
 
% set slider step for each control   
for i = 1:length(handles)
    set(handles(i),'SliderStep',vals);
end

return
