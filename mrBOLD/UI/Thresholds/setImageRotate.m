function setImageRotate(view, imageRotate)
%
% setImageRotate(view, imageRotate)
%
% Sets imageRotate slider values.
if isequal(view.name, 'hidden')
	% instead of a handle to the slider, the ImageRotate field will
	% directly store the rotations for hidden views:
	view.ui.ImageRotate = imageRotate;
else
	% non-hidden view: view.ui.ImageRotate should be a slider struct
	setSlider(view,view.ui.ImageRotate, imageRotate); 
end

return
