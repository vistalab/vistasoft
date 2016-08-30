function view = editMenu(view)
%
% view = editMenu(view)
% 
% Set up the callbacks of the EDIT menu.
% 
% djh, 2/28/2001
editMenu = uimenu('Label','Edit','Separator','on');

% edit mrSESSION:
% [mSESSION,ok] = EditSession(mrSESSION);
% if ok, saveSession(1), end;
cb=['[mrSESSION,ok] = EditSession(mrSESSION,0); ',...
    'if ok, saveSession(1); end;'];
uimenu(editMenu,'Label','Edit/view mrSESSION','Separator','off',...
   'CallBack',cb);

% Edit alignment(using mrRx):
uimenu(editMenu,'Label','Edit/View Alignment...','Separator','off',...
    'Callback','rxAlign;', 'Accelerator', '7');


datatypeMenu = uimenu(editMenu,'Label','Data Type','Separator','off');

% Edit data type:
% c = curDataType(view)
% [dataTYPES(c),ok] = EditDataType(dataTYPES(c))
% if ok, saveSession(1), end;
cb=['c = ',view.name,'.curDataType; ',...
	'[dataTYPES(c), ok] = EditDataType(dataTYPES(c)); ',...
    'if ok, saveSession(1), end;'];
uimenu(datatypeMenu,'Label','Edit data type','Separator','off',...
   'CallBack',cb);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Assign Visual Field Map Parameters submenu:
retinoMapMenu = uimenu(datatypeMenu, 'Label', 'Set Retinotopy Parameters...', ...
                        'Separator', 'off');

% submenus for assigning visual field map params
% retinoSetParams(view);
cb = sprintf('retinoSetParams(%s); ', view.name);
uimenu(retinoMapMenu, 'Label', 'Current Scan', 'Callback', cb);

% scans = er_selectScans(view); retinoSetParams(view, [], scans); 
cb = [sprintf('scans = er_selectScans(%s); ', view.name) ...
      sprintf('retinoSetParams(%s, [], scans); ', view.name)];
uimenu(retinoMapMenu, 'Label', 'Select Scans', 'Callback', cb);

% retinoSetParams(view, [], 1:numScans(view));
cb = sprintf('retinoSetParams(%s, [], 1:numScans(%s)); ', ...
               view.name, view.name);
uimenu(retinoMapMenu, 'Label', 'All Scans', 'Callback', cb);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    

% Edit Event-Related Parameters callback:
%   params = er_getParams(view);
%   params = er_editParams(params);
%   er_setParams(view, params);
cb = sprintf('params = er_getParams(%s); ', view.name);
cb = [cb 'params = er_editParams(params); '];
cb = [cb sprintf('er_setParams(%s, params); ', view.name)];
uimenu(datatypeMenu, 'Label', 'Edit Event-Related Parameters (cur scan)', ...
    'Separator', 'off', 'CallBack', cb);

% Duplicate data type:
%   duplicateDataType(view);
cb = ['duplicateDataType(',view.name,');'];
uimenu(datatypeMenu, 'Label', 'Duplicate current data type', ...
        'Separator', 'on', 'CallBack', cb);

% Group scans into data type:
%   groupScans(view));
cb = ['groupScans(',view.name,');'];
uimenu(datatypeMenu, 'Label', 'Group scans into data type', ...
    'Separator', 'off', 'CallBack',cb);

% Remove data type:
%   removeDataType(getDataTypeName(view));
cb = ['removeDataType(getDataTypeName(',view.name,'));'];
uimenu(datatypeMenu, 'Label', 'Remove data type', 'Separator', 'on',...
   'CallBack', cb);

% Remove last scan from data type:
%   removeScan(view, numScans(view), '', 1);
cb = sprintf('removeScan(%s, numScans(%s), '''', 1); ', view.name, view.name);
uimenu(datatypeMenu, 'Label', 'Remove last scan in data type', 'Separator', 'off',...
   'CallBack', cb);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Edit Preferences callback:
% editPreferences;
uimenu(editMenu, 'Label', 'Edit Preferences', 'Accelerator', ';', ...
    'Separator', 'off', 'CallBack','editPreferences;');


return
