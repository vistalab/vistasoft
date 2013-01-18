function ui = mrViewViewMenu(ui);
%
% ui = mrViewViewMenu(ui);
%
% Attaches a view menu to a mrViewer UI.
%
% ras 07/05.
if ~exist('ui', 'var') | isempty(ui),  ui = get(gcf, 'UserData'); end

ui.menus.view = uimenu(ui.fig, 'Label', 'View');

chkVals = {'off' 'on'}; % will be used to set some menus,  below

% navigation panel toggle callback:
cb = 'ui = mrViewGet; ';
cb = [cb 'mrvPanelToggle(ui.panels.nav, gcbo); clear ui; '];
ui.menus.navToggle = uimenu(ui.menus.view, 'Label', 'Navigation Panel', ...
                            'Checked', 'on', 'Separator', 'off', ...
                            'Accelerator', '1', 'Callback', cb);
                        
% ROI panel toggle callback:
cb = 'ui = mrViewGet; ';
cb = [cb 'mrvPanelToggle(ui.panels.roi, gcbo); clear ui; '];                        
ui.menus.infoToggle = uimenu(ui.menus.view, 'Label', 'ROI Panel', ...
                            'Checked', 'off', 'Separator', 'off', ...
                            'Accelerator', '2', 'Callback', cb);    
                        
% grayscale panel toggle callback:
cb = 'ui = mrViewGet; ';
cb = [cb 'mrvPanelToggle(ui.panels.grayscale, gcbo); clear ui; '];                        
ui.menus.grayscaleToggle = uimenu(ui.menus.view, 'Label', 'Grayscale Panel', ...
                            'Checked', 'off', 'Separator', 'off', ...
                            'Accelerator', '3', 'Callback', cb);                              
                        
% info panel toggle callback:
cb = 'ui = mrViewGet; ';
cb = [cb 'mrvPanelToggle(ui.panels.info, gcbo); clear ui; '];                        
ui.menus.infoToggle = uimenu(ui.menus.view, 'Label', 'Info Panel', ...
                            'Checked', 'off', 'Separator', 'off', ...
                            'Accelerator', '4', 'Callback', cb);                          
                
% mesh panel toggle callback:
cb = 'ui = mrViewGet; ';
cb = [cb 'mrvPanelToggle(ui.panels.mesh, gcbo); clear ui; '];                        
ui.menus.infoToggle = uimenu(ui.menus.view, 'Label', 'Mesh Panel', ...
                            'Checked', 'off', 'Separator', 'off', ...
                            'Accelerator', '5', 'Callback', cb);                          
        
                            
%%%%% Dock submenu
ui.menus.dock = uimenu(ui.menus.view, 'Label', 'Dock Panel to Display', ...
                       'Separator', 'on');
% for these submenus, we need to know which panels are currently
% attached to the main figure, and which are not. This subroutine does
% that...
chk = findDockedPanels(ui);
				   
% dock Navigation Panel
cb = 'mrViewDock(gcf, ''nav'', gcbo); ';
ui.menus.navDock = uimenu(ui.menus.dock, 'Label', 'Navigation Panel', ...
                            'Checked', chk{1}, 'Callback', cb);

% dock ROI Panel
cb = 'mrViewDock(gcf, ''roi'', gcbo); ';
ui.menus.roiDock = uimenu(ui.menus.dock, 'Label', 'ROI Panel', ...
                            'Checked', chk{2}, 'Callback', cb);
                        
% dock Grayscale Panel
cb = 'mrViewDock(gcf, ''grayscale'', gcbo); ';
ui.menus.navDock = uimenu(ui.menus.dock, 'Label', 'Grayscale Panel', ...
                            'Checked', chk{3}, 'Callback', cb);
                        
% dock Info Panel
cb = 'mrViewDock(gcf, ''info'', gcbo); ';
ui.menus.infoDock = uimenu(ui.menus.dock, 'Label', 'Info Panel', ...
                            'Checked', chk{4}, 'Callback', cb);
                        
% dock Mesh Panel
cb = 'mrViewDock(gcf, ''mesh'', gcbo); ';
ui.menus.meshDock = uimenu(ui.menus.dock, 'Label', 'Mesh Panel', ...
                            'Checked', chk{5}, 'Callback', cb);                            
                                                  
% dock Overlay Panels
cb = 'mrViewDock(gcf, ''overlay'', gcbo); ';
ui.menus.overlayDock = uimenu(ui.menus.dock, 'Label', 'Overlay Panels', ...
                            'Checked', 'on', 'Callback', cb);                            

% dock Colorbar Panel
cb = 'mrViewDock(gcf, ''colorbar'', gcbo); ';
ui.menus.colorbarDock = uimenu(ui.menus.dock, 'Label', 'Colorbar Panel', ...
                            'Checked', chk{6}, 'Callback', cb);                            
                       
                            
%%%%% overlays submenu
ui.menus.overlays = uimenu(ui.menus.view, 'Label', 'Overlays', ...
                           'Separator', 'on');                            
                            
% new overlay                          
uimenu(ui.menus.overlays, 'Label', 'New Overlay', 'Separator', 'on', ...
       'Accelerator', 'O', 'Callback', 'mrViewAddOverlay;');  

% close overlay                          
uimenu(ui.menus.overlays, 'Label', 'Close Overlay', 'Separator', 'on', ...
       'Accelerator', '9', 'Callback', 'mrViewRemoveOverlay;');  

% text for showing current overlays:
uimenu(ui.menus.overlays, 'Label', 'Show Overlay Panels:', ...
                         'ForegroundColor', 'w', 'Separator', 'on');

%%%%% label submenu
ui.menus.label = uimenu(ui.menus.view, 'Label', 'Label', 'Separator', 'on');

% label directions                           
cb = 'val=umtoggle(gcbo); mrViewSet([], ''labelDirs'', val); mrViewRefresh;';
chk = chkVals{ui.settings.labelDirs+1};
uimenu(ui.menus.label, 'Label', 'Label Directions', ...
       'Checked', chk, 'Separator', 'on', 'Callback', cb);  
   
% label units menu:
cb = 'val=umtoggle(gcbo); mrViewSet([], ''labelAxes'', val); mrViewRefresh;';
chk = chkVals{ui.settings.labelAxes+1};
uimenu(ui.menus.label, 'Label', 'Label Units', ...
       'Checked', chk, 'Separator', 'on', 'Callback', cb);                           
        
% preserve aspect menu:
cb = 'val=umtoggle(gcbo); mrViewSet([], ''eqAspect'', val); mrViewRefresh;';
ui.menus.preserveAspect = uimenu(ui.menus.view, 'Label', 'Preserve Aspect', ...
                               'Checked', 'on', 'Separator', 'on', ...
                               'Callback', cb);
                           
% All slices option
cb = ['nslices = mrViewGet(gcf, ''NumSlices''); ' ...
      'nrows = ceil(sqrt(nslices)); ncols = ceil(nslices/nrows); ' ...
      'mrViewSet(gcf, ''MontageRows'', nrows, ''MontageCols'', ncols); ' ...
      'mrViewSet(gcf, ''Slice'', 1, ''DisplayFormat'', 1); ' ...
	  'mrViewRefresh(gcf); ' ...
      'clear nrows ncols nslices; '];
uimenu(ui.menus.view, 'Label', 'All Slices', ...
       'Separator', 'off', 'Callback', cb);                           

                           
% center of current ROI option
cb = 'mrViewRecenter(get(gcf, ''UserData''), ''roi''); ';
uimenu(ui.menus.view, 'Label', 'Center of Current ROI', ...
       'Separator', 'off', 'Callback', cb);                           

       
% toggle for standard MATLAB figure menus                              
addFigMenuToggle(ui.menus.view);

% refresh options
uimenu(ui.menus.view,  'Label', 'Clean Up Display Panels',  ...
        'Separator',  'on',  'Callback', 'mrViewFixDisplay(gcf);');

uimenu(ui.menus.view,  'Label', 'Refresh',  'Separator',  'off',  ...
       'Accelerator', 'Y',  'Callback', 'mrViewRefresh;');


return
% /--------------------------------------------------------------/ %



% /--------------------------------------------------------------/ %
function chk = findDockedPanels(ui);
% Checkes whether each panel in a mrViewer UI is attached ("docked")
% to the main figure. Returns a cell array of 'on' for attached 
% and 'off' for not attached (these are useful for setting the
% 'Checked' property of the dock submenus).
panels = [ui.panels.nav ui.panels.roi ui.panels.grayscale ...
		  ui.panels.info ui.panels.mesh ui.panels.colorbar];
for i = 1:6
	if get(panels(i), 'Parent')==ui.fig
		chk{i} = 'on';
	else
		chck{i} = 'off';
	end
end

return
