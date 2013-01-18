function ui = mrViewPlotMenu(ui);
%
% ui = mrViewPlotMenu(ui);
%
% Attaches a plot menu to a mrViewer UI.
%
% ras 07/05.
if ~exist('ui', 'var') | isempty(ui),  ui = get(gcf, 'UserData'); end

ui.menus.plot = uimenu(ui.fig, 'Label', 'Plot');

ui.menus.tcui = uimenu(ui.menus.plot, 'Label', 'Time Course UI', ...
                        'Accelerator', 'G', 'Callback', 'mrViewTimeCourse; ');

ui.menus.mvui = uimenu(ui.menus.plot, 'Label', 'Multi Voxel UI', ...
                        'Accelerator', 'M', 'Callback', 'mrViewVoxelData; ');
                    
% options for IMCLICK tool
uimenu(ui.menus.plot, 'Label', 'Imclick', 'Separator', 'on', ...
		'Callback', 'imclick;');
	
cb = ['ans = inputdlg({''Size of imclick window?''}, ''imclick'', 1, {''1''}); ' ...
	  'imclick( str2num(ans{1}) );'];	
uimenu(ui.menus.plot, 'Label', 'Imclick (set size)', 'Callback', cb);	
					
return                        
                    