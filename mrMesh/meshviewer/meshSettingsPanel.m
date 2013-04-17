function h = meshSettingsPanel(parent);
% Attach a UI panel containing controls for mesh settings.
%
% handles = meshSettingsPanel(parent);
%
% The controls in this panel include a list of stored settings for the
% mrMesh window, and a manual zoom slider.
%
% In linux, there are some issues w/ resizing the panel, which I am
% trying to work around.
%
% ras 03/14/2006.
if notDefined('parent'), parent = gcf; end

h.panel = mrvPanel('right', .4);

% listbox w/ settings
meshDir = viewGet(getSelectedGray, 'meshDir');
settingsFile = fullfile(meshDir, 'MeshSettings.mat');
if exist(settingsFile, 'file')
    load(settingsFile, 'settings');
    names = {settings.name};
else
    names = {''};
end
h.settingsList = uicontrol('Parent', h.panel, 'Style', 'listbox', ...
                   'Units', 'normalized', 'Position', [.1 .5 .8 .45], ...
                   'String', names, 'Tag', 'MeshSettingsList');
               
% store settings button
h.store = uicontrol('Parent', h.panel, 'Style', 'pushbutton', ...
            'Units', 'normalized', 'Position', [.1 .4 .4 .1], ...
            'String', 'Store', 'Callback', 'meshStoreSettings; ');

% retrieve settings button
h.retrieve = uicontrol('Parent', h.panel, 'Style', 'pushbutton', ...
            'Units', 'normalized', 'Position', [.5 .4 .4 .1], ...
            'String', 'Retrieve', 'Callback', 'meshRetrieveSettings; ');
        
% rename settings button
h.rename = uicontrol('Parent', h.panel, 'Style', 'pushbutton', ...
            'Units', 'normalized', 'Position', [.1 .3 .4 .1], ...
            'String', 'Rename', 'Callback', 'meshRenameSettings; ');

% delete settings button
h.delete = uicontrol('Parent', h.panel, 'Style', 'pushbutton', ...
            'Units', 'normalized', 'Position', [.5 .3 .4 .1], ...
            'String', 'Delete', 'Callback', 'meshDeleteSettings; ');
        
% re-load settings
h.reload =  uicontrol('Parent', h.panel, 'Style', 'pushbutton', ...
            'Units', 'normalized', 'Position', [.1 .18 .8 .08], ...
            'String', 'Reload Settings', 'Callback', 'meshSettingsList; ');
		
% manual zoom slider
cb = ['MSH = viewGet(getSelectedGray, ''SelectedMesh''); ' ...
      'TMP = mrmGet(MSH,''Camera''); TMP.actor = 0; ' ...
      'TMP.frustum(2) = 600 - get(gcbo, ''Value''); ' ...
      'mrMesh(MSH.host, MSH.id, ''set'', TMP); clear TMP MSH;'];
h.zoom = uicontrol('Parent', h.panel, 'Style', 'slider', ...
            'Min', 0, 'Max', 600, ...
            'Units', 'normalized', 'Position', [.1 .1 .6 .06], ...
            'String', 'Zoom', 'Callback', cb);
uicontrol('Parent', h.panel, 'Style', 'text', 'Units', 'normalized', ...
    'Position', [.2 .02 .4 .06], 'String', 'Manual Zoom', ...
    'HorizontalAlignment', 'left');

% fix problems w/ linux: will allow resize, but you
% won't be able to toggle it... :(
if isunix
    set(h.zoom, 'Parent', gcf, 'Position', [.65 .1 .3 .1]);
    set(h.store, 'Parent', gcf, 'Position', [.65 .4 .15 .1]);
    set(h.retrieve, 'Parent', gcf, 'Position', [.8 .4 .15 .1]);
    set(h.rename, 'Parent', gcf, 'Position', [.65 .3 .15 .1]);
    set(h.delete, 'Parent', gcf, 'Position', [.8 .3 .15 .1]);
end

return
