function h = cbarPresetMenus(par, viewer);
% Attach menus for quickly loading colorbar presets to a parent
% menu/figure.
% 
% h = cbarPresetMenus(parent, [viewer=gcf]);
%
% This code scans the ui/cmap/presets/ directory for .mat files
% (which should contain saved color bars -- see cbarSavePreset)
% and produces one uimenu for each one, whose callback will 
% quickly load the saved colorbar into a mrViewer (using
% mrViewSetOverlay). The 'viewer' argument should be
% a handle to a mrViewer UI for loading the cbar. 
%
% ras, 02/24/07.
if nargin < 1, error('Not enough input args.'); end

if notDefined('o'),			o = 1;			end
if notDefined('viewer'),	viewer = gcf;	end

presetsDir = fileparts(which(mfilename));
w = what(presetsDir);

if isempty(w.mat), return; end  % no presets saved

for i = 1:length(w.mat)
	[p, f, ext] = fileparts(w.mat{i});
	if i==1, sep = 'on'; else, sep = 'off'; end
	
    % Fails with new version of figure handle as a struct.  To fix.
	cb = sprintf('cbarLoadPreset(''%s'', %i, get(gca, ''UserData'')); ', f, ...
				 viewer);
	
	h(i) = uimenu('Parent', par, 'Label', f, 'Separator', sep, ...
			      'Callback', cb);
				  
end

return


