function ui = mrViewFileMenu(ui);
%
%  ui = mrViewFileMenu(ui);
%
% Attach a file menu to a mrViewer UI.
%
%
% ras 07/06/05.
if ~exist('ui', 'var') | isempty(ui),  ui = get(gcf, 'UserData'); end

ui.menus.file = uimenu(ui.fig, 'Label', 'File');

%%%%% Load submenu
ui.menus.fileLoad = uimenu(ui.menus.file, 'Label', 'Load');

% cb = 'ui=mrViewLoad; mrViewRefresh(ui);';
% ui.menus.fileLoadMR = uimenu(ui.menus.fileLoad, ...
%                             'Label', 'New Base MR Data', ...
%                             'Callback', cb);

cb = 'ui=mrViewLoad(gcf, [], 1); mrViewRefresh(ui);';
ui.menus.fileLoadMap = uimenu(ui.menus.fileLoad, 'Label', 'MR Data Map', ...
                            'Accelerator', 'L', 'Callback', cb);                        

cb = 'ui=mrViewLoad(gcf, [], ''roi''); mrViewRefresh(ui);';
ui.menus.fileLoadROI = uimenu(ui.menus.fileLoad, 'Label', 'ROI', 'Callback', cb);                        
      
cb = 'ui=mrViewLoad(gcf, [], ''segmentation'', 0); mrViewRefresh(ui);';
ui.menus.fileLoadSeg1 = uimenu(ui.menus.fileLoad, 'Label', 'mrGray Segmentation', ...
                              'Callback', cb);                                                  
                              
cb = 'ui=mrViewLoad(gcf, [], ''mesh''); mrViewRefresh(ui);';
ui.menus.fileLoadMesh = uimenu(ui.menus.fileLoad, 'Label', 'Mesh', 'Callback', cb);                        

cb = 'ui=mrViewLoad(gcf, [], ''meshsettings''); mrViewRefresh(ui);';
ui.menus.fileLoadMeshSettings = uimenu(ui.menus.fileLoad, ...
    'Label', 'Mesh Settings File', 'Callback', cb);                        


%%%%% Save submenu
ui.menus.fileSave = uimenu(ui.menus.file, 'Label', 'Save', 'Separator', 'on');


ui.menus.fileSaveROI = uimenu(ui.menus.fileSave, 'Label', 'Selected ROI', ...
            'Callback', 'mrViewROI(''save''); ');   


ui.menus.fileSaveAllROIs = uimenu(ui.menus.fileSave, 'Label', 'All ROIs', ...
            'Callback', 'mrViewROI(''save'', gcf, ''all''); ');   

h = uimenu(ui.menus.fileSave, 'Label', 'Save Map As...', ...
            'Separator', 'on', 'Callback', 'mrViewSave(gcf, [], ''map'');');   
ui.menus.fileSaveSettings = h;

h = uimenu(ui.menus.fileSave, 'Label', 'Underlay as Compressed NIFTI file...', ...
            'Separator', 'on', 'Callback', 'mrViewSaveSettings(gcf, ''nifti'');');   
ui.menus.fileSaveSettings = h;

h = uimenu(ui.menus.fileSave, 'Label', 'Underlay as MATLAB MR file...', ...
            'Callback', 'mrViewSaveSettings;');   
ui.menus.fileSaveSettingsNifti = h;

ui.menus.fileSaveMesh = uimenu(ui.menus.fileSave, 'Label', 'Selected Mesh', ...
            'Callback', 'mrViewSave(gcf, [], ''mesh''); ');   


%%%%% Attach submenu
ui.menus.fileAttach = uimenu(ui.menus.file, 'Label', 'Attach', ...
                            'Separator', 'on');
                        
uimenu(ui.menus.fileAttach, 'Label', 'Functional Time Series', ...
       'Separator', 'off', 'Callback', 'mrViewAttachTSeries; ');

uimenu(ui.menus.fileAttach, 'Label', 'Stimulus (.par) Files', ...
       'Separator', 'off', 'Callback', 'mrViewLoad([], [], ''stim''); ');
   
       

%%%%% Close submenu
ui.menus.fileClose = uimenu(ui.menus.file, 'Label', 'Close', 'Separator', 'on');
                    
uimenu(ui.menus.fileClose, 'Label', 'Close Map', ...
        'Callback', 'mrViewRemoveMap;');                        

%%%%% exit option
uimenu(ui.menus.file, 'Label', 'Exit', 'Separator', 'on', ...
    'Callback', 'mrViewClose;');

return
