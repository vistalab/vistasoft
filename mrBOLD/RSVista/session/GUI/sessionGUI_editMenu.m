function GUI = sessionGUI_editMenu(GUI);
% Attach an Edit Menu to the session GUI figure, including
% callbacks for all editing-related operations.
%
% GUI = sessionGUI_editMenu(GUI);
%
%
% ras, 07/06.
GUI.menus.edit = uimenu('Label', 'Edit', 'Separator', 'on');

% add option to edit mrSESSION
cb = '[mrSESSION ok] = EditSession(mrSESSION,0); if ok, saveSession(1); end; ';
uimenu(GUI.menus.edit, 'Label', 'Session', 'Separator', 'off', 'Callback', cb);

% add option to edit alignment for this session
% Edit alignment(using mrRx):
uimenu(GUI.menus.edit, 'Label', 'Edit/View Alignment...', 'Separator', 'off', ...
      'Callback', 'rxAlign; ');

% Attach submenus
submenu_dataType(GUI.menus.edit);
submenu_eventRelated(GUI.menus.edit);
submenu_retinotopy(GUI.menus.edit);
submenu_segmentation(GUI.menus.edit);

return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function h = submenu_dataType(parent);
% attach a submenu for Study-related operations.
h = uimenu(parent, 'Label', 'Data Type', 'Separator', 'off');

cb = ['dt = GUI.settings.dataType; ' ...
      '[dataTYPES(dt) ok] = EditDataType(dataTYPES(dt)); ' ...
      'if ok, saveSession(1); end; clear dt; ']; 
uimenu(h, 'Label', 'Edit Data Type Parameters', 'Separator', 'off', ...
          'Callback', cb);

cb = 'removeDataType(dataTYPES(GUI.settings.dataType).name);';
uimenu(h, 'Label', 'Delete Current Data Type', 'Separator', 'on', ...
          'Callback', cb);

cb = 'duplicateDataType(INPLANE{1});';
uimenu(h, 'Label', 'Duplicate Current Data Type', ...
        'Separator', 'off', 'Callback', cb);

cb = 'groupScans(INPLANE{1});';
uimenu(h, 'Label', 'Group Scans Into Data Type', ...
        'Separator', 'off', 'Callback', cb);      
          
return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function h = submenu_eventRelated(parent);
% attach a submenu for editing event-related settings.
h = uimenu(parent, 'Label', 'Event-Related', 'Separator', 'off');

uimenu(h, 'Label', 'Group Scans Into Scan Group', 'Separator', 'off', ...
          'Callback', 'er_groupScans(INPLANE{1}, guiGet(''scans''), 2); ');

uimenu(h, 'Label', 'Assign Scan Group to Selected Scan', 'Separator', 'off', ...
          'Callback', 'er_groupScans(INPLANE{1}, guiGet(''scans''), 1); ');

uimenu(h, 'Label', 'Assign .par files to Scans', 'Separator', 'off', ...
          'Callback', 'er_assignParfilesToScans(INPLANE{1}, guiGet(''scans'')); ');          

uimenu(h, 'Label', 'Show parfiles/scan group', 'Separator', 'off', ...
          'Callback', 'er_displayParfiles(INPLANE{1}); ');          
          
cb = ['params = er_getParams(INPLANE{1}); ' ...
      'params = er_editParams(params); ' ...
	  'er_setParams(INPLANE{1}, params); '];
uimenu(h, 'Label', 'Edit Event-Related Parameters (scan group)', ...
          'Separator', 'off', 'Callback', cb);

return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function h = submenu_retinotopy(parent);
% attach a submenu for operations related to simple mapping of 
% traveling-wave analysis results to retinotopic parameters.
% (This is not the full Retinotopy Model Serge created; just parameters
% that will convert corAnal phase to estimated physical units.)
% TO DO: add functionality to the analysis menu to convert corAnal files
% into polar angle and eccentricity parameter maps.
h = uimenu(parent, 'Label', 'Retinotopy', 'Separator', 'off');

uimenu(h, 'Label', 'Set Retinotopy Params (selected scans)', ...
          'Callback', 'retinoSetParams(INPLANE{1}, guiGet(''scans'')); ');

cb = 'retinoSetParams(INPLANE{1}, [], guiGet(''scans''), ''none''); ';
uimenu(h, 'Label', 'Un-set Params (selected scans)', 'Callback', cb);

return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function h = submenu_segmentation(parent);
% attach a submenu for segmentation-related operations.
h = uimenu(parent, 'Label', 'Segmentation', 'Separator', 'off');

uimenu(h, 'Label', 'Install / Reinstall Segmentation (cur session)', ...
          'Separator', 'off', 'Callback', 'installSegmentation; ');

uimenu(h, 'Label', 'Segmentation Info', ...
          'Separator', 'off', 'Callback', 'segmentInfo(VOLUME{1}); ');
	  
uimenu(h, 'Label', 'Load Segmentation into mrViewer', ...
          'Separator', 'on', 'Callback', 'sessionGUI_loadSegmentation; ');

return