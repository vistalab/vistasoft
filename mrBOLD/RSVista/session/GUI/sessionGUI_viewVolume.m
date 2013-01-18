function [GUI, h] = sessionGUI_viewVolume(GUI);
%
% [<GUI>, <viewerHandle>] = sessionGUI_viewVolume(<GUI>);
%
% Launch an instance of mrViewer for the currently-selected session's 
% inplane anatomies. 
%
% Can accept and return the global GUI variable, though this is just a
% formality to explicitly show the inputs/outputs: it's designed to use the 
% global variable automatically.
%
% Can also return the ui struct related to the new viwer (see mrViewer for
% more info), but this is normally stashed within the main UI window.
%
%
% ras, 07/06.
mrGlobals2;

volumePath = getVAnatomyPath;

if ~exist(volumePath, 'file')
    error(sprintf('Inplane file %s not found. ', volumePath));
end

h = mrViewer(volumePath, 'vanat');

GUI.viewers(end+1) = h;
GUI.settings.viewer = length(GUI.viewers);

% add the current inplane prescription as a space
mrViewLoad(h, fullfile(HOMEDIR, 'mrSESSION.mat'), 'space');

% load prefs if they're there
prefsPath = fullfile(GUI.settings.session, 'Volume', 'userPrefs.mat');
if ~exist(prefsPath, 'file')
    prefsPath = fullfile(GUI.settings.session, 'Gray', 'userPrefs.mat');
end
if exist(prefsPath, 'file')
    ui = get(h, 'UserData');
    prefs = load(prefsPath);
    ui = mrViewSet(ui, 'cursorloc', prefs.curSlices);
    ui = mrViewSet(ui, 'ori', prefs.curSliceOri);
    ui = mrViewSetGrayscale(ui, 'clip', prefs.anatClip);   
    mrViewRefresh(ui);
end

% check if mrVista1 segmentations are installed, and if so, load the
% relevant .gray / .class files:
sessionGUI_loadSegmentation(h);

return

