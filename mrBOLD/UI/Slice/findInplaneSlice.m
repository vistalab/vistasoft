function curSlice = findInplaneSlice(view)%%  curSlice = findInplaneSlice(view)%% AUTHOR:  Wandell% DATE:    12.08.00% PURPOSE: Find the current slice from the INPLANE window.%   This window may encode the slice either in the clicked button%   or by a numerical entry and +/- buttons.  So, we switch between%   the alternatives here.
if ~strcmp(view.viewType,'Inplane')   error('findInplaneSlice:  Call with INPLANE view only!');end
curSlice = get(view.ui.slice.sliderHandle,'val');
return;


