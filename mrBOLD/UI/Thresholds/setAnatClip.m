function setAnatClip(view,anatClip)
%
% setAnatClip(view,anatClip)
%
% Sets anatClip slider values

% ras 03/05 -- in adding brightness/contrast
% sliders, I also want to make the views back-
% compatible w/ calls to this function
if isfield(view.ui,'anatMin')
	setSlider(view,view.ui.anatMin,anatClip(1)); 
	setSlider(view,view.ui.anatMax,anatClip(2));
elseif isfield(view.ui,'contrast')
    contrast = diff(anatClip);
    setSlider(view,view.ui.contrast,contrast);
end

return
