function [vw, s] = open3ViewWindow(type)
%
% [vw, s] = open3ViewWindow(type);
% 
% Calls openRaw3ViewWindow to set up a VOLUME data structure, then
% opens and initializes the 3-view interface window for the volume.
%
% If type is set to 'gray', calls switch2Gray to make it a gray
% view. Does this by default. Otherwise leaves as a volume view.
%
% Returns the view created (shouldn't all such routines do 
% this?), as well as the index into the global variable VOLUME
% which contains this view.
%
% See also: openRaw3ViewWindow, volume3View.
%
% ras, 3/04
mrGlobals

if notDefined('type')
    type = 'gray';
end

s = openRaw3ViewWindow;

if isequal(lower(type),'gray')
    VOLUME{s} = switch2Gray(VOLUME{s});
else
    VOLUME{s} = switch2Vol(VOLUME{s});
end

if nargout > 0
    vw = VOLUME{s};
end

%% load preferences
% to avoid refreshing twice (once in loadPrefs, once here), we
% check if the prefs file exists, and load it; otherwise just refresh:
if exist( fullfile(viewDir(VOLUME{s}), 'userPrefs.mat'), 'file' )
    VOLUME{s} = loadPrefs(VOLUME{s});
else
    VOLUME{s} = refreshScreen(VOLUME{s});
end

selectView(VOLUME{s});

return;