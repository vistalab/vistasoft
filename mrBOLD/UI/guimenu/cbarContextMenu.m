function h = cbarContextMenu(view);
% Attach a UI context menu to a colorbar in a mrVista view window.
%
% h = cbarContextMenu(view);
%
% This creates a uicontext menu with several child menus which allow the
% user to quickly set the colormap, edit the colormap, and set some color 
% limits, regardless of the current view mode. It also includes some
% shortcuts to useful colorbars (wheel colorbar), as appropriate.
%
% ras, 11/2007.
if notDefined('view'),	view = getCurView;		end

mode = viewGet(view, 'displayMode');

%% create the top context menu
h = uicontextmenu;

%% copy colorbar to clipboard
cb = sprintf('cbarCopy(%s, ''clipboard'');',  view.name);
uimenu(h,  'Label',  'Copy Color bar to Clipboard',  ...
        'Separator',  'off',  'Callback',  cb);

%% create edit cmap, edit color limits (clip mode) options
cb = sprintf('%s = refreshScreen( rotateCmap(%s) )', ...
			 view.name, view.name);
uimenu(h, 'Label', 'Edit...', 'Separator', 'off', 'Callback', cb);

% edit clip mode -- there's a nicer dialog for map mode
if isequal(mode, 'map')
	cb = sprintf('%s = viewSet(%s, ''MapName'', ''Dialog'');', ...
					view.name, view.name);
else
	cb = sprintf('%s = setClipMode(%s, ''%s'');', ...
			 view.name, view.name, mode);
end
uimenu(h, 'Label', 'Clip Mode...', 'Callback', cb);


% add a menu to set the colorwheel params
if checkfields(view, 'ui', 'displayMode') & isequal(view.ui.displayMode, 'ph')
	cb = sprintf('retinoSetParams(%s); ',  view.name);
	uimenu(h, 'Label', 'Polar Angle Color Wheel', 'Callback', cb, 'Separator', 'on');
end

%% create submenus to select some predefined cmaps
cmaps = mrvColorMaps;
cmaps = cmaps([1:8 18:24 26 27]);  % only want a few more common ones

for n = 1:length(cmaps)
	cb = sprintf('%s = viewSet(%s, ''CurCmap'', mrvColorMaps(''%s'', 128)); ', ...
				 view.name, view.name, cmaps{n});
	cb = [cb 'refreshScreen(' view.name ');'];
	
	if n==1
		sep = 'on';
	else
		sep = 'off';
	end
	uimenu(h, 'Label', cmaps{n}, 'Callback', cb, 'Separator', sep);
end

% for map mode, also allow a bicolor cmap
if isequal(mode, 'map')
	cb = sprintf('%s = refreshScreen( bicolorCmap(%s), 1 ); ', view.name, view.name);
	uimenu(h, 'Label', 'Winter + Autumn', 'Callback', cb);
end

%% if the conditions are appropriate, set shortcuts to left/right RGB polar
%% angle maps
if isequal(mode, 'ph')
	p = retinoGetParams(view);
	
	if ~isempty(p) & isequal(p.type, 'polar_angle')
		cb = sprintf('%s = refreshScreen( cmapPolarAngleRGB(%s, ''left'') ); ', ...
					view.name, view.name);
		uimenu(h, 'Label', 'Left Visual Field Colorwheel', ...
			   'Separator', 'on', 'Callback', cb);
		   
		cb = sprintf('%s = refreshScreen( cmapPolarAngleRGB(%s, ''right'') ); ', ...
					view.name, view.name);
		uimenu(h, 'Label', 'Right Visual Field Colorwheel', ...
			   'Separator', 'off', 'Callback', cb);		   
		   
		   
		cb = sprintf('%s = refreshScreen( cmapPolarAngleRGB(%s, ''both'') ); ', ...
					view.name, view.name);
		uimenu(h, 'Label', 'Both Visual Fields Colorwheel', ...
			   'Separator', 'off', 'Callback', cb);		   		   
	end
end

return

