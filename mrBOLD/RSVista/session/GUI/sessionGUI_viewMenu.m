function GUI = sessionGUI_viewMenu(GUI);
% Attach a View Menu to the session GUI figure, including
% callbacks for all view-related operations.
%
% GUI = sessionGUI_viewMenu(GUI);
%
%
% ras, 07/06.
GUI.menus.view = uimenu('Label', 'View', 'Separator', 'on');

% add an option to view inplanes
uimenu(GUI.menus.view, 'Label', 'New Viewer (Inplane)', 'Separator', 'off', ...
       'Callback', 'sessionGUI_viewInplane; ');
   
% add an option to view volume
uimenu(GUI.menus.view, 'Label', 'New Viewer (Volume)', 'Separator', 'off', ...
       'Callback', 'sessionGUI_viewVolume; ');
       
% add an option to view a new viewer on a user-selected MR file
uimenu(GUI.menus.view, 'Label', 'New Viewer (choose underlay)', ...
       'Separator', 'off', 'Callback', 'sessionGUI_viewMR; ');
       
% add submenu for panel toggles
submenu_panels(GUI.menus.view);

       
% add options to open a Time Course UI for the current ROI
uimenu(GUI.menus.view, 'Label', 'Time Course UI (selected scans)',...
       'Separator', 'on', 'Accelerator', '6', ...
       'Callback', 'sessionGUI_plotTimeCourse([], guiGet(''scans'')); ');
uimenu(GUI.menus.view, 'Label', 'Time Course UI (scan group)',...
       'Separator', 'off', 'Accelerator', 'G', ...
       'Callback', 'sessionGUI_plotTimeCourse; ');

% add options to open a Multi Voxel UI for the current ROI
uimenu(GUI.menus.view, 'Label', 'Multi Voxel UI (selected scans)',...
       'Separator', 'on', 'Accelerator', '7', ...
       'Callback', 'sessionGUI_plotVoxelData([], guiGet(''scans'')); ');
uimenu(GUI.menus.view, 'Label', 'Multi Voxel UI (scan group)',...
       'Separator', 'off', 'Accelerator', 'M', ...
       'Callback', 'sessionGUI_plotVoxelData; ');

% Attach submenus
submenu_movie(GUI.menus.view);
   
       
% Toggle figure menus:
addFigMenuToggle(GUI.menus.view);

return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function h = submenu_movie(parent);
% attach a submenu for operations related to viewing movies of the
% time series for the specified scans.
h = uimenu(parent, 'Label', 'Functionals Movie', 'Separator', 'on');


% Movie UI options
% (These will need to be updated as I figure out how to infer from 
% a general mrViewer what slice to plot, and add support for multi-slices)
cb = ['INPLANE{1}.tSeriesSlice = guiGet(''slice''); ' ...
      'INPLANE{1}.ui.movie = tSeriesMovie(INPLANE{1}, guiGet(''scans'')); '];
uimenu(h, 'Label', 'Movie UI (cur slice)', 'Separator', 'off', ...
          'Accelerator', '1', 'Callback', cb);

cb = ['INPLANE{1}.tSeriesSlice = guiGet(''slice''); ' ...
      'INPLANE{1}.ui.movie = tSeriesMovie(INPLANE{1},guiGet(''scans''),1); '];
uimenu(h, 'Label', 'Movie UI (cur slice, on anatomy)', 'Separator', 'off', ...
          'Callback', cb);

cb = ['INPLANE{1}.tSeriesSlice = guiGet(''slice''); ' ...
      'INPLANE{1}.ui.movie = tSeriesMovie(INPLANE{1}, guiGet(''scans''), ' ...
                                          '0, ''compareFrames'', 1); '];
uimenu(h, 'Label', 'Movie UI (cur slice, compare to frame 1)', ...
          'Accelerator', '2', 'Separator', 'off', 'Callback', cb);
      
cb = ['INPLANE{1}.tSeriesSlice = guiGet(''slice''); ' ...
      'INPLANE{1} = callTSeriesMovie(INPLANE{1}); '];
uimenu(h, 'Label', 'Movie UI (set params)',  'Separator', 'off', ...
          'Accelerator', '3', 'Callback', cb);
      

% Older Movie options:
% Still useful, as they allow multi-slice and don't require java
cb = 'INPLANE{1} = makeTSeriesMovie(INPLANE{1}, [], guiGet(''slice'')); ';
uimenu(h, 'Label', 'Make MATLAB movie (cur slice, cur scan)', ...
          'Separator', 'on', 'Callback', cb);

cb = 'INPLANE{1} = makeTSeriesMovie(INPLANE{1}, [], guiGet(''slice''), 1); ';
uimenu(h, 'Label', 'Make MATLAB movie (cur slice, cur scan, w/ anat)', ...
          'Separator', 'off', 'Callback', cb);
      
cb = 'INPLANE{1} = makeTSeriesMovie(INPLANE{1}, [], 0, 1); ';
uimenu(h, 'Label', 'Make MATLAB movie (all slices, cur scan)', ...
          'Separator', 'off', 'Callback', cb);

cb = 'INPLANE{1} = makeTSeriesMovie(INPLANE{1}, [], 0, 1); ';
uimenu(h, 'Label', 'Make MATLAB movie (all slices, cur scan, w/ anat)', ...
          'Separator', 'off', 'Callback', cb);
      
uimenu(h, 'Label', 'Re-show MATLAB movie', 'Separator', 'off', ...
          'Callback', 'showTSeriesMovie(INPLANE{1}); ');

return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function h = submenu_panels(parent);
% attach a submenu with toggles for the GUI's panels.
h = uimenu(parent, 'Label', 'Panels', 'Separator', 'on');

uimenu(h, 'Label', 'Shortcut Panel', 'Separator', 'off', ...
          'Callback', 'mrvPanelToggle(GUI.panels.shortcut, gcbo);');

uimenu(h, 'Label', 'Status Panel', 'Separator', 'off', ...
          'Callback', 'mrvPanelToggle(GUI.panels.status, gcbo);');

return
