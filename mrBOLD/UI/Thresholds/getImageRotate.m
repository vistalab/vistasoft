function currentVal=getImageRotate(view)
%
% currentVal=getImageRotate(view)
%
% Returns the value of the image rotate slider in radians
if isequal(view.name, 'hidden')
	% instead of a handle to the slider, the ImageRotate field will
	% directly store the rotations for hidden views:
	currentVal = view.ui.ImageRotate;
else
	% non-hidden view: view.ui.ImageRotate should be a slider struct
	currentVal = get(view.ui.ImageRotate.sliderHandle, 'Value'); 
end

return


