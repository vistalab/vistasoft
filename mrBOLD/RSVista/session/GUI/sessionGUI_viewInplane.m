function [h, GUI] = sessionGUI_viewInplane(GUI, loadSeg);
%
% [viewerHandle GUI] = sessionGUI_viewInplane(<GUI>, <loadSeg=1>);
%
% Launch an instance of mrViewer for the currently-selected session's 
% inplane anatomies. Also load any relevant user prefs into the viewer 
% (such as brightness/contrast and zoom)
%
% Can accept and return the global GUI variable, though this is just a
% formality to explicitly show the inputs/outputs: it's designed to use the 
% global variable automatically.
%
% Can also return a handle to the main viewer window (the ui struct
% containing viewer info is this figure's UserData).
%
% The optional 'loadSeg' argument will determine whether the viewer
% tries to load Left/Right segmentations if it finds them. <default 1, try>
%
% ras, 07/06.
mrGlobals2;

if notDefined('loadSeg'),       loadSeg = 1;            end

inplanePath = fullfile(GUI.settings.session, 'Inplane', 'anat.mat');

if ~exist(inplanePath, 'file')
    error(sprintf('Inplane file %s not found. ', inplanePath));
end

h = mrViewer(inplanePath, '1.0anat');

GUI.viewers(end+1) = h;
GUI.settings.viewer = length(GUI.viewers);

ui = get(h, 'UserData');

% load prefs if they're there
prefsPath = fullfile(GUI.settings.session, 'Inplane', 'userPrefs.mat');
if exist(prefsPath, 'file')
    prefs = load(prefsPath);
    mrViewSet(ui, 'slice', prefs.curSlice);
    mrViewSetGrayscale(ui, 'clip', prefs.anatClip);
    
    if isfield(prefs, 'montageSize')
        nrows = ceil(sqrt(prefs.montageSize)); 
        ncols = ceil(prefs.montageSize/nrows);
        mrViewSet(ui, 'montagerows', nrows);
        mrViewSet(ui, 'montagecols', ncols);
    end
    
    if isfield(prefs, 'brightness')
        mrViewSetGrayscale(ui, 'brightness', prefs.brightness);
    end
end

% check if mrVista1 segmentations are installed, and if so, load the
% relevant .gray / .class files:
if loadSeg==1
	try
	    sessionGUI_loadSegmentation(ui);
	catch
		disp('Couldn''t load segmentation.')
		disp(lasterr);
	end
end
        

return

