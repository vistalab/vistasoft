function ui = mrViewEditMenu(ui);
%
% ui = mrViewEditMenu(ui);
%
% Attaches an edit menu to a mrViewer UI.
%
% ras 07/05.
if ~exist('ui', 'var') | isempty(ui),  ui = get(gcf, 'UserData'); end

ui.menus.edit = uimenu(ui.fig, 'Label', 'Edit');

uimenu(ui.menus.edit, 'Label', 'mrViewer Preferences...', 'Accelerator', ',', ...
        'Callback', 'mrViewSetPrefs;');
	
uimenu(ui.menus.edit, 'Label', 'mrVista Preferences...', 'Accelerator', ';', ...
        'Callback', 'editPreferences;');

ui = submenu_space(ui);   
ui = submenu_roi(ui);

uimenu(ui.menus.edit, 'Label', 'Take Screenshot', 'Accelerator', ',', ...
        'Callback', 'mrViewScreenshot(gcf);');
	

return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function ui = submenu_space(ui);
%%%%%%%%%%%%%%%%%%    
% Spaces Submenu %
%%%%%%%%%%%%%%%%%%      
ui.menus.space = uimenu(ui.menus.edit,  'Label',  'Spaces');

%%%%%load space from mrSESSION alignment
uimenu(ui.menus.space,  'Label', 'Load mrSESSION alignment',  ...
    'Callback',  'mrViewLoad([], ''mrSESSION.mat'', ''space'');');

%%%%%load space from mrRxSettings 
uimenu(ui.menus.space,  'Label',  'Load Xform from mrRx Settings',  ...
    'Callback',  'mrViewLoad([], ''dialog'', ''space'');');


return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function ui = submenu_roi(ui);
%%%%%%%%%%%%%%%    
% ROI Submenu %
%%%%%%%%%%%%%%%    
ui.menus.roi = uimenu(ui.menus.edit,  'Label',  'ROIs');

%%%%%%create and add submenu
hCreate = uimenu(ui.menus.roi, 'Label', 'Create New ROI', 'Separator', 'off');

% create empty
cb = 'mrViewROI(''new''); ';
uimenu(hCreate,  'Label',  'Empty ROI',  'Accelerator',  'M',  'Callback',  cb);

% create + add rectangle
cb = 'mrViewROI(''new''); mrViewSet([], ''roiEditMode'', 1); ';
cb = [cb 'mrViewROI(''add''); '];
uimenu(hCreate,  'Label',  'Rectangle',  'Accelerator',  'R',  'Callback',  cb);

% create + add circle
cb = 'mrViewROI(''new''); mrViewSet([], ''roiEditMode'', 2); ';
cb = [cb 'mrViewROI(''add''); '];
uimenu(hCreate,  'Label',  'Circle',  'Callback',  cb);

% create + add line
cb = 'mrViewROI(''new''); mrViewSet([], ''roiEditMode'', 5); ';
cb = [cb 'mrViewROI(''add''); '];
uimenu(hCreate,  'Label',  'Line',  'Callback',  cb);

% create + grow from seed
cb = 'mrViewROI(''new''); mrViewSet([], ''roiEditMode'', 7); ';
cb = [cb 'mrViewROI(''add''); '];
uimenu(hCreate,  'Label', '(Grow Blob)',  'Accelerator', 'B',  'Callback', cb);


%%%%%%extend submenu
hExtend = uimenu(ui.menus.roi, 'Label', 'Extend ROI', 'Separator', 'on');

% extend w/ rectangle
cb = 'mrViewSet([], ''roiEditMode'', 1); mrViewROI(''add''); ';
uimenu(hExtend,  'Label',  'Rectangle',  'Accelerator',  'E',  'Callback',  cb);

% extend w/ circle
cb = 'mrViewSet([], ''roiEditMode'', 2); mrViewROI(''add''); ';
uimenu(hExtend,  'Label',  'Circle',  'Callback',  cb);

% extend w/ line
cb = 'mrViewSet([], ''roiEditMode'', 5); mrViewROI(''add''); ';
uimenu(hExtend,  'Label',  'Line',  'Callback',  cb);

% extend,  grow from seed
cb = 'mrViewSet([], ''roiEditMode'', 7); mrViewROI(''add''); ';
uimenu(hExtend,  'Label', '(Grow Blob)',  'Callback', cb);

% set flush to functional map
cb = ['tmp = mrViewGet(gcf, ''CurROI''); ' ...
      'tmp2 = mrViewGet(gcf, ''CurMap''); ' ...
      'tmp = roiMatchFunctionals(tmp, tmp2, mrViewGet(gcf, ''Base'')); ' ...
      'mrViewSet(gcf, ''CurROI'', tmp); mrViewRefresh(gcf); ' ...
      'clear tmp tmp2 '];
uimenu(hExtend, 'Label', 'Set Flush to Functional Map', 'Callback', cb);

%%%%%%gray matter submenu
hGray = uimenu(ui.menus.roi, 'Label', 'Gray ROIs', 'Separator', 'on');

% create Gray ROI
cb = 'mrViewROI(''gray'', gcf); ';
uimenu(hGray,  'Label',  'Make Gray ROI (Cur Segmentation)', 'Callback',  cb);

% create Gray Disk ROI
cb = 'mrViewROI(''disk'', gcf); ';
uimenu(hGray,  'Label',  'Make Gray Disk ROI', 'Callback',  cb);

% get mesh ROI (layer 1)
cb = 'mrViewROI(''mesh'', gcf, ''layer1''); ';
uimenu(hGray,  'Label',  'Grab Mesh ROI (layer 1)', 'Callback',  cb);

% get mesh ROI (all layers)
cb = 'mrViewROI(''mesh'', gcf, ''layer1''); ';
uimenu(hGray,  'Label',  'Grab Mesh ROI (all layers)', 'Callback',  cb);

% initialize the gray matter submenu to be hidden untiil a segmentation is
% installed:
set(hGray, 'Visible', 'off');
ui.menus.roiGray = hGray;


%%%%%%edit ROI properties
cb = 'mrViewROI(''edit''); ';
uimenu(ui.menus.roi,  'Label', 'Edit ROI',  'Accelerator', 'N',  ...
    'Separator', 'on',  'Callback', cb);

%%%%%%set fill mode options
cb = ['ui = mrViewGet; ' ...
      'for ii = 1:length(ui.rois), ui.rois(ii).fillMode = ''perimeter''; end; ' ...
      'mrViewROI(''draw'', ui); clear ui ii; '];
uimenu(ui.menus.roi,  'Label', 'Set All ROIs To Perimeter',  ...
    'Separator', 'off',  'Callback', cb);

cb = ['ui = mrViewGet; ' ...
      'for ii = 1:length(ui.rois), ui.rois(ii).fillMode = ''filled''; end; ' ...
      'mrViewROI(''draw'', ui); clear ui ii; '];
uimenu(ui.menus.roi,  'Label', 'Set All ROIs To Filled',  ...
    'Separator', 'off',  'Callback', cb);

%%%%%%restrict submenu
hRestrict = uimenu(ui.menus.roi, 'Label', 'Restrict', 'Separator', 'on');

% restrict selected ROI
cb = 'mrViewROI(''restrict''); ';
uimenu(hRestrict,  'Label', 'Restrict Selected ROI',  'Accelerator', 'X', ...
    'Separator', 'off', 'Callback', cb);

% restrict all ROIs
cb = 'mrViewROI(''restrict'', get(gcf, ''UserData''), ''all''); ';
uimenu(hRestrict,  'Label', 'Restrict All ROIs',  ...
    'Separator', 'off', 'Callback', cb);


%%%%%delete submenu
hDelete = uimenu(ui.menus.roi, 'Label', 'Delete ROI(s)', 'Separator', 'on');

% delete selected ROI
cb = 'mrViewROI(''delete''); ';
uimenu(hDelete,  'Label',  'Selected ROI',  'Accelerator',  'D',  'Callback',  cb);

% delete all ROIs
cb = 'mrViewROI(''delete'',  [],  ''all''); ';
uimenu(hDelete,  'Label',  'All ROIs',  'Accelerator',  'K',  'Callback',  cb);

return