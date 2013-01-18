function view=windowMenu(view)
%
% view=windowMenu(view)
% 
% Set up the callbacks for the WINDOW menu
% 
% djh, 1/22/98
% huk, 5/7/99 added keyboard shortcut for graph windows
% ras, 01/06  generally updated and cleaned up, moved older window options
%             to submenu
winmenu = uimenu('Label','Window','separator','on');

% Inplane Montage callback:
%  openMontageWindow;
uimenu(winmenu, 'Label', 'Open Inplane Window', 'Separator', 'off',...
     'CallBack', 'openMontageWindow;');

% Volume 3-view callback:
%  s = openRaw3ViewWindow;
% VOLUME{s} = switch2Vol(VOLUME{s});
uimenu(winmenu, 'Label', 'Open Volume 3-view Window', 'Separator', 'on',...
    'CallBack', 'open3ViewWindow(''volume''); ');

% Gray 3-view callback:
%  open3ViewWindow;
uimenu(winmenu, 'Label', 'Open Gray 3-View Window', 'Separator', 'off',...
    'CallBack', 'open3ViewWindow(''gray''); ');

% Flat callback:
%  openFlatWindow;
uimenu(winmenu, 'Label', 'Open Flat Window', 'Separator', 'on',...
    'CallBack', 'openFlatWindow;');

% Older window types subdirectory
olderMenu = uimenu(winmenu, 'Label', 'Older Window Types', ...
                    'Separator', 'on');
          
% New Graph Window callback:
%  newGraphWin;
uimenu(olderMenu, 'Label', 'New Graph Window', 'Separator', 'off',...
    'CallBack', 'newGraphWin;', 'Accelerator', 'w');

% Inplane callback:
%  openInplaneWindow;
uimenu(olderMenu, 'Label', 'Open Inplane (non-montage) Window', ...
    'Separator', 'on', 'CallBack', 'openInplaneWindow;');                    

% Volume callback:
%  openVolumeWindow;
uimenu(olderMenu, 'Label','Open Volume (Single Orientation) Window',... 
    'Separator','off', 'CallBack','openVolumeWindow;');

% Gray callback:
%  openGrayWindow;
uimenu(olderMenu, 'Label', 'Open Gray (Single Orientation) Window', ...
    'Separator','off', 'CallBack', 'openGrayWindow');

% Flat Level callback:
%  openFlatLevelWindow;
uimenu(olderMenu, 'Label', 'Open Flat Level Window', 'Separator', 'off',...
    'CallBack', 'openFlatLevelWindow;');

% Screen Save callback:
%  openSSWindow; (changed to 'rxLoadScreenSave;' -- ras, 08/05)
uimenu(winmenu,'Label','(Re-)open Screen Save Window','Separator','on',...
    'CallBack','rxLoadScreenSave'); %; 'openSSWindow;'

% 3D mesh submenu.  This menu should only be added in the Gray or Volume
% Window.  We rarely use the Volume ... but at this stage the viewType
% reads Volume even when opening a gray Window.  I am not sure why. (BW).
%
uimenu(winmenu, 'Label', 'Open 3D Window', 'Separator', 'on',...
    'CallBack', 'open3DWindow;');

return