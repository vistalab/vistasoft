function ui = mrViewBuildMesh(ui, vis, saveFlag);
%  ui = mrViewBuildMesh(ui, [vis=1], [saveFlag=1]);
%
% For a mrViewer which has a segmentation attached, 
% build a new mesh for the selected segmentation.
% Selects the new mesh, and optionally creates a 
% visualization window and offers to save the mesh file.
%
%
% ras, 10/2006.
if notDefined('ui'), ui = mrViewGet; end
if notDefined('vis'), vis = 1; end
if notDefined('saveFlag'), saveFlag = 1; end
if ishandle(ui), ui = get(ui, 'UserData'); end

%% ensure there is a segmentation installed
if ~checkfields(ui, 'segmentation')
    q = 'No segmentation installed. Would you like to install one now?';
    resp = questdlg(q, mfilename, 'Yes', 'No');
    if isequal(resp, 'Yes')
        ui = mrViewLoad(ui, '', 'Segmentation');
    else
        fprintf('[%s]: mesh build aborted; no segmentation.\n', mfilename);
        return
    end
end

%% build the mesh
s = ui.settings.segmentation;
ui.segmentation(s) = segBuildMesh(ui.segmentation(s), '', 'visualize', 0);

% select
m = length(ui.segmentation(s).mesh);
 
% add a menu option to select this mesh
ui.menus.meshList(m) = uimenu( ui.menus.meshSelect(s+1), ...
        'Label', ui.segmentation(s).mesh{end}.name, ...
        'Callback', sprintf('mrViewSet(gcf, ''CurMeshNum'', %i); ', m) );

ui = mrViewSet(ui, 'CurMeshNum', m);

%% visualize if selected
if vis==1
    ui.segmentation(s).mesh{m} = meshVisualize(ui.segmentation(s).mesh{m});
end

set(ui.fig, 'UserData', ui);

%% save if selected
if saveFlag==1
    startDir = ui.segmentation(s).params.meshDir;
    pth = mrvSelectFile('w', 'mat', 'Save Mesh File As...', startDir);
    ui.segmentation(s).mesh{m} = mrmWriteMeshFile(ui.segmentation(s).mesh{m}, pth);
end

return