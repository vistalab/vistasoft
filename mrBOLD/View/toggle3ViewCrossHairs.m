function view = toggle3ViewCrossHairs(view,obj);
% view = toggle3ViewCrossHairs(view,obj);
%
% For volume3views in mrLoadRet (rory's version):
%  switches the state of the crosshair display option. 
%
% ras 09/03
% ras, 01/04: now works for uimenu checks or uicontrol checkbox values

if isprop(obj,'Checked')  % menu item
	state = get(obj, 'Checked');
	
	if isequal(state, 'on')
        set(obj, 'Checked', 'off')
        view.ui.crosshairs = 0;
	else
        set(obj, 'Checked', 'on')
        view.ui.crosshairs = 1;
	end
elseif isprop(obj,'Value')   % checkbox
    view.ui.crosshairs = get(obj, 'Value');
else
    % exit quietly
    return
end

view.loc = getLocFromUI(view);

if isequal(view.refreshFn, 'volume3View')
    view = renderCrosshairs(view, view.ui.crosshairs);
% 	view = volume3View(view, [], view.ui.crosshairs);
end

return
% /----------------------------------------------------------------/ %




% /----------------------------------------------------------------/ %
function loc = getLocFromUI(view);
% reads off the axi,cor, and sag UI edit fields to
% get the current view location.
loc(1) = str2num(get(view.ui.sliceNumFields(1),'String'));
loc(2) = str2num(get(view.ui.sliceNumFields(2),'String'));
loc(3) = str2num(get(view.ui.sliceNumFields(3),'String'));
return
