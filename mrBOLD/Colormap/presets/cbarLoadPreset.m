function cbar = cbarLoadPreset(name, viewer, o);
% Load a preset colorbar, and set it as the colorbar for a mrViewer
% overlay.
%
%  cbar = cbarLoadPreset([name=prompt], [viewer=gcf], [o=1]);
%
% name is the name (filename) of a saved colorbar. viewer is a handle to 
% a mrViewer UI. o is the overlay index for the cbar.
%
% ras, 02/24/07.
if notDefined('name')
	name = inputdlg({'Colorbar Name?'}, 'Load a Preset Cbar', 1, {''});
	name = name{1};
end

if notDefined('viewer'),	viewer = gcf;		end
if notDefined('o'),			o = 1;				end

presetsDir = fileparts(which(mfilename));

cbarPath = fullfile(presetsDir, [name '.mat']);
if ~exist(cbarPath, 'file')
	what(presetsDir)
	error(sprintf('Preset %s not found.', name))
end

cbar = cbarLoad(cbarPath);

mrViewSetOverlay(viewer, 'cbar', cbar, o);

return
