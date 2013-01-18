function status = cbarSavePreset(cbar, name);
% Save a colorbar as a preset, to make readily available for all future
% viewers.
%
% status = cbarSavePreset(cbar, [name=prompt]);
%
% This is a particular manifestation of my laziness:
% The saving and loading of color bars works well, but rather
% than remember and navigate to a file location for frequently-used
% cbars, I want to save a copy with my local mrVista2 repository, 
% and have it handy whenever I have a mrViewer UI open.
%
% This will call cbarSave, but save the colorbar in the local
% mrVista2 directory (in ui/cmap/presets/, where this code resides).
% The saved colorbar shouldn't be checked in, but when a new overlay
% is opened in mrViewer (mrViewColorbarOpen), it will look for .mat
% files in that directory, and list their names in the UI Context Menu
% for the colorbar, so it can be quickly set to the preset.
%
%
% ras, 02/24/07
if nargin<1, error('Not enough input arguments.'); end

if notDefined('name')
	name = inputdlg({'Colorbar name?'}, 'Save Preset Cbar', 1, {''});
	name = name{1};
end

presetDir = fileparts(which(mfilename));

status = cbarSave(cbar, fullfile(presetDir, name));

% attach context menus to any overlays in an open mrViewer
try
	ui = mrViewGet;
catch
	ui = [];
end
if ~isempty(ui)
	for o = 1:length(ui.overlays)
		if length(ui.controls.cbarContextMenu)==3
			sep = 'on';
		else
			sep = 'off';
		end
		
		cb = sprintf('cbarLoadPreset(''%s'', %i, %i); ', name, ui.fig, o);
		uimenu(ui.controls.cbarContextMenu, 'Label', name, ...
			   'Separator', sep, 'Callback', cb);
	end
end

return
