function view = mapNameDialog(view);
% Dialog to edit a mrVista parameter map name, units, and clip mode.
% 
% view = mapNameDialog(view);
%
%
% ras, 06/2007.
if notDefined('view'),	view = getCurView;		end

%% get default params
mapName = viewGet(view, 'MapName');
mapUnits = viewGet(view, 'MapUnits');
mapClip = viewGet(view, 'MapClip');


%% build the dialog structure
dlg(1).fieldName = 'mapName';
dlg(1).style = 'edit';
dlg(1).string = 'Parameter Map Name?';
dlg(1).value = mapName;

dlg(2).fieldName = 'mapUnits';
dlg(2).style = 'edit';
dlg(2).string = 'Parameter Map Units?';
dlg(2).value = mapUnits;

dlg(3).fieldName = 'mapClip';
dlg(3).style = 'edit';
dlg(3).string = 'Parameter Map Clip Mode (''auto'' or [min max])?';
dlg(3).value = num2str(mapClip);

%% put up the dialog, get response
resp = generalDialog(dlg, mfilename);


%% parse the response
view = viewSet(view, 'MapName', resp.mapName);
view = viewSet(view, 'MapUnits', resp.mapUnits);
view = viewSet(view, 'MapClip', str2num(resp.mapClip));

return
