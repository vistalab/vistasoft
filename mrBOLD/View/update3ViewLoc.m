function view = update3ViewLoc(view);
% view = update3ViewLoc(view);
%
% Updates the location of a volume 3-view window
% based on the settings of the slice view/orientation
% fields at the bottom of the window.

% 03/07/03 by ras

axiSlice=str2num(get(view.ui.sliceNumFields(1),'String'));
corSlice=str2num(get(view.ui.sliceNumFields(2),'String'));
sagSlice=str2num(get(view.ui.sliceNumFields(3),'String'));

loc = [axiSlice corSlice sagSlice];

view = refreshScreen(view,loc);

return