function [GUI, ui] = sessionGUI_viewMR(mr);
%
% [<GUI>, <viewerUI>] = sessionGUI_viewMR(<MR file = dialog>);
%
% Launch an instance of mrViewer for a user-selected base MR file.
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

if notDefined('mr')     % dialog (in mrLoad)
    mr = mrLoad;
elseif ischar(mr)       % file path
    mr = mrLoad(mr);     
end

h = mrViewer(mr);

GUI.viewers(end+1) = h;
GUI.settings.viewer = length(GUI.viewers);

% check if mrVista1 segmentations are installed, and if so, load the
% relevant .gray / .class files:
sessionGUI_loadSegmentation(h);

return

